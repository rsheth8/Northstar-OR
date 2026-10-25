// Local-only, two-party signaling. Media and support envelopes use WebRTC.
// Connection flow inspired by stasel/WebRTC-iOS (Apache-2.0).
import http from 'node:http'
import fs from 'node:fs'
import crypto from 'node:crypto'
import path from 'node:path'
import os from 'node:os'
import { fileURLToPath } from 'node:url'

const root = path.dirname(fileURLToPath(import.meta.url))
const peers = new Map()
let backlog = []
let backlogBytes = 0
const limit = 512 * 1024
const server = http.createServer((request, response) => {
  const name = new URL(request.url, 'http://localhost').pathname
  const file = new Map([['/', 'index.html'], ['/call.js', 'call.js'], ['/session.js', 'session.js']]).get(name)
  if (!file) { response.writeHead(404).end('Not found'); return }
  response.writeHead(200, { 'content-type': file.endsWith('.js') ? 'text/javascript; charset=utf-8' : 'text/html; charset=utf-8', 'cache-control': 'no-store' })
  fs.createReadStream(path.join(root, file)).pipe(response)
})
server.on('upgrade', (request, socket, head) => {
  const address = new URL(request.url, 'http://localhost')
  const role = address.searchParams.get('role')
  const sessionChannel = address.pathname === '/session'
  const pairKey = role => (sessionChannel ? 'session-' : '') + role
  const key = request.headers['sec-websocket-key']
  // Rep microphone must originate on localhost; no arbitrary website may join.
  const origin = request.headers.origin
  if (!['/', '/session'].includes(address.pathname) || !key || !['room', 'rep'].includes(role) || (origin && origin !== `http://localhost:${server.address().port}` && origin !== `http://127.0.0.1:${server.address().port}`)) {
    socket.end('HTTP/1.1 403 Forbidden\r\n\r\n'); return
  }
  const accept = crypto.createHash('sha1').update(key + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest('base64')
  socket.write(`HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ${accept}\r\n\r\n`)
  if (peers.has(pairKey(role))) { write(socket, JSON.stringify({ type: 'busy' })); socket.end(); return }
  const client = { socket, role, sessionChannel, pairKey, buffer: Buffer.alloc(0), fragments: [], fragmentBytes: 0 }
  peers.set(pairKey(role), client)
  if (!sessionChannel && role === 'rep') for (const text of backlog) write(socket, text)
  if (sessionChannel) {
    const other = peers.get(pairKey(role === 'room' ? 'rep' : 'room'))
    if (other) { write(other.socket, JSON.stringify({ type: 'peer-joined' })); write(socket, JSON.stringify({ type: 'peer-joined' })) }
  }
  const remove = () => {
    if (peers.get(pairKey(role)) !== client) return
    peers.delete(pairKey(role)); if (!sessionChannel) { backlog = []; backlogBytes = 0 }
    const other = peers.get(pairKey(role === 'room' ? 'rep' : 'room'))
    if (other) write(other.socket, JSON.stringify({ type: 'peer-left' }))
  }
  socket.on('data', chunk => {
    client.buffer = Buffer.concat([client.buffer, chunk])
    if (client.buffer.length > limit + 14) { socket.destroy(); return }
    consume(client)
  })
  socket.on('close', remove); socket.on('end', remove); socket.on('error', remove)
  if (head.length) { client.buffer = head; consume(client) }
})
server.listen(Number(process.env.PORT || 8080), '0.0.0.0', () => {
  const port = server.address().port
  console.log(`Rep laptop: http://localhost:${port} (microphone allowed here)`)
  for (const network of Object.values(os.networkInterfaces()).flat()) {
    if (network.family === 'IPv4' && !network.internal) console.log(`iPad server: ws://${network.address}:${port}`)
  }
})
function consume(client) {
  let buffer = client.buffer
  while (buffer.length >= 2) {
    const fin = (buffer[0] & 0x80) !== 0
    const opcode = buffer[0] & 0x0f
    if ((buffer[0] & 0x70) || !(buffer[1] & 0x80)) { client.socket.destroy(); return }
    let length = buffer[1] & 0x7f, offset = 2
    if (length === 126) { if (buffer.length < 4) break; length = buffer.readUInt16BE(2); offset = 4 }
    else if (length === 127) {
      if (buffer.length < 10) break
      const big = buffer.readBigUInt64BE(2)
      if (big > BigInt(limit)) { client.socket.destroy(); return }
      length = Number(big); offset = 10
    }
    if (length > limit || (opcode >= 8 && (!fin || length > 125))) { client.socket.destroy(); return }
    if (buffer.length < offset + 4 + length) break
    const mask = buffer.subarray(offset, offset + 4)
    const payload = Buffer.from(buffer.subarray(offset + 4, offset + 4 + length))
    for (let i = 0; i < payload.length; i++) payload[i] ^= mask[i % 4]
    buffer = buffer.subarray(offset + 4 + length)
    if (opcode === 8) { client.socket.end(Buffer.from([0x88, 0])); return }
    if (opcode === 9) { client.socket.write(Buffer.concat([Buffer.from([0x8a, payload.length]), payload])); continue }
    if (opcode === 10) continue
    if (opcode !== 1 && opcode !== 0 || opcode === 0 && !client.fragments.length || opcode === 1 && client.fragments.length) { client.socket.destroy(); return }
    client.fragments.push(payload); client.fragmentBytes += payload.length
    if (client.fragmentBytes > limit) { client.socket.destroy(); return }
    if (fin) {
      receive(client, Buffer.concat(client.fragments).toString('utf8'))
      client.fragments = []; client.fragmentBytes = 0
    }
  }
  client.buffer = buffer
}
function receive(client, text) {
  let message
  try { message = JSON.parse(text) } catch { return }
  if (client.sessionChannel) {
    if (!['session-snapshot', 'support-envelope', 'snapshot-request'].includes(message.type)) return
    if (message.type === 'session-snapshot' && client.role !== 'room') return
    const other = peers.get(client.pairKey(client.role === 'room' ? 'rep' : 'room'))
    if (other) write(other.socket, text)
    return
  }
  if (!['offer', 'answer', 'candidate'].includes(message.type)) return
  if (message.type === 'offer' && client.role !== 'room' || message.type === 'answer' && client.role !== 'rep') return
  if (client.role === 'room') {
    if (message.type === 'offer') { backlog = []; backlogBytes = 0 }
    backlogBytes += Buffer.byteLength(text)
    if (backlogBytes > limit) { client.socket.destroy(); return }
    backlog.push(text)
  }
  const other = peers.get(client.role === 'room' ? 'rep' : 'room')
  if (other) write(other.socket, text)
}
function write(socket, text) {
  const data = Buffer.from(text)
  const header = data.length < 126 ? Buffer.from([0x81, data.length]) : Buffer.alloc(data.length < 65536 ? 4 : 10)
  if (data.length >= 126) {
    header[0] = 0x81
    if (data.length < 65536) { header[1] = 126; header.writeUInt16BE(data.length, 2) }
    else { header[1] = 127; header.writeBigUInt64BE(BigInt(data.length), 2) }
  }
  socket.write(Buffer.concat([header, data]))
}
