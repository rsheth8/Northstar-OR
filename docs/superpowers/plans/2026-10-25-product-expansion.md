# Complete Experience and Product Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the existing room/rep workflows and extend Planner with explainable coverage, maps, simulated weather and reports, alongside deliberate voice control.

**Architecture:** Extend current AppModel, repository and SyncService contracts in serialized shared-file PRs. Planner destinations consume one selected case/scope; voice invokes the same guarded commands as touch. No second record store or feature-owned network SDK.

**Tech Stack:** Existing SwiftUI iPadOS 17+, Mac Catalyst, Foundation, Speech/AVFoundation and WebRTC. Native map/chart/export capabilities are candidates requiring compatibility spikes; no new provider or dependency is selected by this plan.

**Spec:** [Complete experience and expansion design](../specs/2026-10-25-product-expansion-design.md).

**Status:** Proposed implementation sequence for review. No app implementation is claimed. Tasks 1–5 refine existing contracts; new subsystem tasks include design/contract gates before dependent code. This portfolio plan intentionally does not pretend unresolved provider APIs or future metric schemas are settled. Produce focused subsystem plans at those gates rather than implement undefined interfaces. No schedule or staffing commitment.

## Global Constraints

- Simulated data only. No real patients, hospitals' real data, or real people.
- Native SwiftUI iPadOS 17+ and native Mac Catalyst support.
- Use Northstar design tokens, 72 pt primary targets, 44 pt other targets and adaptive layouts.
- Keep three main tabs: Co-pilot, Planner, Remote Support. Settings remains secondary.
- Features use AppModel commands and SyncService, never a view-owned network SDK or parallel store.
- No clinical decisions, invented readiness scores, ambient completion, automatic plan commitment or unproven delivery.
- One task = one branch = one small PR; split a listed task further when shared contracts and consumers need separate merges. Use copilot/, planner/, sync/ or pitch/ branches.
- Claim exact files/tests in TASKS.md before editing, preserve other writers, never commit generated .xcodeproj, and credit any new library/API/asset in the same PR.
- Every migration retains old records; a migration failure never resets data silently.

## Review Focus

- Long names/largest text/narrow windows: essential case/item/action remains readable; checked in Tasks 1–4.
- Site-local midnight/daylight-saving boundaries: list, chart and report agree on absolute dates; checked in Tasks 3, 7, 10.
- Interrupted/stale/duplicate voice: no wrong-item or duplicate mutation; checked in Tasks 8–9.
- Missing/stale/out-of-order planning inputs: no invented points, zero values or certain routes; checked in Tasks 6–7.
- Superseded plans/disconnected peers/relaunch: late acceptance cannot activate an obsolete arrangement, and saved is not received; checked in Tasks 5 and 11.

## Baseline and dependency management

Planning baseline `8982a7f`, merged #48. UX audit and executable capture checks are in [PR #49](https://github.com/rsheth8/Northstar-OR/pull/49), not yet assumed merged. Read its findings from GitHub until merged; consume current main before each task. Existing TASKS rows can be stale: compare source, merged PRs and active claims before assigning work. Reuse F06/F11/F17 etc. where behavior overlaps; do not create duplicate implementations under new names.

Before each task: confirm its dependencies are merged, reserve exact files, run relevant baseline checks, write a failing behavior regression for functional changes, implement minimally, run affected checks, review the diff, publish evidence and required CI, then hand off merged interfaces. Visual-only changes use rendering/layout evidence rather than token-literal tests. All step boxes below remain unchecked.

## Phase A: finish the existing product

### Task 1: shared shell, device-role clarity and recovery routes

**Files:** modify `DesignSystem/NorthstarWorkspaceChrome.swift`, `App/RootView.swift`; test `NorthstarORUITests/WorkspaceShellTests.swift`, `WorkspaceAppearanceTests.swift`. Coordinate feature empty-state adapters separately. Preserve `Features/CoPilot/WorkspaceCallPanel.swift` from #48.

**Interfaces:** consume `AppModel.Destination`, `selectedDestination`, `demoPost`, `loadState`, `linkState`, `saveError`, `retrySave()`. Produce adaptive shell and explicit device-role change UI; no new domain store.

