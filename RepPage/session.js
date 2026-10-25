// Same-Wi-Fi case connection. Joining never requests microphone/camera access.
const $ = id => document.getElementById(id)
let socket, snapshot, current = false, invitation = null
let alertsOn = false, seenAlerts = [], invitationTimer
let outbox = {}
try { outbox = JSON.parse(sessionStorage.getItem('northstar-note-outbox') || '{}') } catch { /* No retained outbox. */ }
try { snapshot = JSON.parse(sessionStorage.getItem('northstar-session-snapshot') || 'null') } catch { /* Empty retained view. */ }
try { alertsOn = sessionStorage.getItem('northstar-alerts') === 'on'; seenAlerts = JSON.parse(sessionStorage.getItem('northstar-seen-alerts') || '[]') } catch { alertsOn = false; seenAlerts = [] }
const originKey = value => JSON.stringify([value?.workspaceID, value?.caseID, value?.sessionID])
const draftKey = origin => 'northstar-note-draft:' + originKey(origin)
const ended = () => Boolean(snapshot?.recordingSummary?.startsWith('Recording ended'))
const saveOutbox = () => sessionStorage.setItem('northstar-note-outbox', JSON.stringify(outbox))
const pendingNotes = () => Object.values(outbox).filter(envelope => originKey(envelope.origin) === originKey(snapshot?.origin))
const swiftNow = () => Date.now() / 1000 - 978307200
const noteMessageID = note => [note.workspaceID, note.caseID, note.sessionID, note.id].map(value => `${new TextEncoder().encode(value).length}:${value}`).join('') + ':note'
const send = frame => {
  if (socket?.readyState !== WebSocket.OPEN || !current) throw Error('Session is not current. Rejoin and retry; your text is kept.')
  socket.send(JSON.stringify(frame))
}
window.northstarSession = {
  ready: () => current && socket?.readyState === WebSocket.OPEN,
  origin: () => current ? snapshot?.origin : null,
  canStartMedia: () => current && !ended() && invitation?.state === 'accepted' && originKey(invitation.origin) === originKey(snapshot?.origin),
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
  const thread = []
  for (const question of snapshot?.questions || []) thread.push({ at: question.sentAt, title: 'Team question', text: question.text })
  for (const note of snapshot?.messages || []) thread.push({ at: note.sentAt, title: note.actor?.displayName || 'Message', text: note.text, pending: Boolean(outbox[noteMessageID(note)]) })
  thread.sort((a, b) => a.at - b.at)
  $('session-thread').replaceChildren()
  for (const entry of thread) {
    const item = document.createElement('li')
    item.textContent = `${entry.title}: ${entry.text}${entry.pending ? ' · Waiting for room receipt' : ''}`
    $('session-thread').append(item)
  }
  const ended = Boolean(snapshot?.recordingSummary?.startsWith('Recording ended'))
  $('invitation-request').disabled = !current || ended
  $('session-note-retry').disabled = !current || !pendingNotes().length
  $('join').hidden = true
  $('invitation-accept').hidden = !(!ended && current && invitation?.state === 'requested' && invitation.from === 'room')
  $('invitation-decline').hidden = $('invitation-accept').hidden
  $('invitation-cancel').hidden = !(invitation?.state === 'requested' && invitation.from === 'rep')
  $('invitation-status').textContent = invitation ? `Call ${invitation.state}` : (ended ? 'Recording ended. A call cannot start.' : 'No call requested')
  $('session-alerts').textContent = alertsOn ? 'Alerts on' : 'Enable alerts'
  $('session-leave').disabled = !socket
  window.dispatchEvent(new Event('northstar-session'))
}
function notice(previous, next) {
  if (!previous || !next) return
  const banners = []
  for (const line of next.context.lines || []) {
    const before = (previous.context.lines || []).find(item => item.id === line.id)
    if (line.status === 'deferred' && before?.status !== 'deferred') banners.push({ key: `defer:${line.id}:${next.context.recordingRevision}`, text: `${line.title} was deferred.` })
  }
  for (const question of next.questions || []) {
    if (!(previous.questions || []).some(item => item.id === question.id)) banners.push({ key: `question:${question.id}`, text: 'A question is waiting on this case.' })
  }
  const fresh = banners.filter(item => !seenAlerts.includes(item.key))
  if (!fresh.length) return
  $('session-alert').hidden = false
  $('session-alert').textContent = fresh.map(item => item.text).join(' ')
  seenAlerts.push(...fresh.map(item => item.key))
  try { sessionStorage.setItem('northstar-seen-alerts', JSON.stringify(seenAlerts)) } catch { /* The banner remains visible. */ }
  if (alertsOn && !window.northstarCallActive?.() && globalThis.speechSynthesis) {
    for (const item of fresh) speechSynthesis.speak(new SpeechSynthesisUtterance(item.text))
  }
}
function disconnected(message) {
  cancelInvitation(false)
  current = false; $('session-status').textContent = message; render()
  window.dispatchEvent(new Event('northstar-session-lost'))
}
function leave() {
  cancelInvitation(true)
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
        if (!Array.isArray(next.messages)) next.messages = []
        if (current && snapshot && originKey(snapshot.origin) === originKey(next.origin) && next.context.recordingRevision < snapshot.context.recordingRevision) return
        const oldOrigin = snapshot && originKey(snapshot.origin)
        const prior = snapshot
        const wasCurrent = current
        // Pending notes live independently of the authoritative room snapshot.
        for (const envelope of Object.values(outbox)) {
          if (originKey(envelope.origin) === originKey(next.origin) && !next.messages.some(note => note.id === envelope.note.id)) next.messages.push(envelope.note)
        }
        sessionStorage.setItem('northstar-session-snapshot', JSON.stringify(next))
        if (oldOrigin && oldOrigin !== originKey(next.origin)) cancelInvitation(true)
        snapshot = next; current = true
        if (ended()) cancelInvitation(true)
        if (!wasCurrent || oldOrigin !== originKey(next.origin)) $('session-note').value = sessionStorage.getItem(draftKey(next.origin)) || ''
        notice(prior, next)
        if (oldOrigin && oldOrigin !== originKey(next.origin)) window.dispatchEvent(new Event('northstar-session-changed'))
        $('session-status').textContent = 'Joined room session · checklist recording stays with the room'
        render()
        for (const question of next.questions) {
          const brief = { ...question, delivery: 'onThisDevice' }
          delete brief.acknowledgement; delete brief.reply
          window.northstarReceiveSupport?.({ id: messageID(question), kind: 'question', sentAt: question.sentAt, origin: next.origin, questionID: question.id, question: brief })
          window.northstarRestoreResponse?.(question)
        }
        for (const note of next.messages || []) {
          if (outbox[noteMessageID(note)]) continue
          send({ type: 'support-envelope', envelope: { id: noteMessageID(note) + ':receipt', kind: 'receipt', sentAt: swiftNow(), origin: next.origin, questionID: note.id, receiptForID: noteMessageID(note) } })
        }
      } else if (frame.type === 'support-envelope' && current && originKey(frame.envelope?.origin) === originKey(snapshot.origin)) {
        if (frame.envelope.kind === 'note') rememberNote(frame.envelope)
        else if (frame.envelope.kind === 'receipt' && snapshot.messages?.some(note => noteMessageID(note) === frame.envelope.receiptForID)) {
          const note = snapshot.messages.find(item => noteMessageID(item) === frame.envelope.receiptForID)
          note.delivery = 'receivedByPeer'
          delete outbox[frame.envelope.receiptForID]
          saveOutbox()
          try { sessionStorage.setItem('northstar-session-snapshot', JSON.stringify(snapshot)) } catch { /* Receipt stays visible for this page. */ }
          $('session-note-status').textContent = 'Message received on the room iPad'
          render()
        } else window.northstarReceiveSupport?.(frame.envelope)
      } else if (frame.type === 'call-invitation' && current && originKey(frame.invitation?.origin) === originKey(snapshot.origin)) {
        receiveInvitation(frame.invitation)
      } else if (frame.type === 'peer-left') disconnected('Room disconnected. Last received record remains below.')
      else if (frame.type === 'busy') { leave(); $('session-status').textContent = 'Another rep session is connected. Leave that session first.' }
    } catch (error) {
      disconnected(`Session data not retained: ${error.message}. Rejoin to retry.`)
    }
  }
  connection.onclose = () => { if (socket === connection) { socket = null; disconnected('Session disconnected. Rejoin to refresh the room record.') } }
  connection.onerror = () => { if (socket === connection) disconnected('Could not reach the server. Check the same Wi-Fi connection.') }
}
function rememberNote(envelope) {
  const note = envelope.note
  if (!note || note.id !== envelope.questionID || note.sessionID !== envelope.origin.sessionID) return
  if (!snapshot.messages.some(item => item.id === note.id && item.text === note.text)) {
    if (snapshot.messages.some(item => item.id === note.id)) return
    snapshot.messages.push(note)
  }
  sessionStorage.setItem('northstar-session-snapshot', JSON.stringify(snapshot))
  render()
  send({ type: 'support-envelope', envelope: { id: envelope.id + ':receipt', kind: 'receipt', sentAt: swiftNow(), origin: envelope.origin, questionID: note.id, receiptForID: envelope.id } })
}
function setInvitation(value) {
  clearTimeout(invitationTimer)
  invitationTimer = null
  invitation = value
  if (value?.state === 'requested') {
    invitationTimer = setTimeout(() => {
      if (invitation?.id !== value.id || invitation.state !== 'requested') return
      sendInvitation({ ...value, state: 'expired' })
    }, Math.max(0, (value.sentAt + 30 - swiftNow()) * 1000))
  }
  render()
}
function sendInvitation(value) {
  send({ type: 'call-invitation', invitation: value })
  setInvitation(value)
}
function cancelInvitation(notify) {
  const old = invitation
  if (notify && old && current) {
    try { send({ type: 'call-invitation', invitation: { ...old, state: 'canceled' } }) } catch { /* Connection may already be closed. */ }
  }
  setInvitation(null)
}
function receiveInvitation(value) {
  if (!value || !['room', 'rep'].includes(value.from) || !Number.isFinite(value.sentAt)) return
  if (value.state === 'requested') {
    if (ended() || swiftNow() >= value.sentAt + 30) {
      send({ type: 'call-invitation', invitation: { ...value, state: ended() ? 'declined' : 'expired' } }); return
    }
    if (invitation?.state === 'accepted') {
      send({ type: 'call-invitation', invitation: { ...value, state: 'declined' } }); return
    }
    if (invitation?.state === 'requested' && invitation.id !== value.id) {
      if (value.id < invitation.id) send({ type: 'call-invitation', invitation: { ...invitation, state: 'canceled' } })
      else { send({ type: 'call-invitation', invitation: { ...value, state: 'declined' } }); return }
    }
    setInvitation(value)
  } else if (invitation?.id === value.id && originKey(invitation.origin) === originKey(value.origin)) {
    if (value.state === 'accepted' && invitation.state === 'requested' && invitation.from === 'rep') {
      if (ended() || swiftNow() >= invitation.sentAt + 30) { sendInvitation({ ...invitation, state: 'expired' }); return }
      setInvitation({ ...invitation, state: 'accepted' })
      window.northstarStartMedia?.()
    } else if (['declined', 'canceled', 'expired'].includes(value.state)) {
      setInvitation(value)
      window.dispatchEvent(new Event('northstar-session-lost'))
    }
  }
}
$('session-note').oninput = () => {
  if (!snapshot?.origin) return
  try { sessionStorage.setItem(draftKey(snapshot.origin), $('session-note').value) }
  catch { $('session-note-status').textContent = 'Draft storage unavailable. Keep this page open.' }
}
function retryNotes() {
  try {
    for (const envelope of pendingNotes()) send({ type: 'support-envelope', envelope })
    $('session-note-status').textContent = 'Message kept. Waiting for the room receipt.'
  } catch (error) { $('session-note-status').textContent = error.message }
}
$('session-note-retry').onclick = retryNotes
$('session-note-send').onclick = () => {
  const text = $('session-note').value.trim()
  if (!text || !snapshot?.origin) return
  const note = { id: globalThis.crypto?.randomUUID?.() || `note-${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`, ...snapshot.origin, text, sentAt: swiftNow(), delivery: 'onThisDevice',
    actor: { id: 'laptop-rep', workspaceID: 'northstar-laptop-rep', displayName: 'Fictional rep (laptop)', statedRole: 'technicalRep' } }
  const envelope = { id: noteMessageID(note), kind: 'note', sentAt: note.sentAt, origin: snapshot.origin, questionID: note.id, note }
  try {
    outbox[envelope.id] = envelope
    try { saveOutbox() } catch (error) { delete outbox[envelope.id]; throw error }
    snapshot.messages ||= []
    snapshot.messages.push(note)
    $('session-note').value = ''
    sessionStorage.removeItem(draftKey(snapshot.origin))
    render()
    retryNotes()
  } catch (error) { $('session-note-status').textContent = `Message was not saved: ${error.message}. Keep your text and retry.` }
}
$('session-alerts').onclick = () => {
  alertsOn = !alertsOn
  try { sessionStorage.setItem('northstar-alerts', alertsOn ? 'on' : 'off') } catch { $('session-status').textContent = 'Alert preference was not saved. The banner still shows.' }
  render()
}
$('invitation-request').onclick = () => {
  if (!current || !snapshot?.origin || ended() || invitation?.state === 'requested' || invitation?.state === 'accepted') return
  sendInvitation({ id: `call-${Date.now().toString(36)}`, origin: snapshot.origin, from: 'rep', state: 'requested', sentAt: swiftNow() })
}
$('invitation-accept').onclick = () => {
  if (!current || ended() || invitation?.state !== 'requested' || invitation.from !== 'room') return
  if (swiftNow() >= invitation.sentAt + 30) { sendInvitation({ ...invitation, state: 'expired' }); return }
  try { sendInvitation({ ...invitation, state: 'accepted' }); window.northstarStartMedia?.() }
  catch (error) { $('invitation-status').textContent = error.message }
}
$('invitation-decline').onclick = () => { if (invitation?.state === 'requested') sendInvitation({ ...invitation, state: 'declined' }) }
$('invitation-cancel').onclick = () => { if (invitation?.state === 'requested') sendInvitation({ ...invitation, state: 'canceled' }) }
window.addEventListener('northstar-call-ended', () => { if (invitation?.state === 'accepted') { setInvitation(null) } })
window.addEventListener('pagehide', leave)
render()
