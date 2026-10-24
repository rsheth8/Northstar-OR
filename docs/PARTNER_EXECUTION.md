# Northstar OR: Rahil + Amartya build plan

Working allocation requested by Rahil on October 24, 2026. **Rahil owns the shared core, Co-pilot and release. Amartya owns configuration, Planner and the rep experience.** Amartya implements the local repository; Rahil takes the contact-directory screen to balance the work. Each person supervises a focused builder instead of splitting the app into disconnected projects.

This assigns responsibility for upcoming work. It does not mean either person or an agent has claimed or implemented those slices. [TASKS.md](TASKS.md) remains the live claim/completion board. Read [PRODUCT_FOUNDATION.md](PRODUCT_FOUNDATION.md), [DESIGN.md](DESIGN.md) and [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for scope, appearance and acceptance; this plan organizes their delivery. [AGENT_BRIEFS.md](AGENT_BRIEFS.md) contains the kickoff prompts.

## 1. Shared finish line

Build one coherent, configurable fictional product:

**Blank setup → editable directory → create two cases → choose one support plan → explicitly start/resume → record/defer/correct → question/acknowledgment/reply → retained review → relaunch.**

The normal product controls must work with independently chosen fictional names, schedules and contacts. Optional samples use those same controls and state. Start with touch and the truthful **“On this device”** communication mode. Professional quality means clear worklists/forms, stable case context, restrained typography, visible unresolved work and dependable recovery under [DESIGN_REFERENCES.md](DESIGN_REFERENCES.md).

One workspace, a small directory and one versioned supported coordination template are enough for this build. No clinical instructions, patient fields, invented readiness score or unsupported ICD workflow. Camera, AI, maps, video and extra template types are not active assignments. Voice and separate-device transport are conditional after core proof.

The core estimate remains **32–56 person-hours**, not a delivery promise. The deadline is **Sunday, October 25, 2026 at 12:00 PM CT**. Two people and agents do not eliminate serial model changes, CI, device checks, breaks or rehearsal. Re-estimate after the first integrated setup/new-case result; cut optional breadth before repeatability.

## 2. The partner split

| Responsibility | Rahil | Amartya |
| --- | --- | --- |
| Product decisions | Own scope, nonclinical copy, core acceptance and cut decisions | Challenge confusing administration/rep flows and report actual blockers |
| Shared domain | Own F03/F24/F04/F06: reusable content, stable IDs, session/events, plan/question contracts | Review fields needed by setup, repository and recipient screens before implementation |
| Session and integration | Own F05/F07: guarded recording, corrections, AppModel/Sync routing, case isolation | Supply concrete repository API/error semantics; exercise recipient-side commands |
| Persistence | Review snapshot contract and integrate it through F07 | Own F18 atomic local store, failure/corruption/version behavior and restoration tests |
| Interface foundation | Review clarity and consistency against the approved guide | Own F01/F02: scalable components, shell, viewport and Workspace settings entry |
| Product screens | Own Co-pilot F09/F10/F13, review F14, and directory F26 after setup lands | Own setup F25, case forms F27, matcher F08, Planner F11, recipient/support F12, worklist/start/resume F28 |
| Quality | Own candidate commit and F19 release gate; cross-test Amartya's flows | Cross-test Rahil's warning/correction/review flows; capture device/layout/failure evidence |
| Five-minute presentation | Lead narrative/deck, present and coordinate submission | Drive the app, maintain a playable backup and know the recovery path |

These are working defaults, not assumptions about either partner's skill. Transfer a whole slice if capacity changes. Record the new human owner, exact files and dependency in the task/PR before a second writer starts. Do not split one unmerged feature between two unsynchronized drivers.

**Rahil is the integration owner. Amartya is the UI consistency and device-evidence owner.** Both can flag a release blocker. The existing repo steward assists with ready PRs; its 15-minute schedule is not continuous supervision. Keep unfinished work draft or explicitly on hold so it is not integrated prematurely.

## 3. Small agent team

| Role | Supervisor | Active assignment | Limits |
| --- | --- | --- | --- |
| Core builder | Rahil | One shared-content/contracts/integration slice at a time; later Co-pilot/review or F26 | Exclusive driver for its named shared files; no parallel type system or infrastructure rewrite |
| Operations builder | Amartya | One component/shell, repository, setup, case or support slice at a time | Uses merged domain contracts; no private session store or direct network SDK in a view |
| Independent reviewer | Whoever is integrating | Read the other builder's PR, acceptance and evidence | Read-only; report actionable defects and unrun checks; no invented GitHub approval |
| Temporary session builder | Rahil, only after F04 merges | F05 while the core builder completes F06 | Replaces the reviewer slot; separate checkout, CoPilotSession and its tests only; no Models edits |

**Default: two writing agents and one read-only reviewer.** A third writer is useful only for the clearly separated F05/F06 window or another explicitly reserved file set. It replaces the reviewer while active; stay within the tool's actual concurrency limit. Retire/reassign it when that task ends. Do not launch dedicated agents for every future screen or optional feature.

The humans decide priorities, inspect the app and check outputs. Agents implement bounded changes and run available checks. An agent saying “done” does not establish physical-device usability, message delivery, relaunch behavior or institutional readiness.

## 4. File ownership and reservations

| Files | Default driver | Rule |
| --- | --- | --- |
| `NorthstarOR/Data/` | Rahil/core builder | F03 first. Optional seeds and supported content; no script-only behavior |
| `NorthstarOR/Models/` | Rahil/core builder | F24 → F04 → F06, one shared-contract PR at a time; other workers request exact missing fields |
| `NorthstarOR/App/AppModel.swift`, `NorthstarOR/Services/SyncService.swift` | Rahil/core builder | F07 and later bridge fixes are their own small PRs; all features use agreed commands |
| New repository files under `NorthstarOR/Services/` | Amartya/operations builder during F18 | Reserve exact filenames when claiming. Use merged Codable contracts; DTO changes get their own coordinated contract PR. AppModel integration belongs to F07 |
| `NorthstarOR/DesignSystem/`, `NorthstarOR/App/RootView.swift` | Amartya/operations builder | F01/F02 separate from feature work. Necessary bootstrap/optional-session adapters require an explicit handoff before Rahil edits shell files |
| `NorthstarOR/App/NorthstarORApp.swift`, `project.yml` | Named driver for a necessary shell/bootstrap fix | Reserve before editing; explain observed cause. Never commit generated `.xcodeproj` |
| `NorthstarOR/Features/CoPilot/` and later `Services/Voice*` | Rahil/session builder | Domain F05 and UI F09/F10 are sequential when they touch the same file |
| `NorthstarOR/Features/Workspace/` | Amartya for F25; Rahil for F26 after F25 merges | Reserve separate settings/directory filenames. Amartya integrates the directory entry in a named bridge if needed; never two writers in one settings file |
| `NorthstarOR/Features/Planner/`, `Features/RemoteSupport/` | Amartya/operations builder | Matcher, forms, plan UI, support exchange and start/resume remain separate PRs |
| `NorthstarORTests/` | Owner of the behavior under test | Reserve specific test files too; new focused files avoid two writers changing the same test class |
| `docs/TASKS.md`, handoff notes, README integration status | Rahil/integration driver after kickoff | Publish other workers' claims/completions promptly. Agents may update their own task line if it is explicitly reserved; don't rewrite the board |
| Deck/evidence/backup | Rahil for narrative; Amartya for capture | Final assets identify the same candidate build; only actual results enter the slides |

Every writer has its **own branch and checkout**. Never change a shared checkout's branch while another agent or Xcode session is using it. Check existing attached worktrees and PRs first. Dependencies mean **merged interfaces on current main**, not another agent's local uncommitted files. Do not fetch/cherry-pick an unmerged dependency to make a screen appear unblocked.

Keep migrations compiling through small adapters. If a shared change requires a consumer edit, reserve those exact files with their owner and land a focused bridge; do not silently expand a contract PR into a screen rewrite. Explicit handoff is coordination, not an extra mandatory human-approval gate.

## 5. First 60–90 minutes

| When | Rahil | Amartya | Useful result |
| --- | --- | --- | --- |
| First ~10 minutes | Confirm ownership, check open PRs and latest main; publish the F03 claim | Verify local build tools and available iPad/simulator; identify presentation machine | Two clean independent checkouts, device/runtime recorded, no duplicate task claim |
| Next ~35–50 minutes | Core builder implements F03; review recording-only content and reusable seed/template shape | After F03 is visibly claimed, operations builder implements F01 only | Two focused draft PRs; baseline build/check results recorded |
| Remaining block | Review/land F03 if ready; make F24 concrete and list the fields/IDs consumed by F04/F18 | Review F01 evidence; begin F02 viewport diagnosis only after its file reservation | First merged slice(s) or a precise blocker; next contract PR ready to build |

Do not promise all contracts, storage and forms within 90 minutes. First prove two small PRs can build, merge and be consumed. In parallel with agent work, agree minimal setup/case fields and start the slide outline from the product loop; no final screenshots yet.

Both people should be able to build/run the starter independently. Choose the actual presentation device and operator early. A second physical device is optional; Mac support is not established by this iPad target. Initial communication remains local until a transport proof passes.

## 6. Build waves and handoffs

These are dependency gates, not fixed-duration promises. The exact acceptance for each F-number remains in the implementation blueprint.

| Wave | Rahil + agents | Amartya + agent | Merge/exit gate |
| --- | --- | --- | --- |
| A. Content and interfaces | F03 → F24 → F04 → F06; optionally delegate F05 after F04 while the core builder finishes F06 | F01 → F02; F08 after F03 and the actual matcher input contract settles | Stable template/version, workspace/case/session/actor IDs, independent item/selection, plan/question/receipt contracts; old consumers still compile |
| B. State, storage and touch | Finish F05; F09 → F10 once F01/F02/F05 land | F18 after F24/F04/F06; finish F08 | Direct domain tests pin the just-deferred item, reject duplicate/stale targets and preserve correction history. Store round trips, write failures and unsupported/corrupt data are exercised |
| C. Ordinary product setup | F07 integrates the landed store and local commands. Take F26 after F25 merges, in separate directory files | F25 setup/settings → F27 new/edit case forms; publish directory needs before Rahil's F26 | Blank setup and ordinary case creation save/restore; no array-zero active session. F25 may prepare against the landed repository, but functional shell/bootstrap integration must land before claiming setup works |
| D. Connected local workflow | Supply any small reserved integration bridge. F13 after F10/F12, then F14 retained review | F11 after F07/F08/F26/F27; F12 after F07/F26/F27; F28 after F11/F27/F05/F07/F18 | One human plan, explicit rep acceptance, persistent warning + available question, explicit question acknowledgment/reply, correct case start/resume and retained review |
| E. Candidate and delivery | Lead F19; finalize F20 narrative and submission | Cross-test F19, operate rehearsals, capture screenshots and backup for F20 | Independent contact/two-case/input-change/relaunch/failure proof, usable layouts, three consecutive runs ≤5 minutes and playable backup |

Rahil finishes F26 during Amartya's case-form work rather than waiting idle for F12. F26 shares contracts with F25 but has a different reserved view/test file; any settings-entry integration has one driver. Amartya's F11/F12 can be reordered when dependencies allow, but not split into simultaneous writers in overlapping files.

F19 cases are drafted as each slice lands, not first discovered at the end. F20's outline starts in Wave A; final screenshots, evidence claims and recording wait for the candidate. If a wave stalls, name the missing API/PR and work on an independent check or slide task instead of inventing a duplicate implementation.

## 7. Full slice allocation

One row is one accountable owner, not one continuously running agent. Each slice keeps its own branch/PR. The optional rows are a future allocation only.

| ID | Human owner | Delivery |
| --- | --- | --- |
| F01 | Amartya | Accessible shared components and scalable typography |
| F02 | Amartya | Adaptive shell, settings entry and viewport diagnosis |
| F03 | Rahil | Reusable fictional template/seed factory and non-directive copy |
| F04 | Rahil | Session, actor/source, event/intent and acknowledgment contracts |
| F05 | Rahil | Guarded selection/confirmation/deferral/acknowledgment/correction |
| F06 | Rahil | One current plan, supersession, arrangement/question/snapshot/receipt contracts |
| F07 | Rahil | Repository-backed local orchestration and case/session isolation |
| F08 | Amartya | Pure explainable matcher and boundary cases |
| F09 | Rahil | Adaptive Co-pilot layout |
| F10 | Rahil | Recording, warning and correction interactions |
| F11 | Amartya | Planner plan/options/backups and actual acceptance |
| F12 | Amartya | Question/context/recipient acknowledgment/reply and failure retention |
| F13 | Rahil | Co-pilot request entry and prominent incoming reply |
| F14 | Rahil | Retained unresolved-first session review |
| F15 | Amartya | Conditional transport proof; Rahil reserves any shared protocol changes |
| F16 | Amartya | Conditional proven transport/receipts/recovery, coordinated Services reservation |
| F17 | Rahil | Conditional bounded voice and real-device input checks |
| F18 | Amartya | P0 versioned atomic local repository and recovery tests |
| F19 | Rahil, both execute | Integrated correctness, recovery, layout and workflow evidence |
| F20 | Rahil, Amartya operates | Five-minute deck/script, recording/fallback and submission verification |
| F21 | Rahil | Later observation/evidence contract; not active |
| F22 | Rahil | Later mock-label capture/review; not active |
| F23 | Amartya | Later grounded handoff drafts through SyncService; not active |
| F24 | Rahil | Workspace/site/contact/template/case contracts |
| F25 | Amartya | Blank setup and editable Workspace settings |
| F26 | Rahil | Support directory after Amartya's F25 handoff |
| F27 | Amartya | Validated ordinary new/edit case forms |
| F28 | Amartya | Worklist/filter and explicit isolated start/resume |

Count actual review/integration/device effort, not task counts. If one partner has several blocked tasks or a review queue, move one whole disjoint slice to the idle builder. Keep Models/AppModel/Sync ownership serialized. Never relieve overload by dropping persistence or hard-coding sample names.

## 8. Contract handoff and PR rhythm

Before an agent starts a dependent slice, the owner supplies this compact handoff in its PR description or task message:

1. **Merged PR/commit and task ID.** Exact public types, commands, IDs and schema version the consumer uses.
2. **Ownership.** Allowed files/test files; explicitly reserved bridge files; next consumer and its human owner.
3. **Behavior.** Valid input, no-workspace/no-session/unknown states, success result and observable error/unsaved/pending states.
4. **Evidence.** Tests actually run and results; for visible changes, named device/window/text-size screenshots and relevant failure/empty/warning state. List unrun checks separately.
5. **Remaining work.** Next dependency and known limitations; no “Saved,” “accepted,” “delivered” or “connected” claim beyond implementation evidence.

F24 must settle fields/template applicability rather than making F03 invent a disposable parallel schema. F06 must publish immutable request snapshots and plan revisions. F18 must publish a concrete load/save/error contract plus injectable test store before forms rely on it. F07 must expose validated app commands before feature views mutate shared state. Consumers request missing commands instead of adding private shadow stores.

For every task: clean latest main → claim one task visibly → own branch/checkout → draft PR → implement/test → review own diff and independent findings → required CI → ready PR → squash merge → consume main → mark complete in the next board update. Use `copilot/`, `planner/`, `sync/`, or `pitch/` branches from the existing blueprint. Do not run two code agents in one checkout or force-push another person's active branch.

Rahil maintains merge order and candidate identity. Amartya can mark his PR ready after actual checks; the steward may integrate a ready independent PR. A missing dependency stays draft/hold. No required human GitHub approval is introduced. Review comments and failed required checks still need resolution; no bypass or fabricated approval.

## 9. Acceptance checkpoints and deadline decisions

| Checkpoint | Required proof / decision |
| --- | --- |
| First 60–90 minutes | Two lanes running, F03 first claim, first small PRs/checks, chosen device, next shared interface concrete |
| After the first ~4 hours | Inspect actual progress on contracts, guarded domain and store; re-estimate. If contracts/storage are still unsettled, simplify fields/configuration and stop all optional work |
| Sunday 12:00 AM CT | Target ordinary setup → new case → local support loop. If absent, explicitly identify missing core proof and reduce presentation claims; no maps/camera/AI/extra templates or unproven voice/transport |
| Sunday 6:00 AM CT | Feature freeze. Choose demonstrated communication/input modes from evidence; no new provider integration. Retain touch/local fallback |
| Sunday 9:00 AM CT | Target alternate-case/relaunch/failure checks, three timed runs, final screenshots and playable backup. Only blocking fixes afterward; relevant fixes require affected checks again |
| Sunday 11:00 AM CT | Submission/access/credits/final CI and artifact verification; avoid using this hour for ordinary feature development |
| Sunday 12:00 PM CT | Recorded submission deadline; reopen submitted links/artifacts and record confirmation |

These are readiness decisions, not an instruction to work without sleep. Plan breaks around a green integrated build and leave an explicit handoff/candidate note. Do not consume rehearsal and submission time to preserve an optional feature.

At each checkpoint, both people answer: What works on current main? What is the next blocking PR? What evidence is missing? Which optional item is being cut? A false state, cross-case update, lost record/draft or bypassed acknowledgment blocks the corresponding capability claim.

## 10. Five-minute responsibilities and completion

| Role | Working owner | What they prepare |
| --- | --- | --- |
| Integration/candidate | Rahil | Dependency order, reviewed green candidate, open-blocker list |
| Presenter/narrative/deck | Rahil | [Five-minute story](DEMO_READINESS.md#5-working-five-minute-script), factual capability labels and final credits |
| Device operator | Amartya | Normal setup/new-case/support/review/resume controls, explicit role switches, known reset and recovery |
| Evidence/backup | Amartya, Rahil reviews | Candidate-linked screenshots, alternate checks, playable recording and accessible backup copy |
| Submission | Rahil, Amartya verifies | Organizer format/access/required fields, final upload and reopening confirmation |

Both learn the complete journey and test the other person's work. Rahil cross-tests blank setup/new case/plan replacement/failed reply; Amartya cross-tests warning pinning/support while pending/correction/relaunch review. Agents can automate domain checks, but humans must actually perform and record the applicable device/rehearsal checks.

The ready product demonstrates independently created contacts/two cases, changed logistical input, one current plan, explicit acceptance, persistent unresolved work, question/ack/reply, correction history and correct relaunch. Three consecutive five-minute runs and backup playback gate the final presentation claim. Missing functionality stays labeled planned; visual polish does not establish hospital deployment readiness.

**Start now:** Rahil dispatches the F03 brief; after that claim is visible, Amartya dispatches F01. Each stops at a small reviewed PR, consumes merged main, then takes the next unblocked slice. This planning task has not started either implementation worker or claimed their code tasks.