- [ ] Add UI regressions for largest-text/long workspace name, permission/disconnected navigation and changing device role during an active link; verify no accidental role change from ordinary navigation.
- [ ] Reduce repeated chrome, wrap action groups, label device role distinctly and explain link termination before an explicit role switch. Keep save failure persistent with retry.
- [ ] Capture default/largest text at landscape, portrait and narrow width; inspect title/context/actions together and VoiceOver/keyboard order. Do not cap essential text to hide overflow.
- [ ] Run affected shell tests, repository checks and iPad/Mac builds; commit focused changes and submit evidence.

### Task 2: predictable workspace/contact/case forms

**Files:** workspace subtask: `Features/Workspace/WorkspaceSetupView.swift`, `WorkspaceSettingsView.swift`, `ContactsDirectoryView.swift`, `WorkspaceForms.swift`; separate Planner subtask: `Features/Planner/CaseFormView.swift`, `CaseFormDraft.swift`. Tests: existing `WorkspaceFormsTests.swift`, `CaseFormDraftTests.swift`, UI `WorkspaceShellTests.swift`, `UXAuditJourneyTests.swift` after #49 merges.

**Interfaces:** preserve throwing save closures and `WorkspaceSettingsDraft.applying(to:)`, `ContactDraft.applying(to:)`, `CaseFormDraft.validate(in:existingCases:editing:)`. Produce updated saved baselines/dirty tracking within each form, not alternate persistence.

- [ ] Add regressions for Cancel/Done/Back/swipe with changed fields, save failure retaining input, and successful save followed by close without a false discard prompt. Retain the existing nested-contact-save regression.
- [ ] Add persistent labels, field-level errors/first-error focus and explicit Save/Cancel behavior. Protect interactive dismissal and nested navigation; contacts/site changes cannot bypass dirty-state handling.
- [ ] Format time-zone labels for the selected date rather than assuming standard time; verify daylight-saving boundaries and missing travel values.
- [ ] Run form/unit/UI checks and capture keyboard-open, validation, failure and enlarged text. Commit workspace and Planner slices separately.

### Task 3: Planner worklist and independent selection

**Files:** modify `Features/Planner/PlannerView.swift`; create `Features/Planner/PlannerScope.swift` if a pure filter/day-grouping value is needed. Test `NorthstarORTests/PlannerScopeTests.swift`, `NorthstarORUITests/PlannerPresentationTests.swift`.

**Interfaces:** consume `cases`, `hospital(_:)`, `session(for:)`, `activeSession`, `recommendation(for:)`, `startOrResume(caseID:)`; produce local selected case/date/status/site scope shared by later Planner views. Define its exact value shape in this PR's handoff before Task 6.

- [ ] Test two site zones, midnight and daylight-saving dates, empty filters and retained inactive sessions; selecting another row must not mutate active recording.
- [ ] Add day grouping, recording lifecycle, visible filter summary, direct empty-state actions and unsupported-template explanation.
- [ ] Verify explicit start/resume respects pending acknowledgment while browsing/filtering remains available.
- [ ] Run matcher/scope/start-resume/UI tests; capture named-size/default/enlarged states, then commit.

### Task 4: focused Co-pilot, question-first support and retained review

**Files:** split into separate PRs for (a) `Features/CoPilot/CoPilotView.swift`, `CoPilotCorrectionSheet.swift`, (b) `CoPilotSupportPanel.swift`, `SupportRequestSheet.swift`, `SupportThreadView.swift`, (c) `Features/RemoteSupport/RemoteSupportView.swift`, `SupportBriefView.swift`. New `Features/CoPilot/SessionReviewView.swift` for unresolved-first review. Focused UI tests in existing CoPilot/Support presentation suites.

**Interfaces:** consume guarded `record(_:)`, `SessionCommand`, `supportDraftKey(question:)`, `supportSnapshot()`, `supportThread(sessionID:)`, `sendSupportQuestion`, `acknowledgeQuestion`, `sendSupportReply`, `retrySupportMessage`. Retain #48 call actions and panel. No silent acknowledgment or automatic selection advance.

