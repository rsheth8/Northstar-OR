# Shared support session on the same Wi-Fi

Status: proposed design for owner review. This document does not claim implementation.

## Intent and chosen approach

The room starts or resumes a fictional case in Co-pilot. A representative joins that specific session on the laptop, sees a recap of recorded progress, follows later changes, exchanges messages, and optionally joins a call. Joining the session never enables a microphone or camera. The owner selected extending the working local connection; the physically tested network was the same Wi-Fi, not a phone hotspot.

Alternatives considered: extend the current local server and WebRTC call (chosen: reuses the proven call and devices); introduce hosted rooms, accounts and remote notifications (deferred: a separate service and delivery scope). A hotspot may be another local network but has not been established by this test. No internet-distance support claim follows from same-Wi-Fi operation.

## One record and explicit session identity

Co-pilot remains the room's recording authority and keeps the approved Focus layout. Representative actions cannot confirm, defer, acknowledge a checklist warning, or otherwise change a checklist item. Question acknowledgment and checklist-warning acknowledgment remain different actions.

Every shared update, message and call invitation carries workspace, case and session identity. A room explicitly shares its active recording and selects the intended fictional support contact. The server supports one room and one representative for this slice. The laptop shows the offered case identity and a Join session action. A second participant receives an occupied result. Local contact/role selection is not authenticated identity.

Changing the active case ends its active call and stops its live share. The old record stays reviewable, and the next case requires explicit sharing and joining. Late callbacks or messages never migrate into another case. Ending a recording publishes that state and retains unresolved items; the rep sees a read-only ended record and calling is disabled.

## Persistent session connection; optional media

Extend the existing local server with a session-control/message channel separate from WebRTC media signaling. Route it through SyncService and AppModel, not networking in views. Keep WebRTC for the proven two-way audio and room-to-laptop video. Ending a call closes media and releases microphone/camera while preserving the session connection and messages. Leaving a session closes both.

The room is the durable source for the case and recording history. The server relays and holds only bounded connection state; it is not a second authoritative case database. After a join/reconnect, the room sends a complete revisioned snapshot and retained exchange, then later revisions. The receiver ignores older revisions and requests a fresh snapshot after a gap. Snapshot application and subsequent events must be ordered so updates during joining are not lost. If the room is absent, the laptop shows its retained copy as disconnected with the last received time.

Transport connected, session joined/current, message received, question acknowledged, call ringing, and call connected are distinct visible states. Socket delivery is not a receiver receipt. No automatic microphone/camera restart after disconnection.

## Late-join recap and live progress

The laptop leads with case/reference/site, recording state, current item, outstanding questions, deferred/unrecorded items, and team-confirmed items. A compact deterministic recap uses recorded data; no AI or invented clinical summary. The full recorded session activity is expandable with source and time. This requires all recorded events, rather than the existing eight-event question excerpt.

Show later changes and the last update time. A question retains its original wording and original context snapshot; current context is a separate section. Disconnect never looks live. Rejoining refreshes from the room before claiming the context is current.

## Messages and requests

Provide a chronological session thread on Co-pilot's support panel, the laptop station, and the iPad Remote tab. Both parties can send multiple plain-text messages before, during and after a call. Contextual support requests remain first-class thread entries with an explicit recipient, original snapshot, acknowledgment and replies. Existing saved questions/replies migrate or project into this thread without losing identifiers or receipts.

Retain outgoing text before sending; show pending, recipient-received, or failed with retry. Receive and retain before issuing a receipt. Stable message IDs deduplicate retries. Drafts and history remain scoped to the session and survive room app relaunch; the laptop retains its history/drafts in browser storage. If local storage fails, show the failure and do not claim saved or received. A reconnect exchanges outstanding records and receipts without duplicating entries. Use text rendering rather than HTML interpretation and bound payload sizes/history transfer.

## Essential call controls

Either joined participant can request a call; the recipient sees an incoming invitation and accepts or declines. Display requesting/ringing, declined/canceled, connecting, connected and failed states truthfully. A bounded unanswered invitation expires. Simultaneous requests resolve to a single call. A late acceptance cannot revive an ended invitation.

Both endpoints have labeled mute/unmute and end-call controls. Mute controls outbound call audio, not device-wide sound. The iPad has room camera on/off, front/back camera switching when supported, and a local preview of the transmitted track. Turning video off stops camera capture and informs the laptop; microphone audio can continue. Switching preserves the current microphone state and reports failure. The laptop displays incoming room video, camera-off/unavailable state, and an audio-play fallback if the browser blocks playback. Rep camera transmission remains outside this slice; the existing design is room video with two-way audio.

Request media permissions at call acceptance/start, not session join. Denied camera permits an explicitly labeled audio-only call. Denied microphone shows an actionable failure. Missing cameras and simulator camera absence are visible; disable unsupported switching. Show the current system audio route where available, with speaker selection on iPad if supported; respect headphones and use echo cancellation. Do not claim selectable routes the platform cannot expose. No media recording, screen sharing, file attachments or clinical image analysis.

Reuse the working media engine and avoid forcing the user to re-enter the server address for every call. Keep mute/video state and actual track/capture state aligned. End/leave/background/interruption cleans up media and shows disconnection; returning requires an explicit call action. Low delay is a target to verify on the actual devices, not a promised measured result.

## Alerts, voice and screens

A joined laptop can show a persistent question/required-deferral alert even outside a call. Optional spoken alerts require an explicit Enable alerts action and deduplicate event IDs. Do not interrupt a call with spoken alerts. A closed page, sleeping device or disconnected app is not reachable; no phone/push/background delivery promise.

Co-pilot retains dominant current work and the right support panel. The support panel exposes session status, messages, request support and call controls without hiding the pinned deferral warning. The laptop has recap/progress, thread and call area, with video prominent during calls. The iPad Remote tab uses the same session/exchange projection: room mode is the support record; rep mode can continue the existing nearby-iPad exchange. It must not impersonate a second participant on the room device. Extending the new Wi-Fi laptop protocol to a second native rep iPad is not required in this slice.

Hands-free checklist commands are a later bounded task. Existing recognition is not wired in, and its audio-session handling needs coordination with calls. Do not enable it alongside WebRTC or label the app fully hands-free. Large touch controls and current purposeful spoken warnings remain available. No decorative pulse, glow or automatic camera activation.

## Delivery and focused evidence

Implement in dependent slices: session channel and late-join snapshot; durable thread/receipts and both screen projections; call invitation lifecycle and camera controls; real-device integration evidence. Add no provider or unrelated feature. Preserve teammate work in the primary checkout; build from the isolated integrated call branch. Reserve exact shared/model/service/view files in TASKS before implementation.

Focused checks cover: join after progress with no question/call; an update during join; message/reply receipt and reconnect deduplication; stale session isolation; mute/video/switch state; invitation cancellation. Run an affected native build and focused regressions, not repeated full suites. Physically verify both audio directions, mute on both endpoints, room camera switching/off/on, permission failure, end-call with continued messages, and reconnect using the real iPad and laptop on the same Wi-Fi. Do not use audible synthetic microphone tests. Record only checks actually run and capture relevant device sizes/failure states; leave unrun accessibility checks explicit.

Builder discretion: names of new DTOs/services, bounded transfer sizing and invitation timeout, event batching, and file splitting. Preserve current storage/receipt guarantees, protocol boundaries and semantic design tokens. No new external dependency is needed by this design.
