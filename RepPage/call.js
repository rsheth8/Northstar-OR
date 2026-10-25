const $ = id => document.getElementById(id)
const status = $('status'), video = $('remote'), select = $('questions')
let pc, ws, channel, stream, run = 0
let records
try { records = JSON.parse(sessionStorage.getItem('northstar-call') || '{}') } catch { records = {} }
const now = () => Date.now() / 1000 - 978307200 // Swift Date's reference epoch.
const save = () => sessionStorage.setItem('northstar-call', JSON.stringify(records))
const current = () => records[select.value]
const canonical = value => JSON.stringify(value, (_, item) => item && !Array.isArray(item) && typeof item === 'object' ? Object.fromEntries(Object.keys(item).sort().map(key => [key, item[key]])) : item)
const send = envelope => {
  if (channel?.readyState !== 'open') throw Error('Call disconnected. Your message is kept; reconnect and retry.')
  channel.send(JSON.stringify(envelope))
}
function render() {
  const record = current()
  $('question').textContent = record?.question.text || 'No question from the team yet'
  $('context').textContent = record ? `${record.question.snapshot.caseName} · ${record.question.snapshot.siteName} · To ${record.question.recipientName}` : ''
  $('lines').replaceChildren()
  for (const line of record?.question.snapshot.lines.filter(line => line.status !== 'teamConfirmed') || []) {
    const item = document.createElement('li'); item.textContent = `${line.title} — ${line.status}`; $('lines').append(item)
  }
  const open = channel?.readyState === 'open'
  $('ack').disabled = !record || !open || record.ackReceived
  $('ack').textContent = record?.ack ? (record.ackReceived ? 'Acknowledgment received by room' : 'Retry acknowledgment') : 'Acknowledge question'
  $('send').disabled = !record || !open || record.replyReceived
  $('send').textContent = record?.reply ? (record.replyReceived ? 'Reply received by room' : 'Retry saved reply') : 'Send reply'
  $('reply').value = record?.reply?.reply.text || record?.draft || ''
  $('reply').disabled = !!record?.reply
  $('delivery').textContent = record?.reply ? (record.replyReceived ? 'Reply received on the room iPad' : 'Reply kept here · awaiting room receipt') : ''
}
function refreshQuestions(preferred) {
  const selected = preferred || select.value
  select.replaceChildren()
  for (const [key, record] of Object.entries(records)) {
    const option = document.createElement('option'); option.value = key
    option.textContent = `${record.question.snapshot.caseName}: ${record.question.text}`; select.append(option)
  }
  if (records[selected]) select.value = selected
  render()
}
select.onchange = render
$('reply').oninput = () => { const record = current(); if (record) { record.draft = $('reply').value; try { save() } catch { status.textContent = 'Draft storage unavailable. Keep this page open.' } } }
function receive(envelope) {
  if (!envelope || !envelope.origin || !envelope.questionID || !envelope.id) return
  if (envelope.kind === 'question') {
    const q = envelope.question
    if (!q || q.id !== envelope.questionID || !q.snapshot?.lines || q.sessionID !== envelope.origin.sessionID) return
    const existing = records[envelope.id]
    if (existing && canonical(existing.question) !== canonical(q)) return
    records[envelope.id] ||= { question: q, envelope }
    save() // Receipt means the browser retained the question, not just bytes arrived.
    refreshQuestions(envelope.id)
    send({ id: envelope.id + ':receipt', kind: 'receipt', sentAt: now(), origin: envelope.origin, questionID: q.id, receiptForID: envelope.id })
  } else if (envelope.kind === 'receipt') {
    const record = Object.values(records).find(r => r.question.id === envelope.questionID && canonical(r.envelope.origin) === canonical(envelope.origin))
    if (!record) return
    if (record.ack?.id === envelope.receiptForID) record.ackReceived = true
    if (record.reply?.id === envelope.receiptForID) record.replyReceived = true
    save(); render()
  }
}
function response(record, kind, text) {
  const q = record.question, at = now(), id = record.envelope.id + (kind === 'reply' ? ':reply' : ':ack')
  const actor = { id: 'laptop:' + q.recipientContactID, workspaceID: 'northstar-laptop-rep', displayName: q.recipientName + ' (laptop)', statedRole: 'technicalRep' }
  const payload = { id, questionID: q.id, actor, at, delivery: 'onThisDevice' }
  if (kind === 'reply') payload.text = text
  return { id, kind, sentAt: at, origin: record.envelope.origin, questionID: q.id, [kind === 'reply' ? 'reply' : 'acknowledgement']: payload }
}
$('ack').onclick = () => {
  const record = current(); if (!record) return
  try { record.ack ||= response(record, 'questionAcknowledgement'); save(); send(record.ack); render() }
  catch (error) { status.textContent = error.message }
}
$('send').onclick = () => {
  const record = current(), text = $('reply').value.trim(); if (!record || (!text && !record.reply)) return
  try { record.reply ||= response(record, 'reply', text); save(); send(record.reply); render() }
  catch (error) { status.textContent = error.message }
}
function end(message = 'Call ended. Saved questions remain on this laptop tab.') {
  run++
  const old = pc; pc = null; channel = null; old?.close()
  const socket = ws; ws = null; socket?.close()
  stream?.getTracks().forEach(track => track.stop()); stream = null
  video.srcObject = null; $('end').disabled = true; $('join').disabled = false; $('play').hidden = true
  status.textContent = message; render()
}
$('end').onclick = () => end()
$('play').onclick = () => video.play().then(() => { $('play').hidden = true }).catch(() => { status.textContent = 'Room audio could not play. Check the laptop output.' })
$('join').onclick = async () => {
  end(); const generation = run
  if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia) {
    status.textContent = 'Open http://localhost:8080 on the server laptop to allow the microphone.'; return
  }
  $('join').disabled = true; status.textContent = 'Allow microphone access'
  try {
    const media = await navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: true, noiseSuppression: true }, video: false })
    if (run !== generation) { media.getTracks().forEach(track => track.stop()); return }
    stream = media
    const peer = new RTCPeerConnection({ iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] })
    pc = peer
    stream.getTracks().forEach(track => peer.addTrack(track, stream))
    const socket = new WebSocket(`ws://${location.host}/?role=rep`); ws = socket
    let pending = [], ready = false
    const signal = object => { if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(object)) }
    peer.onicecandidate = event => { if (pc === peer && event.candidate) signal({ type: 'candidate', ...event.candidate.toJSON() }) }
    peer.ontrack = event => {
      if (pc !== peer) return
      video.srcObject = event.streams[0] || new MediaStream([event.track])
      video.play().catch(() => { $('play').hidden = false })
    }
    peer.ondatachannel = event => {
      if (pc !== peer || event.channel.label !== 'northstar') return
      channel = event.channel
      channel.onopen = render; channel.onclose = render
      channel.onmessage = event => {
        if (pc !== peer) return
        try { receive(JSON.parse(event.data)) } catch (error) { status.textContent = `Message not retained: ${error.message}` }
      }
    }
    peer.onconnectionstatechange = () => {
      if (pc !== peer) return
      if (peer.connectionState === 'connected') status.textContent = 'In call'
      if (['failed', 'disconnected', 'closed'].includes(peer.connectionState)) end('Call disconnected. Join again, then restart from the iPad.')
    }
    // Serialize offer and candidate handling: candidates must wait for remote SDP.
    let handling = Promise.resolve()
    socket.onmessage = event => {
      handling = handling.then(async () => {
        if (pc !== peer) return
        const message = JSON.parse(event.data)
        if (message.type === 'offer') {
          await peer.setRemoteDescription({ type: 'offer', sdp: message.sdp }); ready = true
          for (const candidate of pending) await peer.addIceCandidate(candidate)
          pending = []
          const answer = await peer.createAnswer(); await peer.setLocalDescription(answer)
          signal({ type: 'answer', sdp: answer.sdp }); status.textContent = 'Connecting'
        } else if (message.type === 'candidate') {
          const candidate = { candidate: message.candidate, sdpMid: message.sdpMid, sdpMLineIndex: message.sdpMLineIndex }
          if (ready) await peer.addIceCandidate(candidate); else pending.push(candidate)
        } else if (message.type === 'peer-left') end('Room ended the call. Join again for the next call.')
        else if (message.type === 'busy') end('Another rep page is connected. End that call first.')
      }).catch(error => { if (pc === peer) end(`Could not connect: ${error.message}`) })
    }
    socket.onopen = () => { if (pc === peer) status.textContent = 'Waiting for the room iPad' }
    socket.onerror = () => { if (pc === peer) end('Could not reach the laptop server. Check it and join again.') }
    socket.onclose = () => { if (pc === peer) end('Signaling disconnected. Check the server and join again.') }
    $('end').disabled = false
  } catch (error) { if (generation === run) end(`Microphone unavailable: ${error.message}`) }
}
window.addEventListener('pagehide', () => end())
refreshQuestions()