- [ ] Regress required deferral pinning, correction, support while pending, same draft across sheet/panel, older-question review while a new question arrives and failed send retaining the original message identity.
- [ ] Give current item priority; replace fixed-size enlarged-text tiles; unify question entry and make general messages secondary. Put the exact question/ack/reply before the full rep recap; keep original snapshot distinct from later changes.
- [ ] Before exposing an End recording action, land a separate shared lifecycle contract/command/storage PR in `Models/SessionContracts.swift`, `Features/CoPilot/CoPilotSession.swift`, `App/AppModel.swift` and `Services/WorkspaceRepository.swift`, with focused SessionContract/CoPilotSession/WorkspaceRepository tests. Define recording/ended independently from selection, explicit end/reopen policy, retained unresolved count and a pending-acknowledgment guard; preserve existing records and call state derivation. Never infer clinical completion.
- [ ] Build case/session-specific unresolved-first review with actor/source/time and original-to-corrected state. Error/retry stays beside its action; composer/Send stays above keyboard.
- [ ] Run relevant domain and UI tests; physically verify call controls remain reachable and keyboard/VoiceOver/largest text. Commit each reserved slice separately.

## Phase B: finish real logistical plan management

### Task 5: plan revision, recipient eligibility, persistence and recipient actions

**Files:** create `Models/CoveragePlan.swift`; coordinate `Models/SupportExchange.swift`, `App/AppModel.swift`, `Services/SyncService.swift`, `Services/WorkspaceRepository.swift` in a contracts/storage PR. Consumers `Features/Planner/PlannerView.swift`, `Features/RemoteSupport/RemoteSupportView.swift` follow after merge. Tests `NorthstarORTests/CoveragePlanTests.swift`, `WorkspaceRepositoryTests.swift`, `AppModelTests.swift`, focused two-device integration tests.

**Interfaces:** proposed `CoveragePlan` belongs to workspace/case and has stable plan ID + revision, kind (named technical-rep request with explicit in-person/remote mode, or reschedule intention), requester/time, recipient snapshot, and separate response. Acceptance must reference exact plan ID/revision and requested support mode; changing mode creates a new revision. Publish validated AppModel commands and transport envelope cases in the contract PR before building consumer controls.

- [ ] Add tests for one current plan, explicit replacement, superseded late acceptance, duplicate response, in-person versus remote acceptance, a mode switch superseding a previous request, unavailable/incompatible/default contact, contact rename/removal, save failure and old-store migration.
- [ ] Implement persisted plan history and explicit request/accept/decline/reschedule-intention commands. Availability, acceptance, question acknowledgment, media connection and receipt stay separate.
- [ ] Add current arrangement, named response and unrequested backups to Planner and rep UI. Show actual peer separately from listed contact; reschedule makes no external booking claim.
- [ ] Run domain/migration/cross-device failure tests, then a physical request/response/reconnect walkthrough; hand off exact merged schema/commands before new coverage views.

## Phase C: richer Planner evidence

### Task 6: planning-data contracts, fictional editor and geographic coverage

**Files:** new `Models/PlanningEvidence.swift`, `Data/FictionalPlanningScenarios.swift`, `Features/Planner/PlanningEvidenceForm.swift`, `CoverageMapView.swift`; coordinated repository/AppModel persistence bridge; `Features/Planner/PlannerView.swift` navigation adapter. Tests new `PlanningEvidenceTests.swift`, `PlanningEvidencePersistenceTests.swift`, `CoverageMapPresentationTests.swift`.

**Interfaces:** site/contact IDs reference configured records. New evidence needs stable ID, schema version, scenario/source, recorded/valid timestamps, units, optional coordinates and optional listed travel estimate. Forecast time series/closure event remain separate. The contract must define authoritative selected evidence revision per site/scenario/valid window, migration from legacy site-keyed `StormForecast` and `DeviceRep.driveMinutes`, and how matcher and graph consume the same revision. A missing legacy as-of remains unknown; never refresh relative closure by anchoring it at now. Reuse Task 3's scope and Task 5's arrangement; do not turn home base into live location.

- [ ] First run a bounded map compatibility/offline/attribution spike on iPadOS 17+ and Catalyst. Record selected native API, supported behavior and README credit; no provider account setup is assumed.
- [ ] Publish exact validated Codable types and repository migration before consumers. Test missing/invalid coordinates, renamed sites, removed contacts, stale inputs, duplicate IDs, overlapping revisions and legacy missing-as-of closure migration.
- [ ] Provide normal editable fictional evidence fields/scenarios so new user-created sites/cases work like samples. Saved evidence is shared by map, matcher, weather and reports.
- [ ] Implement linked map/list selection; show only recorded valid coordinates, no invented routes or current rep positions. When tiles fail, list/context remains usable. Preserve actual active recording.
- [ ] Run contract/migration/UI checks with independently created records, offline tiles and largest text; commit contract, editor and map consumers as separate PRs.

