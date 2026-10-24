# F04 session and event contracts implementation plan

> **For agentic workers:** Use superpowers:executing-plans for this bounded slice. The approved product plan and Rahil's instruction to continue F04 supply scope and execution authorization.

**Goal:** Publish versioned, Codable session state, command and event contracts for F05/F06/F18 without changing the starter recording behavior.

**Architecture:** Add value types beside the merged F24 workspace types. Session identity is a workspace/case/run tuple. Selection is separate from recorded status. Commands name the original target and expected session version; accepted events carry sequence, actor, source and optional intent identity. Required acknowledgment names its triggering deferral and item. The existing feature types remain the compatibility boundary until F05/F07; no lossy conversion from legacy `StepStatus.current`.

**Tech stack:** Swift, Foundation, XCTest; iPadOS 17+; no dependencies.

**Spec:** `docs/IMPLEMENTATION_PLAN.md` sections 4.1, 4.2, 4.5 and F04 acceptance; `docs/PARTNER_EXECUTION.md` shared ownership.

## Global constraints

- Fictional coordination records only; no clinical readiness or authentication claims.
- Reserve only `Models/SessionContracts.swift`, `NorthstarORTests/SessionContractTests.swift`, this plan, and the F04 board line.
- Preserve existing consumers; F05 owns mutation rules and F07 owns SyncService migration.
- Schema version 1; missing/future schemas and malformed structural data fail decoding. Directly constructed values must pass `validate()` before use.
- Caller supplies stable IDs and absolute times; sequence, not wall-clock order, represents accepted ordering.

## Review focus

- Two runs of the same case and two workspaces must have unequal identities.
- Acknowledgment must name the deferred item/event, never imply team confirmation.
- Stale command target/version must survive serialization unchanged for F05 to reject.
- Correction history must reference the original event without rewriting it.
- Empty IDs, foreign actors, invalid versions/times and inconsistent pending gates must fail validation/decoding.

## Task 1: Shared value contracts and behavioral serialization tests

**Files:** Create the two reserved Swift files above.

**Interfaces:** Consume `LocalParticipant`, `ParticipantRole`, `CoordinationTemplateReference`. Produce `SessionIdentity`, `RecordingInputSource`, `RecordedItemStatus`, `RequiredAcknowledgment`, `SessionRecordingState`, `SessionCommandAction`, `SessionCommand`, `SessionEventPayload`, `SessionEvent`, `SessionContractError`. All values are Codable/Hashable; all identity/metadata properties are immutable. `validate()` checks structure, not domain authorization or replay acceptance.

- [ ] Write focused XCTest cases for run isolation, source labels, selection/status independence, targeted command and event round trips, correction/acknowledgment links, schema rejection and malformed state.
- [ ] Run the tests before implementation; confirm missing contract types fail compilation.
- [ ] Implement the contracts with command kinds for select/confirm/defer/ack/correct and event payloads for selection/confirmation/deferral/ack/correction. Require version >= 0 on commands/state and positive accepted version on events. Require explicit intent IDs for user recording events. Preserve actor snapshot and absolute time. Pending gate state requires the same selected item with deferred status.
- [ ] Run repository checks and the full iPad test suite; inspect actual output.
- [ ] Review the diff and obtain a read-only independent review if available. Address correctness findings, then satisfy required CI and merge through normal protected-branch flow.

## Execution record

- Existing attached worktree is clean and isolated; base `14f4df6`.
- F04 has no competing claim. Amartya's draft #21 remains confined to design-system work.
- The previously assigned builder/reviewer both report account usage limits. The integration driver will implement here; independent review will be attempted through the available review tools. No fabricated review/approval.
