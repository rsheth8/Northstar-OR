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
Files: reserved task line; CoPilotSession.swift; minimal CoPilotView.swift adapter; CoPilotSessionTests.swift; FictionalContentTests.swift.
- [ ] Write regression tests for pinned deferral, source-independent gate, explicit navigation, duplicate/stale/foreign actions, corrections and immutable history. Run scripts/check.sh; expect failures for missing authority API and old skip-advance behavior.
- [ ] Implement command validation/atomic transition and compatibility projections; capture UI commands before callbacks. Add selectable rail for explicit post-ack navigation.
- [ ] Run scripts/check-repo.sh and scripts/check.sh; expect all tests passing and no generated tracked files.
- [ ] Review full diff independently, address actionable findings, collect named iPad warning/default/enlarged-text evidence for minimal adapter.
- [ ] Rebase latest main, push ready PR, satisfy required CI, merge and publish exact API/verification handoff. Mark board complete only after merge.

## Evidence and rulings
- Base: ad9af9a. F04 merged in PR25. Primary checkout planning edits preserved.
- Ruling: keep confirmation advance for starter compatibility, while adding arbitrary explicit selection; only deferral/ack prohibit advance per F05 spec. Later F09/F10 owns full interaction design.
