# Cursor handoff: shared Wi-Fi session

## Start here

User wants efficient completion with limited Codex usage. Continue in the integrated checkout below, NOT the dirty primary checkout. Preserve the chosen Focus Co-pilot design and working real-device WebRTC media. Only local commits are authorized; no push/PR/merge was requested.

- Checkout: `/Users/rahilsheth/.codex/worktrees/nearby-support-exchange/northstar-or`
- Branch: `sync/shared-session-foundation`
- Primary checkout to preserve: `/Users/rahilsheth/Documents/Projects/northstar-or` (contains separate uncommitted Cursor work; do not overwrite/stage/reset it).
- Baseline working call/control commit: `7737f64`; prior integration `ee9dad2`.
- Approved design: `docs/superpowers/specs/2026-10-25-shared-support-session-design.md`.
- Execution plan/ledger: `docs/superpowers/plans/2026-10-25-shared-support-session.md`.
- Read AGENTS.md and referenced product/ownership docs first. The owner explicitly approved the recommended local approach and requested basic media controls; design approval is complete. No need to repeat brainstorming.

## What this bounded slice adds

1. `/session?role=room|rep` WebSocket pair in `RepPage/server.mjs`, isolated from the existing WebRTC signaling pair. No server-side case database; fresh snapshots come from the room on each join/rejoin.
2. `SharedSessionTransport.swift` implements existing `NearbyTransport` through SyncService. It publishes `SharedSessionSnapshot { origin, context, recordingSummary, saved, questions }`. Context includes ALL session events for late-join recap. Questions remain immutable original snapshots.
3. AppModel `startSharedSession(server:)`, `isSharingSession`, `publishSharedSession()`, `endRepCall()`. Recording and support changes publish snapshots. Snapshot questions are withheld while storage has failed so an unsaved response never looks received. Receipt-only input does NOT republish snapshots (avoids receipt/snapshot loops).
4. The Call rep sheet now has Share current case / Stop sharing controls. When sharing, `nearbyCall` is a separate media controller; ending media does not replace or stop the SyncService data transport. Active-case switch, role/background shutdown and session disconnection release media. Existing nearby-iPad behavior remains separate.
5. Laptop `session.js` provides explicit Join/Leave session, current case/checklist, full recorded activity, saved-question replay and existing ack/reply before a call. It stores the snapshot before receipts, filters stale revisions within a connection, accepts the authoritative first snapshot after reconnect (including rollback after unsaved room changes), and disables old-case responses. `call.js` uses the session channel when current and retains the legacy WebRTC data channel fallback.
6. RemoteSupportView shows the current room record and the same persisted support questions. It is not yet a complete redesigned rep station.

## Still required, in priority order

### A. Physical foundation walkthrough first

Start the server from THIS checkout, join/share WITHOUT a call, record a fictional confirmation/deferral, verify late join and live updates, acknowledge/reply and verify room receipt. End a media call and verify further support exchange still works. Disconnect/rejoin and verify no duplicate question or wrong-case data. No claim that this new flow has been physically verified yet.

### B. Durable multi-message chat

Current exchange is multiple contextual questions, each with one acknowledgment and one reply. It is NOT arbitrary multi-message chat. Add session-scoped message IDs, actor/time/text, drafts and exact receipts with backward-compatible storage decoding/validation. Keep current contextual question snapshots and receipts; don't bolt on a second private record in a view. Project the same chronological thread in CoPilotSupportPanel, RemoteSupportView and laptop. Preserve text before sending and receiving before receipt; retry/deduplicate across reconnect.

### C. Call invitation lifecycle

Currently still manual Join call on laptop + Start call on room. Add session-scoped unique invitation ID, request/accept/decline/cancel/timeout, simultaneous-request resolution and no stale acceptance. Request media permissions/start tracks only after acceptance. End call preserves shared session; Leave ends both. Ended recordings must not start calls. Session joining alone never requests media.

### D. Essential camera controls

Mute/unmute and local room preview already exist and the owner reported the prior media call working. Still missing: camera off/on and front/back switching. Extend NearbyCallController + NearbyCallEngine in `Services/NearbyCallSession.swift` and call sheet. Retain source/capturer/track (capturer delegate is weak); switch capture device rather than creating a second independent camera session. Stop capture when off; show remote off/unavailable state over session channel. Respect simulator/denied permission/missing devices and actual asynchronous capture result. Preserve microphone mute across switching. Two-way video is not requested: room camera goes to laptop, audio is two-way. Native audio route display/speaker option may be added if supported.