### Task 7: weather graphs and travel/case timeline

**Files:** new `Features/Planner/WeatherTimeline.swift`, `WeatherView.swift`, `CoverageTimelineView.swift`; Task 6 evidence contracts; coordinated `Features/Planner/CoverageMatcher.swift` adapter. Tests `WeatherTimelineTests.swift`, `CoverageMatcherTests.swift`, `WeatherPresentationTests.swift`.

**Interfaces:** consume persisted Task 6 series and existing absolute `Procedure.scheduledAt`, duration, site zone and explicit closure. Proposed pure timeline projection accepts `now: Date`, case, evidence and optional planned departure; outputs valid/gap/stale markers and explicit intervals without choosing a plan. Set its exact signature after evidence types merge.

- [ ] Verify native chart availability/interaction on both platforms. Assert graph and matcher use the same selected evidence revision and legacy unknown closure stays unknown across repeated evaluations. Test out-of-order/duplicate hourly samples, gaps, stale issue time, units, missing departure, daylight saving and boundary equality.
- [ ] Plot recorded quantities with labeled axes/units and accessible table alternative. Display issue/valid times, scenario and source. Missing is not zero; never fabricate hourly values from the old summary.
- [ ] Show explicit travel/setup/case/closure intervals. No precipitation threshold invents closure; unknown forecast is visible even if listed travel otherwise fits.
- [ ] Regress matcher explanations with incomplete evidence; save/relaunch/edit inputs through normal forms. Run focused checks, capture failure/enlarged states and commit.

## Phase D: bounded voice

### Task 8: command vocabulary and guarded routing

**Files:** modify `Services/VoiceCommandService.swift`; create `Features/CoPilot/VoiceCommandRouter.swift`; minimal coordinated AppModel adapter only if existing command API is insufficient. Tests new `VoiceCommandTests.swift`, `VoiceCommandRouterTests.swift` and existing `CoPilotSessionTests.swift`.

**Interfaces:** replace the broad `complete/skip/confirm` parser with explicit navigation/read-only/mutation intents from the spec. Proposed router consumes a final recognition ID, parsed intent and a captured `SessionCommand` target/version, returning a pending preview or rejection. Commit consumes that same preview once. Publish actual enum/signatures before Task 9.

- [ ] Write tests: “do not record confirmation,” unrelated speech, partial results, repeated final IDs, stale item/version/session, pending acknowledgment, correction and permission interruption; assert zero unintended events and at most one explicit committed event.
- [ ] Implement exact normalized vocabulary and reject ambiguity. Read-only/navigation actions do not mutate recording. Mutation preview identifies case/item/action; explicit commit revalidates current state with `.voice` source.
- [ ] Stop/background/context change invalidates pending commands. No send/plan replacement/device-role change/delete/end-call command in release one.
- [ ] Run parser/router/session tests, review all entry paths and commit before microphone UI integration.

### Task 9: listening UI, microphone arbitration and real-device proof

**Files:** `Services/VoiceCommandService.swift`, `Features/CoPilot/VoiceControlsView.swift` (new), `CoPilotView.swift`; coordinated `Services/NearbyCallSession.swift` audio boundary only as a separate reserved bridge. Tests `VoiceCommandRouterTests.swift`, new `VoicePresentationTests.swift`.

**Interfaces:** consume Task 8 intents/previews/commit and existing call state. Produce Off / Listening / Processing / Unavailable UI and explicit stop; disabled during media calls until coexistence is proven separately. Dictation never uses the command parser.

- [ ] Spike permission/capability/audio interruption and call takeover on real iPad and Catalyst. Include existing `Services/VoiceAnnouncer.swift` and optional rep spoken alerts: prevent synthesized speech/echo from becoming commands, suspend/invalidate recognition around app speech or suppress optional speech while listening, and retain visible warnings. Check on-device recognition support before describing offline capability; denied/unavailable recognizer must leave touch controls working.
- [ ] Add explicit short listening sessions and Heard/action/target preview with confirmation. Permission loss, backgrounding and call start stop recognition and discard pending mutation.
- [ ] Test cancel, repeated recognition, stale preview, active call, permission denial and interrupted input; verify touch/pinned gate unchanged.
- [ ] Run focused tests and document real-device quiet/noisy fictional phrases, false activations, latency and missed commands. Passing parser tests alone cannot release voice. Commit with actual limitations.

