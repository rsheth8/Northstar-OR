# In-app call integration

Local branch `sync/in-app-call-integrated` builds on `e783642` (approved Focus layout plus saved nearby support). Cursor’s uncommitted primary checkout is preserved. No push, PR or merge performed.

## What changed

- Call rep controls remain in the app shell alongside Nearby iPad; the Focus layout is retained. Closing the sheet keeps the call; ending, changing roles/transports or backgrounding stops capture.
- WebRTC is a `NearbyTransport` selected through `SyncService` by `AppModel`. Questions use existing `SupportEnvelope` values, frozen case/session context, durable workspace persistence, exact delivery receipts and explicit retry. Replies return to the Focus panel. There is no parallel transient call-message model and no checklist recording path from a call envelope.
- Browser microphone starts only after Join call from localhost. Original laptop-IP HTTP instructions were unusable for getUserMedia. The iPad still uses the laptop’s LAN IP for signaling. See [MDN](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia#privacy_and_security).
- Signaling has one room/one rep slot, bounded frames, fragmented WebSocket support, late-rep offer replay and ended-call cleanup. No old offer is replayed to a new call. The server serves only the page/script. This remains an unauthenticated fictional local demo, with no TURN relay.
- Call state includes microphone denial, camera unavailable/audio only, connect timeout, send failure and disconnect. Old peer/socket callbacks cannot change a restarted call. A failed send leaves the original saved question available for retry.
- The browser retains question/response values in tab session storage before returning a receipt, scopes response IDs to their original question, and compares JSON semantically across key ordering. It does not claim an institutional identity or durable server storage.

## Checks actually run

- `build/call-integration2.xcresult`: 7 existing NearbySupportIntegrationTests passed. This compiled the integrated call service/view and exercised saved messages, relaunch, receipt, retry and checklist isolation through the transport boundary.
- `node --test RepPage/server.test.mjs`: 1 focused signaling regression passed (late join, answer, extra-peer rejection, disconnect, no stale replay, new call).
- `build/call-journey-silent.xcresult`: 1 actual simulator-to-browser WebRTC journey passed, iPad Pro 13-inch M5 / iOS 26.5, 1376×1032 pt landscape. Room defers item, saves question, connects to Chrome, explicitly sends the saved question, receives independent acknowledgment/reply, returns to Focus with the required warning still pending, ends call and retains reply/warning. Browser confirms the room’s scoped receipt for its reply.
- Browser used a synthetic microphone **disabled before transmission** and muted received playback. This proves signaling/data interoperability, not intelligibility or echo performance. Simulator camera is intentionally absent.
- Final incremental simulator build passed after timeout handling changed. Generated plist inspected: camera/microphone/local-network usage, local networking ATS and the existing Bonjour service are all present. No generated project committed.
- Independent code review found the localhost instructions issue (fixed), with no further definite blockers identified. Review is not a GitHub approval.
- Initial bridge attempt connected, but failed on an ambiguous UI test selector (sheet and background both expose the saved-question button). Scoped the selector to the call sheet and reran successfully. The initial unmuted fake microphone emitted a tone; that call was stopped and the harness was changed to silence both directions before continuing.
- `git diff --check` passed. No full unit/UI suite rerun for this slice.

## Repeat the silent check

Run `node RepPage/server.mjs`. With Playwright available and Chrome installed, run `node docs/evidence/nearby-support/call-browser-check.cjs` (or set `NORTHSTAR_PLAYWRIGHT_MODULE` to its package directory). Then run only `NorthstarORUITests/NearbyCallJourneyTests` on the simulator. This optional UI test skips when the server is absent; it requires the joined browser harness when selected. The harness silences its synthetic track and mutes browser playback. It does not test physical audio.

## Hardware and accessibility checks still needed

**NOT RUN:** real iPad ↔ laptop hotspot call, microphone intelligibility, echo/headphones behavior, live back-camera frames, real device permissions and network isolation/recovery. Build with this checkout’s generated project, use [RepPage setup](../../../RepPage/README.md), and verify those before presenting video/audio as proven. Simulator support-message proof does not establish camera streaming on hardware.

**NOT RUN for this new sheet:** enlarged text, narrow windows, VoiceOver traversal, hardware keyboard, measured contrast/touch, Reduce Motion interaction. Existing Focus evidence remains in FOCUS_CORRECTION.md; it does not cover this sheet. No animation was added.

## Captures

- [Focus after the real call reply, with warning still pending](focus-call-ipad13-1376x1032pt.png)
- [Saved reply in the call sheet](call-sheet-ipad13-1376x1032pt.png)
- [Laptop receipt of the room’s retained reply](rep-browser-call.png) — blank video is expected on this simulator run.

## Physical trial follow-up: preview and call microphone controls

Owner reported laptop-to-iPad speech audible, but iPad-to-laptop speech and camera were not seen/heard. This is partial user-reported hardware evidence, not a verified two-way call. Xcode also logged a failed local-network signaling attempt (-1009); that attempt cannot establish a connected call. The root cause of the original one-way audio report is not yet proven.

Owner explicitly requested a local iPad camera area and laptop Mute/Unmute controls. Added a renderer of the same outbound camera track, with an explicit unavailable placeholder; retained both video track and source wrapper (RTCCameraVideoCapturer.delegate is weak in the shipped SDK). Camera-on status now follows capture completion. No second capture session or recording was added.

iPad mute is now selectable while connecting, clearly says microphone on/muted for this call, applies the selection when the engine creates the track, and remains independent of system output volume. Added laptop microphone track enable/disable with visible state. Room audio has a dedicated audio element; a later video event cannot overwrite the audio stream. Receive-track aggregation handles streamless events and either arrival order. Existing browser diagnostics distinguish absent packets, absent microphone signal, muted/paused playback and video frames. Connection failure before WebSocket open is now surfaced immediately through URLSessionTaskDelegate.

Verification: physical iPad build passed (`build/call-controls-device3.log`); `node --test RepPage/call-controls.test.mjs` passed one focused check against the real browser script for outgoing track mute/unmute, independent audio/video arrival, and cleanup. Syntax and diff checks passed. The earlier successful integration journey was extended with iPad mute UI assertions but **not rerun** for this follow-up; no fresh physical audio/video success is claimed. The installed build and browser page headed “Call controls 3 · microphone and room camera” are ready for the next owner-operated trial. No audible synthetic test was run.
