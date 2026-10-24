# Task board

Claim a task by changing `[ ]` to `[~] (your name)`. Mark `[x]` when it's merged.
One task per branch and PR. Lanes keep people and agents out of each other's files.

## Agreed product direction

Read [PRODUCT.md](PRODUCT.md) and [DESIGN.md](DESIGN.md) before choosing implementation work. Northstar helps teams coordinate support, track reported progress, and hand off context. It prompts and documents; it does not assess clinical correctness.

Priority: a configurable fictional workspace, normal case creation, retained records and a reliable support journey using one reviewed coordination template before additional procedure types, maps or automation. The prepared story exercises the normal app. The items below are implementation work, not claims that these capabilities already exist.

Use [the detailed implementation blueprint](IMPLEMENTATION_PLAN.md) for F01–F28 slices/dependencies and [PRODUCT_FOUNDATION.md](PRODUCT_FOUNDATION.md) for setup, persistence and independent-case acceptance. [DESIGN_REFERENCES.md](DESIGN_REFERENCES.md) records institutional UI research. Claim work here; blueprint IDs are planned slices, not additional active claims or GitHub issues.

Use [the presentation delivery plan](DEMO_READINESS.md) for the owner-confirmed **five-minute** script, product proof and fallback. First claim **F03** reusable content, then **F24/F04/F06**, guards/storage **F05/F18**, and **F07** orchestration. Shared visuals can progress separately. No implementation slice is claimed by the planning update.

## Rahil and Amartya: working allocation

Follow [the partner execution plan](PARTNER_EXECUTION.md) for the full F01–F28 owner map, file reservations, build waves and deadline gates. [Agent briefs](AGENT_BRIEFS.md) provide bounded kickoff/review prompts. These are planned owners, not active task claims:

- **Rahil:** reusable content/shared contracts, guarded Co-pilot, AppModel/Sync integration, session review, the F26 directory after setup lands, and release/presentation/submission coordination.
- **Amartya:** accessible shared UI/shell, F18 persistence, setup/settings, matcher/case forms/Planner, rep support exchange, worklist/start-resume, device operation and evidence/backup.
- **Start:** Rahil claims F03; once visible, Amartya claims F01. Default two isolated writing agents plus an optional read-only reviewer. Only use a third writer for an explicitly disjoint reserved slice. Shared Models/AppModel/Sync changes remain serialized under Rahil; F18 repository files belong to Amartya.

Publish actual claims here and in early draft PRs. Rahil coordinates board updates and merge order; do not mark an implementation complete because it has an owner or a plan.

## UX delivery order

The approved logo and neutral shared styling are merged. This is the next implementation sequence, not a claim that the screen redesign is complete. Claim the corresponding task below. Keep shared files in their own small PRs; a grouped stage can require several PRs.

Start the fixture/contracts lane first. The visual foundation and viewport check can progress in another checkout after that work is claimed. Feature screens depend on the relevant merged state interfaces; they must label pending/unavailable capabilities honestly while integration is unfinished. Draft the script/deck from F03; final screenshots, recording and claims wait for verified integration.

