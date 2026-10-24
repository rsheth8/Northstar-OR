# Task board

Claim a task by changing `[ ]` to `[~] (your name)`. Mark `[x]` when it's merged.
One task per branch and PR. Lanes keep people and agents out of each other's files.

## Agreed product direction

Read [PRODUCT.md](PRODUCT.md) and [DESIGN.md](DESIGN.md) before choosing implementation work. Northstar helps teams coordinate support, track reported progress, and hand off context. It prompts and documents; it does not assess clinical correctness.

Priority: one coherent simulated procedure and a reliable support journey before additional procedure types, maps, or visual effects. The items below are implementation work, not claims that these capabilities already exist.

Use [the detailed implementation blueprint](IMPLEMENTATION_PLAN.md) for the inspected baseline, shared state contracts, F01–F23 PR slices, dependencies, screen specifications, acceptance tests, effort assumptions, and demo cut lines. Claim a task here; blueprint IDs are planned slices, not additional active claims or GitHub issues.

Use [the presentation delivery plan](DEMO_READINESS.md) for the must-work proof matrix, timed primary path and fallback. First claim **F03**, followed by the separate shared contract/state slices **F04–F07**. Do not claim shared visual polish first. This review claims planning only; no app feature has been claimed or completed by it.

## UX delivery order

The approved logo and neutral shared styling are merged. This is the next implementation sequence, not a claim that the screen redesign is complete. Claim the corresponding task below. Keep shared files in their own small PRs; a grouped stage can require several PRs.

Start the fixture/contracts lane first. The visual foundation and viewport check can progress in another checkout after that work is claimed. Feature screens depend on the relevant merged state interfaces; they must label pending/unavailable capabilities honestly while integration is unfinished. Draft the script/deck from F03; final screenshots, recording and claims wait for verified integration.

| Order | Slice and ownership | Done when |
| --- | --- | --- |
| 1 | Fictional fixture and shared state prerequisites: F03–F07, separate PRs | One coherent pacemaker case; ranking-only secondary cases; independent session/selection/status; pinned acknowledgment; one coordinator plan (rep or reschedule); acceptance/connection/question acknowledgment kept separate; obsolete-plan events cannot activate coverage. |
| 2 | Shared accessibility/components: F01, `DesignSystem/` | Text scales with Dynamic Type; supporting labels meet the 13 pt baseline; essential indicators meet contrast targets; shared controls retain large hit areas, visible focus, and reduced-motion behavior. Can run in another checkout after the first fixture/state claim. |
| 3 | App shell and viewport: F02, `App/RootView.swift`, plus `project.yml` only for necessary settings | A real landscape iPad/window check explains and resolves unexpected letterboxing/overflow; navigation and active-case context remain stable; narrower windows and enlarged text retain essential actions. Coordinate shared context with stage 1. |
| 4 | Co-pilot touch journey: Lane A, F09/F10/F13 | Progress/current work/activity hierarchy adapts; required deferral pins that item; support/review/correction remain available; acknowledgment leaves the item deferred; touch recording/correction and incoming reply work. Depends on merged state/visual interfaces and coordinated support request work. |
| 5 | Planner decisions: Lane B, F08/F11 | Ranked cases/reasons, one named-rep request or mark-to-reschedule, visible unrequested backups, actual acceptance, and safe plan replacement. No preparation checklist. Browsing secondary cases leaves the active Co-pilot untouched. |
| 6 | Remote support exchange: Lane B | The request carries question/context/unresolved items; the recipient acknowledges and replies; Co-pilot visibly receives the reply. Pending, unavailable, and failure states are reviewable. |
| 7 | Voice and cross-device delivery: Lanes A/C, separate tasks | Explicit commands have a visible state and touch fallback; duplicate results do not duplicate records; transport/receipt states reflect evidence, including a disconnected rehearsal. Local demo labels remain until transport works. |
| 8 | Review and demo verification: review task plus Lane D | Review keeps unresolved items and sources visible. Rehearse one coherent journey on the intended devices, including enlarged text, VoiceOver/keyboard access, failed support, and reduced motion. Record actual results and workflow feedback. |

