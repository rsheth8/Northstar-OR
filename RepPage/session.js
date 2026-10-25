// Same-Wi-Fi case connection. Joining never requests microphone/camera access.
const $ = id => document.getElementById(id)
let socket, snapshot, current = false
try { snapshot = JSON.parse(sessionStorage.getItem('northstar-session-snapshot') || 'null') } catch { /* Empty retained view. */ }
const originKey = value => JSON.stringify([value?.workspaceID, value?.caseID, value?.sessionID])
const send = frame => {
  if (socket?.readyState !== WebSocket.OPEN || !current) throw Error('Session is not current. Rejoin and retry; your text is kept.')
  socket.send(JSON.stringify(frame))
}
window.northstarSession = {
  ready: () => current && socket?.readyState === WebSocket.OPEN,
  origin: () => current ? snapshot?.origin : null,
  send: envelope => {
    if (originKey(envelope.origin) !== originKey(snapshot?.origin)) throw Error('This message belongs to another case. Its saved record remains available.')
    send({ type: 'support-envelope', envelope })
  }
}
const messageID = q => [q.workspaceID, q.caseID, q.sessionID, q.id].map(v => `${new TextEncoder().encode(v).length}:${v}`).join('') + ':question'
function render() {
  $('session-context').textContent = snapshot ? `${snapshot.context.caseReference} · ${snapshot.context.caseName} · ${snapshot.context.siteName}` : 'No case received yet'
  $('session-summary').textContent = snapshot ? `${snapshot.recordingSummary} · ${snapshot.saved ? 'Room record saved' : 'Room has unsaved changes'} · ${current ? 'Current' : 'Disconnected copy'} · Last update ${new Date((snapshot.context.capturedAt + 978307200) * 1000).toLocaleTimeString()}` : 'Join the room session to receive progress without starting a call.'
  $('session-lines').replaceChildren()
  for (const line of snapshot?.context.lines || []) {
    const item = document.createElement('li')
    const label = line.status === 'teamConfirmed' ? 'Team-confirmed' : line.status === 'deferred' ? 'Deferred' : 'Unrecorded'
    item.textContent = `${line.title} — ${label}${line.id === snapshot.context.selectedItemID ? ' · Current item' : ''}`
    $('session-lines').append(item)
  }
  $('session-events').replaceChildren()
  for (const text of snapshot?.context.recentEvents || []) {
    const item = document.createElement('li'); item.textContent = text; $('session-events').append(item)
  }
  $('session-leave').disabled = !socket
  window.dispatchEvent(new Event('northstar-session'))
}
function disconnected(message) {
  current = false; $('session-status').textContent = message; render()
  window.dispatchEvent(new Event('northstar-session-lost'))
}
function leave() {
  const old = socket; socket = null; old?.close()
  disconnected('Session left. Retained context is a disconnected copy.')
}
$('session-leave').onclick = leave
$('session-join').onclick = () => {
  leave()
  const connection = new WebSocket(`${location.protocol === 'https:' ? 'wss' : 'ws'}://${location.host}/session?role=rep`)
  socket = connection
  $('session-status').textContent = 'Connecting to the room session'
  connection.onopen = () => {
    if (socket !== connection) return
    connection.send(JSON.stringify({ type: 'snapshot-request' }))
    $('session-status').textContent = 'Waiting for the room to share its case'
  }
  connection.onmessage = event => {
    if (socket !== connection) return
    try {
      const frame = JSON.parse(event.data)
      if (frame.type === 'session-snapshot') {
        const next = frame.snapshot
        if (!next?.origin?.sessionID || !next.context?.lines || !Array.isArray(next.questions)) throw Error('Invalid case snapshot')
        if (current && snapshot && originKey(snapshot.origin) === originKey(next.origin) && next.context.recordingRevision < snapshot.context.recordingRevision) return
        const oldOrigin = snapshot && originKey(snapshot.origin)
        sessionStorage.setItem('northstar-session-snapshot', JSON.stringify(next))
        snapshot = next; current = true
        if (oldOrigin && oldOrigin !== originKey(next.origin)) window.dispatchEvent(new Event('northstar-session-changed'))
        $('session-status').textContent = 'Joined room session · checklist recording stays with the room'
        render()
        for (const question of next.questions) {
          const brief = { ...question, delivery: 'onThisDevice' }
          delete brief.acknowledgement; delete brief.reply
          window.northstarReceiveSupport?.({ id: messageID(question), kind: 'question', sentAt: question.sentAt, origin: next.origin, questionID: question.id, question: brief })
          window.northstarRestoreResponse?.(question)
        }
      } else if (frame.type === 'support-envelope' && current && originKey(frame.envelope?.origin) === originKey(snapshot.origin)) {
        window.northstarReceiveSupport?.(frame.envelope)
      } else if (frame.type === 'peer-left') disconnected('Room disconnected. Last received record remains below.')
      else if (frame.type === 'busy') { leave(); $('session-status').textContent = 'Another rep session is connected. Leave that session first.' }
    } catch (error) {
      current = false
      $('session-status').textContent = `Session data not retained: ${error.message}. Rejoin to retry.`
      render()
    }
  }
  connection.onclose = () => { if (socket === connection) { socket = null; disconnected('Session disconnected. Rejoin to refresh the room record.') } }
  connection.onerror = () => { if (socket === connection) disconnected('Could not reach the server. Check the same Wi-Fi connection.') }
}
window.addEventListener('pagehide', leave)
render()