| Order | Slice and ownership | Done when |
| --- | --- | --- |
| 1 | Reusable content, shared contracts and retained state: F03/F24/F04/F06/F05/F18/F07, separate PRs | Optional seeds and one supported template; workspace/case/session IDs; P0 local store; guarded selection/recording and one current plan; separate acceptance/connection/question state; no hard-coded sample IDs. |
| 2 | Shared accessibility/components: F01, `DesignSystem/` | Text scales with Dynamic Type; supporting labels meet the 13 pt baseline; essential indicators meet contrast targets; shared controls retain large hit areas, visible focus, and reduced-motion behavior. Can run in another checkout after the first fixture/state claim. |
| 3 | App shell and viewport: F02, `App/RootView.swift`, plus `project.yml` only for necessary settings | A real landscape iPad/window check explains and resolves unexpected letterboxing/overflow; navigation and active-case context remain stable; narrower windows and enlarged text retain essential actions. Coordinate shared context with stage 1. |
| 4 | Co-pilot touch journey: Lane A, F09/F10/F13 | Progress/current work/activity hierarchy adapts; required deferral pins that item; support/review/correction remain available; acknowledgment leaves the item deferred; touch recording/correction and incoming reply work. Depends on merged state/visual interfaces and coordinated support request work. |
| 5 | Setup and Planner: F25–F28, Lane B F08/F11 | Functional workspace/directory settings, new/edit case, useful worklist, explicit start/resume, one current plan/backups and safe replacement. Multiple supported cases retain isolated records. No preparation checklist. |
| 6 | Remote support exchange: Lane B | The request carries question/context/unresolved items; the recipient acknowledges and replies; Co-pilot visibly receives the reply. Pending, unavailable, and failure states are reviewable. |
| 7 | Voice and cross-device delivery: Lanes A/C, separate tasks | Explicit commands have a visible state and touch fallback; duplicate results do not duplicate records; transport/receipt states reflect evidence, including a disconnected rehearsal. Local demo labels remain until transport works. |
| 8 | Review and demo verification: review task plus Lane D | Review keeps unresolved items and sources visible. Rehearse one coherent journey on the intended devices, including enlarged text, VoiceOver/keyboard access, failed support, and reduced motion. Record actual results and workflow feedback. |

