# F05 Guarded Recording Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans. Existing owner-approved F05 specification authorizes execution.

**Goal:** Pin required deferrals, reject duplicate/stale/wrong-target actions, and preserve explicit correction history.
**Architecture:** CoPilotSession consumes merged F04 values as its recording authority. Existing UI/status/log consumers retain adapters; touch buttons capture target/version when rendered. No alternate shared models or storage.
**Tech Stack:** Swift, Observation, SwiftUI, XCTest; iPadOS 17+; no dependencies.
**Spec:** docs/IMPLEMENTATION_PLAN.md sections 4/7 F05, docs/PRODUCT.md, docs/DESIGN.md.

## Global Constraints
- Fictional data only; recording is no clinical decision or validation.
- One task/branch/small PR; no Models/AppModel/SyncService/DesignSystem changes or generated project.
- Pending warning blocks confirmation/defer/selection across all input sources; support/review stay available.
- Acknowledgment clears only its matching gate, leaving selection and deferred state.

## Design decisions and interfaces
- `apply(_ command: SessionCommand) throws -> SessionEvent`: atomic validation, accepted intents deduplicated by full command; conflicting reuse rejected. Global expected version protects all recording paths. Event ID derives from intent ID; warning ID derives from accepted event identity. No clock-based deduplication.
- `makeCommand(_:targetItemID:actor:source:at:intentID:) -> SessionCommand?`: capture current version/target, default actor only for legacy local preview. F07 supplies configured participant and stable session identity.
- `recordingState: SessionRecordingState?`, `events: [SessionEvent]` expose snapshots for consumers. Unsupported content has no recording state and rejects commands.
- Keep normal confirmation's existing sequential convenience; explicit selection can visit any item outside the gate. Deferral never advances. Acknowledgment never advances. Re-recording existing status requires correction. Rail buttons permit explicit navigation after acknowledgment.
- Correction must reference the latest status-changing event for that target, never selection/ack, another item or superseded history. Correcting pinned deferral supersedes its warning explicitly; correction to required deferred opens a fresh warning.
- Persistence restoration is F18/F07; no unchecked snapshot restore API in F05.

## Review Focus
- Same intent after intervening actions returns original event without effects; reused identity with changed payload rejects.
- Foreign workspace/case/run, stale versions and unselected targets leave all state/history unchanged.
- Correcting required deferred state cannot silently clear a warning; stale acknowledgment cannot clear a replacement.
- Support/context/reply reads do not move selection or change recording version.
- Unsupported or tampered template cannot record; status adapters preserve deferred state even when selected.

### Task 1: Guard recording and integrate existing touch calls
Files: reserved task line; CoPilotSession.swift; minimal CoPilotView.swift adapter; CoPilotSessionTests.swift; FictionalContentTests.swift; one WorkspaceContractTests.swift legacy-call adapter.
- [x] Write regression tests for pinned deferral, source-independent gate, explicit navigation, duplicate/stale/foreign actions, corrections and immutable history. Run scripts/check.sh; expect failures for missing authority API and old skip-advance behavior.
- [x] Implement command validation/atomic transition and compatibility projections; capture UI commands before callbacks. Add selectable rail for explicit post-ack navigation.
- [x] Run scripts/check-repo.sh and scripts/check.sh; expect all tests passing and no generated tracked files.
- [x] Review full diff independently, address actionable findings, collect named iPad warning/default/enlarged-text evidence for minimal adapter.
- [ ] Rebase latest main, push ready PR, satisfy required CI, merge and publish exact API/verification handoff. Mark board complete only after merge.

## Evidence and rulings
- Base: ad9af9a. F04 merged in PR25. Primary checkout planning edits preserved.
- Ruling: keep confirmation advance for starter compatibility, while adding arbitrary explicit selection; only deferral/ack prohibit advance per F05 spec. Later F09/F10 owns full interaction design.

- Baseline: 45 tests passed, build/check.AQzTti/Tests.xcresult.
- Red: build/f05-red.log, exit 65: missing command authority API (apply/makeCommand/recordingState).
- First green: 55 tests, zero failures; build/f05-green.log. Production mutators without captured targets removed.
- Pre-flight: shared F04 state/command/event fields match; no Models changes.

- Rebased onto 9909f22 (F01 components and rep-join-brief docs merged). Final full simulator run after that rebase/fix: 56 tests, zero failures; build/f05-review-green.log, build/check.t53mjs/Tests.xcresult.
- Independent whole-branch review found activation timestamps were captured at render. Added delayed-activation regression (red missing helper → green suite), `RecordingCommandActivation` stamps once at first action and retains exact retries. Reviewer confirmed resolution; no other actionable findings.
- Simulator touch/AX evidence: docs/evidence/f05/README.md. Existing enlarged-text layout crowding explicitly deferred to F09; no accessibility/transport/device claims beyond recorded checks.

## Consumer handoff
- `CoPilotSession(procedure:reducedSupport:now:sessionID:)` accepts a retained/new run ID; procedure supplies workspace/case IDs. Legacy absent workspace uses local-unconfigured, not a configured workspace claim. F07 must supply configured values and actor.
- `makeCommand(_:targetItemID:actor:source:at:intentID:)` captures exact context/version. Delayed touch callbacks use `RecordingCommandActivation.command(at:)` to stamp first activation once, then call `apply(_:)`. Removed untargeted complete/skip/ack methods.
- `apply(_:) throws -> SessionEvent` returns the existing event for an identical accepted command; conflicting ID reuse throws intentConflict, stale expectedVersion throws staleVersion. Rejections leave state/history/log unchanged. SessionContractError validates structure; RecordingCommandError reports contextual guards.
- `recordingState` uses merged F04 schema1; `events` are append-only accepted structured records with actor/source/time. Text log is a compatibility projection, not the authoritative correction history. No unchecked restoration API: F18/F07 must retain state plus history/accepted intents and validate their consistency before a separate restore adapter.
- Required deferral pins; acknowledgment clears only matching gate. Use selectItem after acknowledgment; recorded statuses change only through explicit correction referencing the latest status-changing event for that item. Correction to required deferred creates/pins a fresh warning, including when initiated from history.
- `status(of:)`/`statuses` remain legacy view projections; use recordingState for independent selection/status. Support message/mode compatibility methods never mutate recording state/version. No support-domain contracts or persistence added.
