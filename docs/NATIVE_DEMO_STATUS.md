# Native demo status — October 25, 2026

This checkout is the integrated candidate, not merged main. Use the native Northstar app on both devices. No browser page, Node process, address entry or localhost server is needed for this path.

## Launch and connect

1. Build `NorthstarOR` with XcodeGen/Xcode. For the laptop choose **My Mac (Mac Catalyst)**; for the room choose the physical iPad. Select your own development team locally.
2. Set up fictional workspaces, or explicitly load optional samples, on both devices. The Mac defaults to Rep; use Room on the iPad.
3. On the room iPad, Planner → choose a compatible case → **Start recording** or **Resume recording**. Browsing alone does not start a recording. New case and Edit case open the existing validated forms.
4. On both devices choose **Connect devices → Find Northstar devices**. Invite the opposite-role device and accept its pairing invitation. Keep both apps open on the same Wi-Fi. Allow Local Network access.
5. On the Mac open **Remote Support**. It receives the current case/checklist and complete recorded activity even before the room asks a question. Later recording changes update that brief.
6. Send case messages in either app. Contextual questions retain their original attached checklist snapshot; the rep acknowledges/replies in Remote Support.
7. Choose **Session and call → Request call** on either side. The other app shows Accept/Decline. Microphone access and room-camera access happen only after acceptance. Rep sends audio and receives room video; rep camera is not requested. Use headphones.
8. Check mute/unmute on both devices, room camera off/on and Flip camera. End call, then send another message. Ending media must preserve the case connection. Stopping the device connection ends media too.

## Feature claim audit

| Capability | Implementation in this candidate | Evidence / remaining limit |
| --- | --- | --- |
| Blank setup, editable workspace and contacts | Repository-backed forms and settings | Existing unit coverage; previous UI checks; new normal-launch UI check opens case form and starts recording |
| Create/edit/start/resume cases | Case form connected to Planner; compatible cases start through explicit action | Normal-launch UI test passed; unsupported templates remain blocked |
| Co-pilot recording | Explicit confirmation, deferral, pinned acknowledgment, correction, retained events | Domain/integration coverage; team remains recording authority |
| Late native rep join | Full read-only room projection over encrypted Multipeer session | Model tests pass; physical pairing and live case update confirmed; initial physical no-case result traced to no active recording and missing Planner entry wiring, now fixed |
| Messages and contextual question/ack/reply | Stable message IDs, persistence before send/receipt, retry and reconnect replay, shared thread | Native integration tests pass; browser pending-outbox regressions pass; rep-to-room message saved on the physical iPad with a receipt shown on Mac; room question also appears on Mac |
| Call invitation | Either side requests; acceptance required; decline/cancel; 30-second expiry; deterministic simultaneous-request winner; origin/call-ID checks | State regressions pass; native media wiring builds; physical call proof pending |
| Audio and room video | Native WebRTC, two-way audio, room-only camera, native received-video renderer | Mac Catalyst and real iPad builds pass; new native-to-native audio/video still needs human walkthrough |
| Basic call controls | Both sides mute/end; room camera off/on and front/back; camera-off hides frozen image | Lifecycle reviewed and builds pass; physical control checks pending |
| Alerts | Persistent recorded deferrals and optional short native rep speech outside calls | Implemented; no closed-app or push notification service |
| Coverage Matcher | Simulated logistical risk/options, reasons and reduced-support context | Existing unit coverage. Named-rep plan requests, acceptance and rescheduling are NOT implemented here |
| Hands-free voice commands | Parser/recognition service exists but is not connected to recording/rep UI | Do not demonstrate or claim working voice commands |
| Computer vision / conversational AI | Not implemented | Video sharing is not image interpretation; recap is recorded data, not AI |
| Internet/distant support, authentication, background calls, export | Not implemented | Nearby fictional demonstration only; local role/pairing is not verified identity |

## Checks actually run this pass

- Final complete unit suite: **157 passed** after the native, save-recovery and reduced-support persistence changes.
- Final affected native integration checks: **12 passed**, including the first four new native session checks (late join/no question, retained messages, stable retry, save recovery, expired/canceled invitation guards).
- Normal-launch iPad UI check: **1 passed**, loading samples through ordinary UI, opening/canceling New case, selecting a case and starting Co-pilot. Screenshot retained in the Xcode test result.
- Browser/server regressions: **4 passed**, including pending message recovery/stable retry and invitation acceptance/expiry regressions.
- Signed **Mac Catalyst build succeeded** and signed **physical iPad build succeeded** after the native changes. Both apps opened; iPad installed without clearing stored records.
- Native physical pairing and live case feed succeeded. Mac showed the iPad’s first team-confirmed item. A fictional rep note was verified in the physical iPad’s persisted workspace file; Mac showed its recipient receipt. A room question appeared on Mac. Human audio/video/control walkthrough remains pending.
- Generated Xcode project is ignored. No push/PR/merge performed. Primary dirty checkout preserved.

Logs are in ignored `build/native-unit.log`, `native-focused-final.log`, `native-entry-ui.log`, `native-mac-final.log`, and `native-device-final.log`. Unit/model tests use injected transports; they do not prove Wi-Fi delivery, microphone output, camera capture or usability. No synthetic microphone tones were used. VoiceOver, enlarged text, keyboard, contrast and Reduce Motion were not rechecked for this pass.

Native Mac evidence: `docs/evidence/native-shared-session/mac-live-session.png` shows the real app in Rep mode with a received question and message receipt. It is a native Mac window, not a browser.

The physical call check exposed a missing Mac hardened-runtime audio-input entitlement. `NorthstarOR/Supporting/MacCatalyst.entitlements` now supplies it only for the Mac SDK; the signed Mac bundle was inspected to confirm the entitlement. The old running process was fully terminated and the corrected app opened. Microphone access must still be allowed by the owner, and native audio/video proof remains pending. Stopped/failed calls now label the microphone disconnected rather than on.

A focused regression reproduced loss of reduced-support context on relaunch and absence of a rep update. The label is now stored as an additive optional StoredSession field (old files default false), and Planner updates are saved/published. Final unit suite passed with that regression included.