### E. Alert/UI finish

Optional explicit Enable alerts on joined laptop, persistent new-question/deferred-item banner, deduplicated short speech outside calls. No closed-page/push notification claims. Polish the shared record in Remote and the laptop station, preserving Focus. VoiceCommandService is NOT wired into UI; it changes AVAudioSession and is unsafe to turn on beside WebRTC without deliberate integration. Full hands-free recognition is deferred, not delivered.

## Environment and current run instructions

- User confirmed SAME WI-FI, not hotspot. Laptop current LAN IP was `192.168.0.148`; recheck before instructing them.
- Laptop page `http://localhost:8080/?session=4` (localhost is needed for browser microphone permission).
- Room server `ws://<laptop-LAN-IP>:8080`.
- Server command from this checkout: `node RepPage/server.mjs`. Restart after server code changes; refresh page. Version label: Shared session 4.
- iPad: Rahil's iPad, CoreDevice `7C75261D-0B4C-554F-AD92-85F725CEBF81`, UDID `00008112-0005182E2E23C01E`, bundle `edu.umn.northstar.or`.
- Build product `/Users/rahilsheth/Library/Developer/Xcode/DerivedData/NorthstarOR-ahkgiyyaubmksbgxhjustnepuivs/Build/Products/Debug-iphoneos/NorthstarOR.app`.
- Generated project is ignored; NEVER commit it. `xcodegen generate` clears local team. Device builds used local `DEVELOPMENT_TEAM=P28MCS4P38`; do not put personal signing into project.yml. Reapply signing locally for Xcode GUI if needed.
- Browser automation is disabled in Work settings. Do not bypass through Chrome/CDP/AppleScript. Native Xcode/device CLI and headless Node tests are available. No audible synthetic microphone tests: a previous harness emitted a tone and upset the user.

## Checks actually run

- Red then green relay regression in `RepPage/session.test.mjs` (join, refresh, independent call pair, extra peer rejection).
- `node --test RepPage/session-page.test.mjs RepPage/session.test.mjs RepPage/server.test.mjs RepPage/call-controls.test.mjs`: 4 passed. Page harness proves no getUserMedia on session join, saved question ack/reply before media, end media retains data, stale-revision rejection, authoritative restored revision on reconnect, and no receipt after storage failure. This is mocked DOM/RTC, not physical device evidence.
- `xcodebuild test -scheme NorthstarOR -destination 'platform=iOS Simulator,id=54F54EE7-6DCB-46CA-A459-20F06CA3E258' -only-testing:NorthstarORTests/NearbySupportIntegrationTests -resultBundlePath build/shared-session-support.xcresult`: 7 passed. This preceded final small storage/connection guard changes; it covers existing retained exchange, not a live Foundation-to-Node session.
- Device builds passed during implementation; final log/result recorded below after completion.
- One focused fresh read-only reviewer found the reconnect rollback issue; regression reproduced it and now passes after fixing it. No fabricated GitHub approval.
- No full suite, UI screenshot, VoiceOver, keyboard, enlarged-text, contrast or new physical media/session check performed for this slice.

## Final state of this slice

- Final device build: **BUILD SUCCEEDED** in `build/shared-session-device-final2.log` after the storage and disconnect guards.
- Updated app successfully installed on Rahil's iPad (bundle `edu.umn.northstar.or`, installation sequence 1672). Installation preserves existing app records. Not a physical functionality check.
- Server restarted from the integrated checkout and serves `/session.js` successfully on port 8080. Server exec session at handoff: 61944; restart from this checkout if it has stopped.
- Generated project/local signing is not committed. No push or merge performed. Locate the implementation commit with `git log -1` (this handoff is included in it).

Suggested Cursor prompt: Read this handoff, the approved design and implementation plan. Work in the integrated checkout and preserve the dirty primary checkout. First verify the independent session on the real iPad/laptop, then implement durable multi-message chat, invitations and camera off/on/front-back switching. Keep focused checks and local commits; do not claim full hands-free voice or push notifications.
