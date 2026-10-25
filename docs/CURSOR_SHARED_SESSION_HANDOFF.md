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

## Cursor continuation

Implemented in this worktree after `02d4b1c`. Page label is Shared session 5. Refresh the laptop page after restarting the server.

- Session notes are a separate retained record from contextual questions. Stable IDs, drafts, receipts, and the same thread in Co-pilot, Remote Support, and the laptop. A failed save does not transmit. Replaying a note does not duplicate it. A note stays on its own case.
- Either side can request a call. Accept, decline, cancel, and a 30-second expiry are on the session channel. Media starts only after acceptance. Ending a call leaves the session up. Leave ends both. An ended recording cannot start a call. If both request at once, the lower invitation ID remains.
- Room camera off/on and front/back use the existing capturer. Mute is left alone. The laptop shows camera off when the room turns it off. Simulator and missing-camera states stay audio-only.
- The joined laptop has Enable alerts, a persistent deferral/question banner, and one spoken line outside a call. A closed page is not notified. Voice commands stay unwired.

## Still required

Physical walkthrough on Rahil's iPad and the laptop, on the same Wi-Fi. This has not been done for the foundation slice or for messages, invitations, camera, or alerts. Do not claim those device checks.

1. Restart `node RepPage/server.mjs` from this checkout. Refresh `http://localhost:8080/?session=5`.
2. iPad: Call rep, Share current case. Laptop: Join session. Confirm progress appears with no microphone prompt.
3. Send a message each way. Confirm one copy after refresh. Defer a line and confirm the laptop banner. Acknowledge and reply. End a call and send another message.
4. Request a call from one side and accept on the other. Confirm audio both ways, mute, camera off/on, and flip. Decline and cancel once. Leave the session and confirm the call ends.

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

## Superseding native demo continuation

The owner now requires Northstar itself on BOTH devices. See `docs/NATIVE_DEMO_STATUS.md`; it supersedes browser setup as the demo path. Native Mac Catalyst support is enabled in project.yml. Multipeer v2 carries full snapshots, support envelopes, invitations and scoped WebRTC signaling; no Node/browser is needed. The native engine supports room/rep roles, incoming video and camera lifecycle guards. Rep projection is persisted with backward-compatible decoding, pending messages survive snapshots/reconnects, and accepted calls do not replace the data connection.

A physical walkthrough exposed an additional core gap: sample setup had no active recording and Planner lacked start/resume/form entry controls. These are now connected, and starting a case publishes the first recap. Normal-launch UI regression passes. Case selection is scoped to the connected room. Save retry finalizes withheld rep snapshots/receipts. Camera-off hides the frozen remote frame.

Current native launch products are in the usual DerivedData `Build/Products/Debug-maccatalyst/NorthstarOR.app` and `Debug-iphoneos/NorthstarOR.app`; signed builds passed. The owner is actively checking devices. Record their actual results; do not claim native media works solely from compilation or earlier browser-call confirmation. Feature audit explicitly excludes unwired voice, AI/vision, named-rep Planner acceptance, internet/push/background calls and export. Continue in this integrated checkout, preserve the primary dirty checkout, and do not push/merge without authorization.