## Phase E: useful reports

### Task 10: deterministic case report, reviewed export and operational metrics

**Files:** new `Features/Planner/Reports/CaseReport.swift`, `CaseReportView.swift`, later `CaseReportExporter.swift`; Planner navigation adapter. Later separate `OperationalReport.swift` and any event-contract addition. Tests `CaseReportTests.swift`, `CaseReportExportTests.swift`, later `OperationalReportTests.swift`.

**Interfaces:** proposed pure case report snapshots case/session ID, template, unresolved/confirmed/corrected items, Task 5 plan, Task 6 evidence and support events at a captured time. Reports never mutate their sources. Export consumes the reviewed snapshot, never a changing live store.

- [ ] Test no-session/no-plan/no-weather, unresolved corrections, wrong-case isolation, contact renaming, site-local dates and data changing after snapshot. Assert report preserves known values and explicitly labels missing information.
- [ ] Build on-screen case brief first, with sources/times and separate plan acceptance/connection/question acknowledgment. Include no clinical readiness or generated advice.
- [ ] In a separate export slice, render the frozen brief with case/page/date/zone/simulated labels; visually inspect long multi-page text and accessibility. Explicit share/export only, cancellation/failure retains source record; no external transmission is automatic.
- [ ] Before aggregate metrics, publish event definitions for first receipt/ack/reply, denominator, period, local-only exclusion, retries and missing data. Add a fixture where duplicates/local-only messages cannot inflate responses; negative/out-of-order durations are flagged/excluded, never absolute-valued.
- [ ] Run report/export/metric checks and verify output against recorded history; ship deterministic brief before metrics if event semantics are incomplete.

## Phase F: release proof and later projects

### Task 11: integrated release verification

**Files:** focused `NorthstarORTests/NativeSessionIntegrationTests.swift`, existing UI suites plus new subsystem suites; evidence under a new named `docs/evidence/product-expansion/` reservation; release notes in `docs/NATIVE_DEMO_STATUS.md` only when updated behaviors are verified.

- [ ] Create fictional workspace, two sites/time zones, two contacts and two cases without seed IDs. Use plan replacement/late old response, map/weather edits, explicit recording and voice mutation, question/ack/reply, media ending/reconnect and report snapshot.
- [ ] Relaunch mid-draft/pending acknowledgment; verify correct records, pending message identity and no resurrected connection. Inject save failure and transport failure independently; neither becomes a false success label.
- [ ] Verify default/largest text, narrow/portrait, VoiceOver, keyboard, Reduce Motion, chart/list parity and physical call/voice interruption. Have an OR-member/coordinator and technical rep review a fictional walkthrough; record hesitation and wrong interpretations.
- [ ] Run `bash scripts/check-repo.sh`, `bash scripts/check.sh` with a named installed iPad simulator, affected Catalyst builds and required CI. Record exact candidate, evidence and remaining exclusions; mark tasks complete only after merge.

### Task 12: future projects, deliberately unclaimed

- [ ] Grounded AI handoff drafts: separate source-grounding/review/failure design; no autonomous record mutations or sending.
- [ ] Mock-label camera observation: reviewed fictional labels, captured observation separated from human confirmation; unreadable/absent/mismatch datasets and no auto-completion.
- [ ] Additional procedure templates: reviewed fictional content, explicit applicability, pinned versions and retained old records; never reuse pacemaker content for unsupported ICD.
- [ ] Coverage conflicts/what-if: first define accepted availability intervals, travel/setup and alternative-scenario identity; no inferred free time from today's Boolean.
- [ ] Distant internet support/verified identity/background notifications: separate deployment/security/data-policy project; current nearby demonstrations do not prove it.

## Implementation handoff

Recommended first implementation: Task 1, shared shell/accessibility, followed by the form and Co-pilot/rep slices. Planner plan contracts and evidence must settle before map/weather consumers. Voice parser work can be a separately reserved slice; shared audio/AppModel changes remain serialized.

No implementation starts from this planning turn. Review the proposed design and this roadmap first; approve or adjust the defaults, then create the focused Task 1 execution plan from current main. Do not claim all twelve portfolio tasks as active or launch one writer per page.
