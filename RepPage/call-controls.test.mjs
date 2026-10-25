import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import vm from 'node:vm'

test('laptop mute changes its outgoing track and video cannot replace room audio', async () => {
  const nodes = new Map()
  const node = id => {
    if (!nodes.has(id)) nodes.set(id, { textContent: '', value: '', disabled: false, hidden: false, muted: false, volume: 1,
      srcObject: null, setAttribute() {}, replaceChildren() {}, append() {}, play: async () => {} })
    return nodes.get(id)
  }
  const microphone = { kind: 'audio', enabled: true, stop() { this.stopped = true } }
  class Stream {
    constructor(tracks = []) { this.tracks = tracks }
    getTracks() { return this.tracks }
    getAudioTracks() { return this.tracks.filter(track => track.kind === 'audio') }
    addTrack(track) { this.tracks.push(track) }
  }
  let peer
  class Peer {
    constructor() { peer = this }
    addTrack() {}
    close() {}
  }
  class Socket { static OPEN = 1; close() {} }
  const context = { document: { getElementById: node, createElement: () => ({}) },
    window: { isSecureContext: true, addEventListener() {}, northstarSession: { canStartMedia: () => true, ready: () => false } },
    navigator: { mediaDevices: { getUserMedia: async () => new Stream([microphone]) } },
    sessionStorage: { getItem: () => null, setItem() {} }, location: { host: 'localhost:8080' },
    MediaStream: Stream, RTCPeerConnection: Peer, WebSocket: Socket,
    setInterval: () => 1, clearInterval() {}, console }
  vm.runInNewContext(readFileSync(new URL('./call.js', import.meta.url), 'utf8'), context)
  await node('join').onclick()
  assert.equal(node('mute').disabled, false)
  node('mute').onclick()
  assert.equal(microphone.enabled, false)
  assert.equal(node('mute').textContent, 'Unmute microphone')
  node('mute').onclick()
  assert.equal(microphone.enabled, true)
  const camera = { kind: 'video' }, audio = { kind: 'audio' }, nextCamera = { kind: 'video' }
  peer.ontrack({ track: camera, streams: [] })
  peer.ontrack({ track: audio, streams: [] })
  peer.ontrack({ track: nextCamera, streams: [] })
  assert.deepEqual(node('room-audio').srcObject.getTracks(), [audio])
  assert.deepEqual(node('remote').srcObject.getTracks(), [camera, nextCamera])
  assert.equal(node('remote').muted, true)
  node('end').onclick()
  assert.equal(microphone.stopped, true)
  assert.equal(node('room-audio').srcObject, null)
  assert.equal(node('mute').disabled, true)
})