Camera, AI, maps, and additional procedure types follow the working core journey. Use [the screen contracts](DESIGN.md#4-screen-contracts) and [review evidence](DESIGN.md#9-review-evidence-for-a-ui-pr) to judge each slice. Visual polish never substitutes for the state/behavior prerequisites.

## Next implementation tasks (one task per branch/PR)

- [x] (Amartya / Codex; merged PR #33) **Light-workspace design foundation:** reconcile the owner-approved light workspace / midnight header direction and add opt-in semantic palette tokens. Reserves `AGENTS.md`, `CLAUDE.md`, `docs/DESIGN.md`, `docs/LIGHT_WORKSPACE_HANDOFF.md`, `NorthstarOR/DesignSystem/NorthstarWorkspacePalette.swift`, `docs/evidence/light-workspace/`, and this claim only. Existing screen migration remains F02/F09/F11/F12 after merged dependencies; no feature, model, storage, or shell edits.

Claim the individual F-number row for each implementation slice. The lane checklists below are acceptance reminders, not additional parallel claims for the same work. Optional slices stay pending until their core gate passes.

- [x] (Codex) **Shared design:** establish restrained clinical typography, flat controls, and quiet surfaces in `DesignSystem/`; preserve action sizes and semantic status colors (merged in [PR #8](https://github.com/rsheth8/Northstar-OR/pull/8)).
- [x] (Rahil / Codex core builder) **F03 — first implementation claim: reusable fictional template/seed and copy.** One versioned pacemaker coordination template, optional sample factory, injected clock/IDs, non-directive recording copy and honest completion labels. Empty workspace and arbitrary compatible case IDs are valid; unsupported ICD content cannot launch (`Data/` and coordinated copy; small PR). Merged in [PR #22](https://github.com/rsheth8/Northstar-OR/pull/22); reserves `NorthstarOR/Data/`, `NorthstarORTests/FictionalContentTests.swift`, and this F03 claim. Reserved adapters: `Features/CoPilot/CoPilotSession.swift` (content guard and recording copy), `CoPilotView.swift` (recording/completion/unsupported labels), `Features/RemoteSupport/ContextPackage.swift` (recorded-state summary), and `RemoteSupportView.swift` (technical-support reply content reference), as published in draft PR #22 before edits. Models/AppModel/SyncService/DesignSystem remain outside this slice. F24 owns canonical template references; F05 owns pending-acknowledgment guards; F07/F25 own blank startup and explicit sample loading.
- [x] (Rahil / Codex core builder) **F24 — workspace/case contracts:** stable workspace/site/contact/template/case IDs, valid case inputs and pinned supported template version (`Models/`; shared-files PR). Merged in [PR #23](https://github.com/rsheth8/Northstar-OR/pull/23); reserves `Models/WorkspaceContracts.swift`, additive adapters in `Models/Models.swift`, `Data/FictionalCoordinationTemplate.swift` for canonical template pinning, `Data/SampleData.swift` solely for known forecast/travel baselines and stated technical-rep roles, and `NorthstarORTests/WorkspaceContractTests.swift`. No AppModel/SyncService/DesignSystem/shell/feature edits.
- [x] (Rahil / Codex) **F04 — shared session/event contracts:** session and actor/source IDs, separate selection/recorded item status, target-specific command and acknowledgment identities (`Models/`; shared-files PR). Merged in [PR #25](https://github.com/rsheth8/Northstar-OR/pull/25); reserves `NorthstarOR/Models/SessionContracts.swift`, `NorthstarORTests/SessionContractTests.swift`, the F04 plan/handoff, and this task line. Existing feature state and SyncService remain unchanged until F05/F07.
- [x] (Rahil / Codex) **F05 — Co-pilot domain:** unrecorded/deferred/team-confirmed items, correction history, duplicate/stale action guards. Required deferral pins that item; pending acknowledgment blocks confirmation/defer/item switching but permits support, read-only review and pinned-item correction (`Features/CoPilot/`; shared types land separately). Merged in [PR #29](https://github.com/rsheth8/Northstar-OR/pull/29). Reserved files: `CoPilotSession.swift`, minimal captured-command/navigation adapter in `CoPilotView.swift`, `NorthstarORTests/CoPilotSessionTests.swift`, compatibility updates in `FictionalContentTests.swift` and `WorkspaceContractTests.swift`, the F05 plan/handoff and this task line. Uses merged F04; Models/AppModel/SyncService/DesignSystem remain outside this slice.
- [ ] **F06 — shared plan/support contracts:** one current coordinator plan/revision (rep request or reschedule), visible unrequested backups, superseded plans, named role/recipient, independent acceptance/connection/question/receipt state (`Models/`; shared-files PR).
- [ ] **F18 — P0 repository/persistence:** versioned local configuration/contacts/cases/sessions/drafts, atomic writes with visible failures, schema/corruption handling, relaunch and pending-send reconciliation (`Services/` and coordinated shared state; small PR).
- [ ] **F07 — local support orchestration:** request/accept/ack/reply, main-actor routing, case/session isolation, safe plan replacement and late old-acceptance handling, failure injection (`App/AppModel.swift`, `Services/SyncService.swift`; shared-files PR).
- [x] (Amartya) **F01 — shared UX foundation:** implement scalable typography, the 13 pt supporting-label baseline, high-contrast status indicators, and accessible primary/secondary/focus states (`DesignSystem/`; shared-files PR). Active on `pitch/accessible-components` (F03 claim visible); reserves `NorthstarOR/DesignSystem/` and its previews only. Merged in [PR #21](https://github.com/rsheth8/Northstar-OR/pull/21); simulator text-size/banner evidence is in `docs/evidence/f01/`, with unrun interaction checks listed.
- [~] (Amartya / Codex) **F02 — app shell and viewport:** verify the intended landscape iPad presentation; diagnose unexpected letterboxing and rigid sizing, and adapt navigation/context to window width and enlarged text (`App/RootView.swift`; shared-files PR; `project.yml` only if settings need correction).
- [ ] **F25 — setup/settings:** blank workspace flow, editable fictional site/time zone/local role, explicit optional sample loading and saved configuration (`Features/Workspace/`; shell entry coordinated separately).
- [ ] **F26 — support directory:** add/edit fictional contacts, roles, device-family capabilities, availability and simulated travel estimates; these contacts drive normal support selection (`Features/Workspace/`; shared contracts/storage first).
- [ ] **F27 — case forms:** create/edit cases through validated normal UI using a supported template; no patient fields or sample-ID dependency (`Features/Planner/`; contracts/storage first).
- [ ] **F28 — worklist/start/resume:** useful case filters, explicit active-context switch and retained independent records/drafts; pending acknowledgment cannot be bypassed (`Features/Planner/`; shared session orchestration in its own PR).
- [~] (Amartya / Claude) **F08 — explainable matcher:** availability, qualification, missing travel/forecast, schedule/closure boundaries, stable ranking and explicit Reschedule candidate; reasons describe actual logistical constraints (`Features/Planner/CoverageMatcher.swift`; pure behavior tests).
- [ ] **F09 — adaptive Co-pilot workspace:** progress/current work/activity hierarchy, persistent unresolved context and reachable actions at wide/narrow windows and enlarged text (`Features/CoPilot/`; merged state/UI interfaces first).
- [ ] **F10 — recording and corrections UI:** explicit confirmation/defer/acknowledgment/correction interactions; pinned-item warning cannot be bypassed and history remains reviewable (`Features/CoPilot/`; after F09).
- [ ] **F11 — Planner support plans:** configured case/contact detail, one named-rep or reschedule plan, visible unrequested backups, actual acceptance and safe plan replacement; no preparation checklist (`Features/Planner/`; after shared orchestration, matcher, contacts and case forms).
- [ ] **F12 — contextual support exchange:** rep join brief from the request snapshot (see DESIGN.md Remote Support contract), actual question/snapshot, chosen sender/recipient, explicit acceptance/question acknowledgment/reply, retained failed-send draft and retry (`Features/RemoteSupport/`; configured contacts/cases and shared orchestration first).
- [ ] **F13 — Co-pilot support integration:** request help with zero deviations or while warning is pending; correct sender/session and prominent incoming reply without changing selection or losing drafts (`Features/CoPilot/`; after F10/F12).
- [ ] **F14 — retained session review:** unresolved-first confirmations, corrections and support exchanges; verify correct case after resume/relaunch and preserve actor/source/time. Export remains separate (`Features/CoPilot/`; after F05/F07/F13/F18).
- [ ] **F19 — core journey verification:** blank setup, independent contact/two cases, input change, relaunch/isolation, meaningful failure and relevant accessibility/device evidence (`docs/` and focused tests; after core integration).
- [ ] **F20 — five-minute delivery:** draft deck/script early, then verified-build screenshots/claims, three timed runs, playable backup, credits and authorized submission checks (`docs/`/presentation artifacts; final assets after F19).
- [ ] **F15 — conditional transport proof:** time-box chosen real-device request/receipt/disconnect/reconnect proof and document the actual network scenario before implementing a backend (`Services/` and decision/evidence note; core first).
- [ ] **F16 — conditional device delivery:** implement only the proven transport through `SyncService`, honest connection/receipt states, deduplication and stale-session/reconnect handling (`Services/`; after F15 passes).
- [ ] **F17 — conditional voice:** bounded explicit commands, visible listening state, duplicate/stale-command handling, permissions/capability/noise checks and touch fallback (`Features/CoPilot/`, `Services/Voice*`; reliable touch first).
- [ ] **F21 — later observation contract:** evidence/source/time/proposed result and separate human confirm/correct/reject states; unknown never completes an item (`Models/`; after stable core).
- [ ] **F22 — later camera observation:** mock labels only, captured frame/extracted text/proposed match and explicit review; unreadable or unseen means unknown (after F21 and labeled mock examples).
- [ ] **F23 — later AI assistant:** recorded-session questions and reviewable handoff drafts with sources, unresolved items and unavailable state; provider through `SyncService`, credited before implementation (stable core first).
- [ ] **User validation:** review the workflow with an OR nurse and device rep; document assumptions and feedback without recording real case data (`docs/`).

## Open decisions (team call)
- [ ] **Sync transport and network scenario (F15/F16).** Keep the labeled local demo until a time-boxed real-device proof passes. Multipeer Connectivity is a candidate for a nearby, in-room demonstration; distant support needs an appropriate internet-backed transport. Verify SDK/deployment compatibility, permission, receipt, disconnect/reconnect, and background behavior before choosing. Do not claim distant support survives an unavailable communications path. See [the transport decision](IMPLEMENTATION_PLAN.md#9-transport-and-voice-decisions-that-must-remain-honest).
- [ ] **Planner/rep device for the demo.** Prefer a second iPad if available; otherwise verify the actual available Mac/iPad build, permissions and role UI before choosing. Mac compatibility is not established by the starter's iPad target.

## Lane A: Co-pilot (folders: `Features/CoPilot/`, `Services/Voice*`)
- [ ] Build the adaptive progress / current work / activity layout from DESIGN.md; keep unresolved items, correction, and support access available
- [ ] Wire `VoiceCommandService` into `CoPilotView` with explicit listening/processing/unavailable labels, start/stop controls, duplicate-command protection, and touch fallback
- [ ] Deferred-item moment: persistent named amber warning pins that item; support, read-only review and pinned-item correction remain available; acknowledgment leaves it selected and unresolved
- [ ] Use discrete state transitions that respect Reduce Motion; verify enlarged text, readable status indicators, and keyboard/VoiceOver access
- [ ] Named support role, arrangement/connection labels, and a reduced-support explanation consistent with the shared state
- [ ] Show incoming remote prompts as a banner over the current step
- [ ] Test voice on the real iPad in a noisy room (early, not at hour 22)

## Lane B: Workspace + Planner + Remote Support (folders: `Features/Workspace/`, `Features/Planner/`, `Features/RemoteSupport/`)
- [ ] Create/edit independently named fictional cases with one supported template; worklist empty/filter states and explicit start/resume use saved state, not a locked Grand Marais session
- [ ] Planner list/detail: coverage-risk reasons, ranked options, one named-rep or reschedule plan, visible unrequested backup, actual acceptance, supersession/late-acceptance handling; no preparation checklist; coordinate shared state first
- [ ] Remote rep view: team's question, context/unresolved items, explicit acknowledgment, technical-support reply, and prominent receipt in Co-pilot
- [ ] Loading, empty, unavailable, disconnected, and failed-send states; preserve the team's draft and distinguish local-only from delivered/acknowledged messages
- [ ] Coverage Matcher: explain actual skill/availability/travel/closure constraints and stable ranking; keep Reschedule selectable but never automatically committed; no invented score required
- [ ] Optional after the core demo: Minnesota map with labeled coverage risk, with the same information available in the case list
- [ ] Optional after the core demo: evaluate weather integration against the simulated-data-only rule before implementation; keep the demo on fictional forecasts

## Lane C: Sync (folder: `Services/`)
- [ ] Implement the chosen backend as a `SyncService` conforming type
- [ ] Two-device test, only after the transport gate: current plan/acceptance and question/receipt/reply reach the correct session; demonstrate disconnect/reconnect and late obsolete-plan rejection. A reduced-support flag alone does not prove this journey
- [ ] Stream co-pilot log entries to the remote rep view

## Lane D: Pitch and demo
- [x] (Amartya / Claude) Lead the pitch with the rep join brief: define the Remote Support join-brief contract, F12 acceptance and F06 snapshot fields, and the cold-call contrast in the five-minute script (`docs/`; documentation only, no Swift changes). Merged in [PR #26](https://github.com/rsheth8/Northstar-OR/pull/26).
- [x] (Amartya / Claude) Research how an OR case runs in real time, the device rep's role and existing OR tools; record gaps and pitch implications for Northstar (`docs/OR_LANDSCAPE.md`; research only; merged in [PR #28](https://github.com/rsheth8/Northstar-OR/pull/28)).
- [x] (Codex) Turn F01–F28 into a two-person execution plan for Rahil and Amartya, with bounded subagent assignments, shared-file ownership, dependency handoffs, first work blocks and presentation responsibilities (`docs/`; planning only; merged in [PR #19](https://github.com/rsheth8/Northstar-OR/pull/19)).
- [x] (Codex) Reframe the plan around a configurable, persistent app with blank-workspace setup and repeatable case workflows; revise the presentation to the owner-confirmed five minutes; research institutional medical-software interaction patterns and translate them into Northstar design rules (`docs/`, README; planning/research only; merged in [PR #17](https://github.com/rsheth8/Northstar-OR/pull/17)).
- [x] (Codex) Review the owner's implementation-plan edits and align product/design/task scope; close plan-switch and pinned-warning edge cases; define presentation-critical proof, timed script, rehearsal, fallback, and submission checks (`docs/`; planning only; merged in [PR #15](https://github.com/rsheth8/Northstar-OR/pull/15)).
- [x] (Codex) Write the detailed product implementation blueprint: verified starter gaps, shared state contracts, screen-level work, dependency-sized PRs, acceptance tests, demo cut lines, and the path to institutional evaluation (`docs/IMPLEMENTATION_PLAN.md`; documentation only; merged in [PR #13](https://github.com/rsheth8/Northstar-OR/pull/13)).
- [x] (Codex) Publish the approved UI/UX rules, screen contracts, implementation order, and review criteria; align teammate/agent instructions and remove outdated decorative-UI tasks (`docs/`, shared agent instructions, PR template; merged in [PR #11](https://github.com/rsheth8/Northstar-OR/pull/11)).
- [x] (Codex) Refine the identity for institutional medical software: a restrained connected star/pulse, neutral wordmark, editable masters, and app assets (`docs/brand/`, app asset catalog; merged in [PR #9](https://github.com/rsheth8/Northstar-OR/pull/9)). Rural scenes are preserved as presentation artwork.
- [x] (Codex) Set up GitHub build/test checks, protected main without mandatory human approvals, PR defaults, and teammate/agent collaboration guide (merged in [PR #3](https://github.com/rsheth8/Northstar-OR/pull/3)); scheduled repo stewardship in the owner’s Codex chat every 15 minutes.
- [x] (Codex) Document agreed product direction, current implementation limits, and prioritized roadmap (`README.md`, `docs/PRODUCT.md`, `docs/TASKS.md`; merged in [PR #1](https://github.com/rsheth8/Northstar-OR/pull/1))
- [ ] Confirm the planned presentation roles at kickoff: Rahil integration/presenter/submission, Amartya device/evidence/backup; duration is owner-confirmed at five minutes; confirm deck format, submission location and access in DEMO_READINESS.md
- [ ] Build the concise slide deck from the proof/story map in DEMO_READINESS.md (due Sunday 12:00 PM CT); draft from F03, finalize only with verified build evidence
- [ ] Rehearse the 5-minute product presentation: workspace settings, normal new case, support loop, correction/review, second case and relaunch/resume. Operator triggers deferral; judge interaction only if allowed and rehearsed
- [ ] Record and test a backup screen capture of the final verified build, labeled with the actual communication mode
- [ ] Pass blank setup, independently created case/contact, changed logistical input and relaunch/isolation checks; complete three timed successful five-minute runs, failure/projection/audio checks and submission evidence in DEMO_READINESS.md
- [ ] Update the demo to show coverage disruption → support acceptance → recorded progress → support request with context; add camera/AI only when implemented and tested
- [ ] Update README credits and team names before submission

## Active native iPad visual migration reservation

Owner-approved implementation following the native iPad concept. F02 reserves `DesignSystem/NorthstarTheme.swift`, `DesignSystem/NorthstarComponents.swift`, `DesignSystem/NorthstarWorkspaceChrome.swift`, `App/RootView.swift`, `App/NorthstarORApp.swift`, `project.yml`, `NorthstarORUITests/`, `.github/workflows/ci.yml`, `docs/DESIGN.md`, and `docs/evidence/native-ipad/`. This is the shared shell/component PR; subsequent separate feature PRs reserve only PlannerView, CoPilotView, and RemoteSupportView respectively. Models, AppModel, session domain, matcher and SyncService are not changed. Functional setup/start/request contracts remain in their existing tasks.

- [~] (Amartya / Codex) **Planner native visual slice:** reserves only `Features/Planner/PlannerView.swift`, this claim and `docs/evidence/native-planner/`. Implements the approved list/detail styling against merged matcher/session APIs. No plan/request/create/start contracts are invented; F11/F27/F28 remain pending.
