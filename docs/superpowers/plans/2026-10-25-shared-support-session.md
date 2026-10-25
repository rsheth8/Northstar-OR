# Shared support session implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Join the room's case without a call, follow recorded progress, exchange retained support requests, then optionally call.
**Architecture:** A separate `/session` WebSocket relays snapshots and existing support envelopes through SyncService. Existing WebRTC media remains independent. The room stays the recording authority.
**Tech Stack:** SwiftUI, Foundation WebSockets, existing WebRTC, dependency-free Node/browser JavaScript.
**Spec:** `docs/superpowers/specs/2026-10-25-shared-support-session-design.md`

## Global constraints
Fictional data only; no clinical decisions. Preserve Focus, saved question snapshots and explicit receipts. Same-Wi-Fi scope. No new dependencies. No generated project commits. Native execution requested to conserve usage; leave unfinished slices explicitly for Cursor.

## Review focus
Late join without a question; reconnect after room changes; stale case responses; media end preserving data; failed persistence must not produce receipt.

### Task 1: Independent live case feed and retained support exchange
- [x] Add focused relay regression in `RepPage/session.test.mjs`: session peers pair independently of call peers, request a fresh snapshot on join/rejoin, relay support envelope, reject extra peers. Watch it fail.
- [x] Extend `RepPage/server.mjs` with isolated `/session` pairing and bounded relay (no server case database).
- [x] Add `Services/SharedSessionTransport.swift`: `NearbyTransport`, URLSession WebSocket, `publish(SharedSessionSnapshot)`, refresh callback. Snapshot has origin, context, recording summary, saved flag and scoped questions.
- [x] Integrate `AppModel.startSharedSession(server:)` and `publishSharedSession()` through existing SyncService transport. Publish after recording and support changes and on peer join. Stop sharing on case switch/role/background; keep media end independent.
- [x] Add share controls to `NearbyCallView.swift`; show same status in Remote. Add `/session.js` to laptop for explicit join, live recap/full event list, current context and saved question receipt/ack/reply through session channel. Existing call remains usable.
- [x] Run Node relay/control regressions and affected native build; review diff; commit bounded result.

### Task 2: Durable multi-message thread (Cursor if remaining)
- [ ] Add session-scoped message records/drafts/receipts with backward-compatible WorkspaceSnapshot decoding and validation, without replacing contextual questions. Both sides retain before receipt, retry with stable IDs. Project the same thread in CoPilotSupportPanel, RemoteSupportView and laptop.
- [ ] Focused test: disconnect/reconnect doesn't duplicate messages, old-case reply stays on old case, persistence failure produces no receipt. Build and commit.

### Task 3: Invitations and camera controls (Cursor if remaining)
- [ ] Add request/accept/decline/cancel/expiry over session connection, unique call ID scoped to origin; resolve simultaneous requests. Only accepted calls request permissions/start media; end media preserves session.
- [ ] Add camera off/on and front/back switch to NearbyCallController/engine and call sheet, reflect actual capture completion and remote camera state, preserve mute. Handle missing device/permissions/simulator.
- [ ] Focused lifecycle/control checks and real-device Wi-Fi test; no audible synthetic tests.

### Task 4: Device evidence and handoff
- [ ] Document exact branch/worktree/commits, finished vs missing behavior and commands actually run in `docs/CURSOR_SHARED_SESSION_HANDOFF.md`. Physically verify late join, message receipts, continued messaging after media ends, camera and both microphone directions. Do not claim device checks not performed.

## Execution ledger
- Design approved by owner; subsequent instruction prioritizes usage conservation and an actionable Cursor handoff.
- Ruling: task 1 ships existing contextual request/ack/reply before generic chat or invitation redesign, to provide a useful bounded slice without destabilizing the working call.

- Task 1 completed locally: 4 focused Node checks pass, 7 existing support tests pass, final real-device build passes. Reconnect rollback finding fixed with a red/green regression. New shared-session physical walkthrough remains pending. Tasks 2/3/physical evidence handed to Cursor per usage constraint.
