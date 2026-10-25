import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawn } from 'node:child_process'
import { once } from 'node:events'

test('session joins without media, refreshes on rejoin and isolates call peers', { timeout: 10000 }, async () => {
  const server = spawn(process.execPath, [new URL('./server.mjs', import.meta.url).pathname], { env: { ...process.env, PORT: '0' } })
  const clients = []
  try {
    const [output] = await once(server.stdout, 'data')
    const port = String(output).match(/localhost:(\d+)/)[1]
    async function connect(role, path = '/session') {
      const ws = new WebSocket(`ws://localhost:${port}${path}?role=${role}`), messages = []
      ws.addEventListener('message', event => messages.push(JSON.parse(event.data)))
      clients.push(ws); await once(ws, 'open'); return { ws, messages }
    }
    async function next(client, type) {
      for (let i = 0; i < 100; i++) {
        const index = client.messages.findIndex(message => message.type === type)
        if (index >= 0) return client.messages.splice(index, 1)[0]
        await new Promise(resolve => setTimeout(resolve, 10))
      }
      throw Error(`No ${type}`)
    }
    const room = await connect('room'), rep = await connect('rep')
    await next(room, 'peer-joined')
    room.ws.send(JSON.stringify({ type: 'session-snapshot', snapshot: { revision: 4 } }))
    assert.equal((await next(rep, 'session-snapshot')).snapshot.revision, 4)
    room.ws.send(JSON.stringify({ type: 'call-invitation', invitation: { id: 'call-1', state: 'requested' } }))
    assert.equal((await next(rep, 'call-invitation')).invitation.id, 'call-1')
    rep.ws.send(JSON.stringify({ type: 'support-envelope', envelope: { id: 'ack' } }))
    assert.equal((await next(room, 'support-envelope')).envelope.id, 'ack')
    const mediaRoom = await connect('room', '/'), mediaRep = await connect('rep', '/')
    mediaRoom.ws.send(JSON.stringify({ type: 'offer', sdp: 'call' }))
    assert.equal((await next(mediaRep, 'offer')).sdp, 'call')
    mediaRoom.ws.send(JSON.stringify({ type: 'camera', enabled: false, facing: 'back' }))
    assert.equal((await next(mediaRep, 'camera')).enabled, false)
    assert.equal(rep.messages.some(m => m.type === 'offer'), false)
    const extra = await connect('rep'); await next(extra, 'busy')
    rep.ws.close(); await once(rep.ws, 'close'); await next(room, 'peer-left')
    const rejoined = await connect('rep'); await next(room, 'peer-joined')
    room.ws.send(JSON.stringify({ type: 'session-snapshot', snapshot: { revision: 5 } }))
    assert.equal((await next(rejoined, 'session-snapshot')).snapshot.revision, 5)
    assert.equal(rejoined.messages.some(m => m.snapshot?.revision === 4), false)
    mediaRoom.ws.close(); await next(mediaRep, 'peer-left')
    rejoined.ws.send(JSON.stringify({ type: 'snapshot-request' })); await next(room, 'snapshot-request')
  } finally { clients.forEach(ws => ws.close()); server.kill(); await once(server, 'exit') }
})
