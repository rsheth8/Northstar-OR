import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import vm from 'node:vm'

test('late join restores case and questions without media; end call preserves session replies', () => {
  const nodes = new Map(), handlers = new Map(), storage = new Map(), sockets = [], timers = new Map()
  let nextTimer = 0
  let failStorage = false, mediaRequests = 0
  const node = id => {
    if (!nodes.has(id)) nodes.set(id, { textContent: '', value: '', children: [], disabled: false,
      replaceChildren() { this.children = []; if (id === 'questions') this.value = '' },
      append(item) { this.children.push(item); if (id === 'questions' && !this.value) this.value = item.value }, setAttribute() {} })
    return nodes.get(id)
  }
  class Socket {
    static OPEN = 1
    constructor() { this.readyState = 1; this.sent = []; sockets.push(this) }
    send(text) { this.sent.push(JSON.parse(text)) }
    close() { this.readyState = 3 }
  }
  const window = {
    addEventListener(name, fn) { if (!handlers.has(name)) handlers.set(name, []); handlers.get(name).push(fn) },
    dispatchEvent(event) { for (const fn of handlers.get(event.type) || []) fn(event) }, isSecureContext: true
  }
  const context = vm.createContext({ window, document: { getElementById: node, createElement: () => ({}) },
    location: { host: 'localhost:8080', protocol: 'http:' }, WebSocket: Socket, TextEncoder, Event,
    sessionStorage: { getItem: k => storage.get(k) || null, setItem(k, v) { if (failStorage) throw Error('storage unavailable'); storage.set(k, v) }, removeItem: k => storage.delete(k) },
    navigator: { mediaDevices: { getUserMedia() { mediaRequests++; throw Error('must not request media') } } },
    setTimeout(fn, delay) { const id = ++nextTimer; timers.set(id, { fn, delay }); return id }, clearTimeout(id) { timers.delete(id) }, clearInterval() {}, console })
  for (const file of ['call.js', 'session.js']) vm.runInContext(`{${readFileSync(new URL(file, import.meta.url), 'utf8')}\n}`, context)
  node('session-join').onclick()
  let ws = sockets[0]; ws.onopen()
  const origin = { workspaceID: 'w', caseID: 'c', sessionID: 's' }
  const snapshot = { origin, recordingSummary: 'Recording', saved: true,
    context: { capturedAt: 800000000, recordingRevision: 2, caseReference: 'Fictional 1', caseName: 'Fictional case', siteName: 'Example', lines: [{ id: 'i', title: 'Fictional item', status: 'deferred' }], recentEvents: ['Recorded event'] },
    questions: [{ id: 'q', ...origin, text: 'Fictional question', sentAt: 800000000, snapshot: { caseName: 'Fictional case', siteName: 'Example', lines: [] }, recipientContactID: 'rep', recipientName: 'Fictional rep' }] }
  const receive = value => ws.onmessage({ data: JSON.stringify({ type: 'session-snapshot', snapshot: value }) })
  receive(snapshot)
  node('join').onclick()
  context.window.northstarStartMedia()
  assert.equal(mediaRequests, 0, 'legacy entry points cannot bypass invitation acceptance')
  assert.equal(mediaRequests, 0)
  assert.match(node('session-context').textContent, /Fictional 1/)
  assert.equal(node('session-events').children.length, 1)
  assert.equal(Boolean(node('ack').disabled), false)
  assert.equal(ws.sent.filter(m => m.envelope?.kind === 'receipt').length, 1)
  node('end').onclick()
  assert.equal(ws.readyState, Socket.OPEN)
  node('ack').onclick()
  assert.equal(ws.sent.at(-1).envelope.kind, 'questionAcknowledgement')
  node('reply').value = 'Fictional technical reply'
  node('send').onclick()
  assert.equal(ws.sent.at(-1).envelope.kind, 'reply')
  assert.ok(storage.get('northstar-call').includes('Fictional technical reply'))
  ws.onmessage({ data: JSON.stringify({ type: 'call-invitation', invitation: { id: 'room-call', origin, from: 'room', state: 'requested', sentAt: Date.now() / 1000 - 978307200 } }) })
  assert.equal(mediaRequests, 0)
  assert.equal(node('invitation-accept').hidden, false)
  node('invitation-accept').onclick()
  assert.equal(mediaRequests, 1, 'media starts only after the invitation is accepted')
  node('session-note').value = 'Fictional message'
  node('session-note-send').onclick()
  const note = ws.sent.at(-1)
  assert.equal(note.envelope.kind, 'note')
  ws.onmessage({ data: JSON.stringify(note) })
  ws.onmessage({ data: JSON.stringify(note) })
  assert.equal(node('session-thread').children.filter(item => String(item.textContent).includes('Fictional message')).length, 1)
  const savedNoteID = note.envelope.id
  receive(snapshot)
  assert.equal(node('session-thread').children.filter(item => String(item.textContent).includes('Fictional message')).length, 1, 'room snapshot must retain unreceived local note')
  node('session-note-retry').onclick()
  assert.equal(ws.sent.at(-1).envelope.id, savedNoteID, 'retry preserves original ID')
  assert.ok(storage.get('northstar-note-outbox').includes(savedNoteID))
  context.window.northstarRoomCamera(false, 'back')
  assert.equal(node('video-status').textContent, 'Room camera: off')
  node('session-alerts').onclick()
  receive({ ...snapshot, context: { ...snapshot.context, recordingRevision: 3, lines: [{ id: 'i', title: 'Fictional item', status: 'unrecorded' }] } })
  receive({ ...snapshot, context: { ...snapshot.context, recordingRevision: 4, lines: [{ id: 'i', title: 'Fictional item', status: 'deferred' }] } })
  assert.match(node('session-alert').textContent, /Fictional item was deferred/)
  receive({ ...snapshot, context: { ...snapshot.context, recordingRevision: 1, caseReference: 'STALE' } })
  assert.doesNotMatch(node('session-context').textContent, /STALE/)
  ws.onclose()
  node('session-join').onclick()
  ws = sockets.at(-1); ws.onopen()
  receive({ ...snapshot, context: { ...snapshot.context, recordingRevision: 1, caseReference: 'RESTORED' } })
  assert.match(node('session-context').textContent, /RESTORED/, 'fresh connection must accept the authoritative restored record')
  assert.equal(node('session-thread').children.filter(item => String(item.textContent).includes('Fictional message')).length, 1, 'reconnect preserves pending message outside room snapshot')
  node('session-note-retry').onclick()
  assert.equal(ws.sent.at(-1).envelope.id, savedNoteID)
  // A simultaneous smaller request replaces the local request and gets its own expiry.
  node('invitation-request').onclick()
  const requested = ws.sent.at(-1).invitation
  ws.onmessage({ data: JSON.stringify({ type: 'call-invitation', invitation: { ...requested, id: '000-room', from: 'room' } }) })
  assert.equal(timers.size, 1)
  assert.equal(node('invitation-accept').hidden, false)
  const timer = [...timers.values()][0]
  assert.ok(timer.delay > 0 && timer.delay <= 30000)
  timer.fn()
  assert.equal(ws.sent.at(-1).invitation.state, 'expired')
  const requestsBefore = mediaRequests
  node('invitation-accept').onclick()
  assert.equal(mediaRequests, requestsBefore, 'expired request cannot open media')
  ws.onmessage({ data: JSON.stringify({ type: 'call-invitation', invitation: { ...requested, id: 'ended-room', from: 'room' } }) })
  receive({ ...snapshot, recordingSummary: 'Recording ended' })
  node('invitation-accept').onclick()
  assert.equal(mediaRequests, requestsBefore, 'ended recording cannot accept call')
  const before = ws.sent.length
  failStorage = true
  receive({ ...snapshot, context: { ...snapshot.context, recordingRevision: 3 } })
  assert.equal(ws.sent.length, before, 'failed snapshot persistence must not issue receipts')
  assert.equal(node('ack').disabled, true)
  assert.match(node('session-status').textContent, /not retained/)
})