Camera, AI, maps, and additional procedure types follow the working core journey. Use [the screen contracts](DESIGN.md#4-screen-contracts) and [review evidence](DESIGN.md#9-review-evidence-for-a-ui-pr) to judge each slice. Visual polish never substitutes for the state/behavior prerequisites.

## Next implementation tasks (one task per branch/PR)
- [x] (Codex) **Shared design:** establish restrained clinical typography, flat controls, and quiet surfaces in `DesignSystem/`; preserve action sizes and semantic status colors (merged in [PR #8](https://github.com/rsheth8/Northstar-OR/pull/8)).
- [ ] **F03 — first implementation claim: shared fixture/data and copy.** One resettable fictional Grand Marais pacemaker scenario, stable clock, non-directive recording copy, honest completion labels. Keep Worthington and Bemidji browsable for ranking; the ICD row cannot launch the active checklist (`Data/` and coordinated feature copy; small PR).
- [ ] **F04 — shared session/event contracts:** session and actor/source IDs, separate selection/recorded item status, target-specific command and acknowledgment identities (`Models/`; shared-files PR).
- [ ] **F05 — Co-pilot domain:** unrecorded/deferred/team-confirmed items, correction history, duplicate/stale action guards. Required deferral pins that item; pending acknowledgment blocks confirmation/defer/item switching but permits support, read-only review and pinned-item correction (`Features/CoPilot/`; shared types land separately).
- [ ] **F06 — shared plan/support contracts:** one current coordinator plan/revision (rep request or reschedule), visible unrequested backups, superseded plans, named role/recipient, independent acceptance/connection/question/receipt state (`Models/`; shared-files PR).
- [ ] **F07 — local support orchestration:** request/accept/ack/reply, main-actor routing, case/session isolation, safe plan replacement and late old-acceptance handling, failure injection (`App/AppModel.swift`, `Services/SyncService.swift`; shared-files PR).
- [ ] **Shared UX foundation:** implement scalable typography, the 13 pt supporting-label baseline, high-contrast status indicators, and accessible primary/secondary/focus states (`DesignSystem/`; shared-files PR).
- [ ] **App shell and viewport:** verify the intended landscape iPad presentation; diagnose unexpected letterboxing and rigid sizing, and adapt navigation/context to window width and enlarged text (`App/RootView.swift`; shared-files PR; `project.yml` only if settings need correction).
- [ ] **Co-pilot:** wire voice commands with visible listening state, duplicate-command handling, and touch fallback; require an explicit command rather than inferring completion from conversation (`Features/CoPilot/`, `Services/Voice*`).
- [ ] **Planner + Remote Support:** allow a team member to request help at any time; include their question, current context, unresolved items, recipient acknowledgment, and prominent incoming messages (`Features/Planner/`, `Features/RemoteSupport/`; coordinate shared state first).
- [ ] **Sync:** connect separate devices through `SyncService`, show connection state, and test disconnected behavior without implying a message was delivered (`Services/`; coordinate shared state first).
- [ ] **Camera observation:** on mock labels only, show a captured frame, extracted text, proposed match, and explicit confirmation; unreadable or unseen means unknown, never skipped (feature implementation after a small shared-state PR).
- [ ] **AI assistant:** answer session questions and draft handoffs from recorded events; label drafts, preserve event sources, and review before sharing; choose an integration through `SyncService` and credit it before implementation.
- [ ] **Session review:** summarize confirmations, deferred items, corrections, and support interactions; label automated observations separately and decide persistence/export scope before implementing.
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

## Lane B: Planner + Remote Support (folders: `Features/Planner/`, `Features/RemoteSupport/`)
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
- [~] (Codex) Reframe the plan around a configurable, persistent app with blank-workspace setup and repeatable case workflows; revise the presentation to the owner-confirmed five minutes; research institutional medical-software interaction patterns and translate them into Northstar design rules (`docs/`, README; planning/research only).
- [x] (Codex) Review the owner's implementation-plan edits and align product/design/task scope; close plan-switch and pinned-warning edge cases; define presentation-critical proof, timed script, rehearsal, fallback, and submission checks (`docs/`; planning only; merged in [PR #15](https://github.com/rsheth8/Northstar-OR/pull/15)).
- [x] (Codex) Write the detailed product implementation blueprint: verified starter gaps, shared state contracts, screen-level work, dependency-sized PRs, acceptance tests, demo cut lines, and the path to institutional evaluation (`docs/IMPLEMENTATION_PLAN.md`; documentation only; merged in [PR #13](https://github.com/rsheth8/Northstar-OR/pull/13)).
- [x] (Codex) Publish the approved UI/UX rules, screen contracts, implementation order, and review criteria; align teammate/agent instructions and remove outdated decorative-UI tasks (`docs/`, shared agent instructions, PR template; merged in [PR #11](https://github.com/rsheth8/Northstar-OR/pull/11)).
- [x] (Codex) Refine the identity for institutional medical software: a restrained connected star/pulse, neutral wordmark, editable masters, and app assets (`docs/brand/`, app asset catalog; merged in [PR #9](https://github.com/rsheth8/Northstar-OR/pull/9)). Rural scenes are preserved as presentation artwork.
- [x] (Codex) Set up GitHub build/test checks, protected main without mandatory human approvals, PR defaults, and teammate/agent collaboration guide (merged in [PR #3](https://github.com/rsheth8/Northstar-OR/pull/3)); scheduled repo stewardship in the owner’s Codex chat every 15 minutes.
- [x] (Codex) Document agreed product direction, current implementation limits, and prioritized roadmap (`README.md`, `docs/PRODUCT.md`, `docs/TASKS.md`; merged in [PR #1](https://github.com/rsheth8/Northstar-OR/pull/1))
- [ ] Assign presenter, device operator, integration owner and submission owner; confirm actual presentation duration, required format, submission location and access in DEMO_READINESS.md
- [ ] Build the concise slide deck from the proof/story map in DEMO_READINESS.md (due Sunday 12:00 PM CT); draft from F03, finalize only with verified build evidence
- [ ] Rehearse and finalize the 3-minute primary script; operator triggers the required-item deferral. Judge interaction is optional only if allowed and rehearsed
- [ ] Record and test a backup screen capture of the final verified build, labeled with the actual communication mode
- [ ] Complete three timed successful primary runs plus the alternate/failure checks, projection/audio check and submission evidence in DEMO_READINESS.md
- [ ] Update the demo to show coverage disruption → support acceptance → recorded progress → support request with context; add camera/AI only when implemented and tested
- [ ] Update README credits and team names before submission
