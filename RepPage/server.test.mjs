import { test } from 'node:test'
import assert from 'node:assert/strict'
import { spawn } from 'node:child_process'
import { once } from 'node:events'

// One transport regression: late joins get the current offer, ended calls never
// leak it into the next call, and extra peers cannot join the active pair.
test('signaling pairs two peers and discards ended-call backlog', { timeout: 10000 }, async () => {
  const server = spawn(process.execPath, [new URL('./server.mjs', import.meta.url).pathname], { env: { ...process.env, PORT: '0' } })
  const clients = []
  try {
    const [output] = await once(server.stdout, 'data')
    const port = String(output).match(/localhost:(\d+)/)[1]
    async function connect(role) {
      const ws = new WebSocket(`ws://localhost:${port}/?role=${role}`)
      const messages = []
      ws.addEventListener('message', event => messages.push(JSON.parse(event.data)))
      clients.push(ws); await once(ws, 'open')
      return { ws, messages }
    }
    async function waitFor(client, type) {
      for (let i = 0; i < 100; i++) {
        const found = client.messages.find(message => message.type === type)
        if (found) return found
        await new Promise(resolve => setTimeout(resolve, 10))
      }
      throw Error(`No ${type} received`)
    }
    const room = await connect('room')
    room.ws.send(JSON.stringify({ type: 'offer', sdp: 'current-offer' }))
    room.ws.send(JSON.stringify({ type: 'candidate', candidate: 'room-candidate' }))
    const rep = await connect('rep')
    assert.equal((await waitFor(rep, 'offer')).sdp, 'current-offer')
    assert.equal((await waitFor(rep, 'candidate')).candidate, 'room-candidate')
    rep.ws.send(JSON.stringify({ type: 'answer', sdp: 'rep-answer' }))
    assert.equal((await waitFor(room, 'answer')).sdp, 'rep-answer')
    const extra = await connect('room')
    await waitFor(extra, 'busy')
    room.ws.close(); await waitFor(rep, 'peer-left')
    rep.ws.close(); await once(rep.ws, 'close')
    const nextRep = await connect('rep')
    await new Promise(resolve => setTimeout(resolve, 50))
    assert.equal(nextRep.messages.some(message => message.type === 'offer'), false)
    const nextRoom = await connect('room')
    nextRoom.ws.send(JSON.stringify({ type: 'offer', sdp: 'new-offer' }))
    assert.equal((await waitFor(nextRep, 'offer')).sdp, 'new-offer')
  } finally { clients.forEach(ws => ws.close()); server.kill(); await once(server, 'exit') }
})
