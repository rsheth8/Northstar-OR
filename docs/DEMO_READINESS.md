# Northstar OR: presentation delivery plan

Planning review: **2026-10-24**, against `main` at `29d999f` plus the owner's implementation-plan edits. This document is a build/rehearsal contract. The app remains a starter; writing this plan does not establish that any gate has passed.

Owner correction: **five full minutes**, confirmed on 2026-10-24. Present a configurable app with ordinary setup, case creation and retained records. This supersedes the earlier three-minute, single-seeded-case presentation minimum; the rehearsal path never limits product behavior.

Use [PRODUCT.md](PRODUCT.md) for scope, [PRODUCT_FOUNDATION.md](PRODUCT_FOUNDATION.md) for setup/repeatability, [DESIGN.md](DESIGN.md) and [DESIGN_REFERENCES.md](DESIGN_REFERENCES.md) for institutional UI, [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for F01–F28 dependencies, and [TASKS.md](TASKS.md) to claim work. Only simulated data is permitted.

## 1. What the audience should understand

**When travel disrupts technical coverage, Northstar helps a rural team choose a support plan, share the actual question and context, and keep unresolved work visible.**

Connect the prompt, *Connect & Intersect*, to behavior the audience sees: Planner intersects simulated skill/availability/travel constraints; the support flow connects people around one shared session record. Present this as the team's framing, not an official judging rubric.

The three destinations form one story: **coverage decision → explicit acceptance → team-reported progress → contextual question → human acknowledgment/reply → review**. Keep the same fictional case, named role, question and unresolved item throughout.

First show where that case comes from: editable workspace/contact configuration and the normal New case form. End with retained records/start-resume proof. Sample content is a convenience; an independent new case must support the same workflow without code changes or special taps.

The presentation must make eight things clear:

1. Why the coordinator needs a different support arrangement.
2. Which single plan is current, who accepted it, and which options remain unrequested.
3. What the team recorded and what remains deferred.
4. What the representative received and explicitly acknowledged.
5. How the reply and correction appear in the shared record.
6. Which communication mode is actually running and which extensions remain planned.
7. How a user configures the workspace and creates a supported case.
8. How another case and a relaunch preserve the correct records and drafts.

## 2. Scope that must stay fixed

- **Product scope:** one configured fictional workspace, a small editable support directory and multiple independently created cases using one supported pacemaker coordination template. Blank setup and optional sample loading are separate entry choices.
- **Presentation case:** create a fictional case through the normal form. Grand Marais/Ana may be prepared example values, never code dependencies. Keep another saved compatible case to demonstrate isolated start/resume. The unsupported ICD template cannot launch.
- **Primary coverage path:** explicitly choose a configured rep and accept in that simulated role. Ana is a rehearsal choice; other contacts and Reschedule are functional, separately verified choices.
- **One current plan:** before commitment it is unset; after commitment it is one named-rep request or mark-to-reschedule. Backup options are unrequested candidates with truthful availability.
- **No Planner preparation checklist.** Put the effort into the decision, acceptance and handoff.
- **Primary input:** touch. Voice and cross-device communication enter the script only after their own gates pass.
- **Warnings:** required deferral pins that item. Confirmation, additional deferral and item switching are blocked. Support, read-only review and pinned-item correction remain available. Acknowledgment leaves it selected and deferred.
- **Support:** a real question, timestamped context snapshot, explicit question acknowledgment, and a reply visible in Co-pilot. A question may be sent before coverage acceptance; it does not silently commit a coverage plan.
- **Record:** F18 persistence is core. Configuration, contacts, cases, events and drafts survive tested relaunch; pending messages are reconciled without invented delivery. Preserve original/corrected events and unresolved work.
- **Optional:** maps, camera, AI, rich attachments, video, advanced administration and additional procedure templates remain outside the required five-minute path. Normal case creation and persistence are required product capabilities.

## 3. Must-work proof matrix

All rows are **not yet verified** at this planning baseline. F19 records the actual results; a PR merge alone does not mark a manual gate passed.

| Proof | Implementation slices | Observable pass condition | Baseline gap |
| --- | --- | --- | --- |
| Set up and create ordinary records | F03, F24–F27, F18 | Blank workspace setup, editable contact and a new compatible fictional case work without source edits, seed IDs or a storm | No configuration/case forms or repository; unconditional seed initialization |
| Explain the coverage problem | F03, F08, F11 | Grand Marais shows 110-minute travel versus closure in 90 minutes; logistical reasons and ranked secondary cases are readable | Matcher reasons/availability and decision UI need work |
| Commit exactly one plan | F04, F06, F07, F11, F12 | Ana is requested then explicitly accepted; Marcus remains unrequested. Reschedule and plan replacement pass alternate checks | No current-plan or acceptance model |
| Demonstrate the Co-pilot moment | F05, F09, F10 | Defer a required item, keep it pinned, request help while the warning persists, acknowledge without resolving it | Starter advances selection and lacks domain gate guards |
| Close the support loop | F06, F07, F12, F13 | Rep sees the exact question/unresolved snapshot, explicitly acknowledges it, replies, and Co-pilot displays that reply | No question/request/receipt state or prominent incoming reply |
| Show a trustworthy retained record | F04, F05, F14, F18 | Review matches state/corrections/unresolved work and survives relaunch | Text-only in-memory log; no correction/review/store |
| Prove repeatable use | F18, F27, F28, F19 | Independently named second case, changed logistical input, safe case switch and restored drafts/records all pass | Only one hard-coded active sample session |
| Look coherent on the presentation device | F01, F02, F09–F14 | Full intended viewport, calm shared styling, readable projected labels, reachable actions and keyboard-safe question entry | Viewport diagnosis, scaling and responsive feature layouts pending |
| Finish and recover on time | F03, F19, F20 | Three consecutive primary runs within the time limit, deterministic reset, failure drill and playable same-build backup | No rehearsal evidence, final script recording or submission evidence |

For each row record commit, device/OS/window, operator, date/time, result, evidence location and unresolved issue. A false confirmation/acceptance/delivery, wrong-session update, lost draft on the supported path, or hidden essential action blocks the corresponding readiness claim.

## 4. Implementation order that protects the presentation

1. **F03 first, then F24:** create reusable fictional template/seed content and workspace/site/contact/case contracts. Optional samples use ordinary IDs/actions; an empty repository is valid.
2. **F04/F06, F05/F18, then F07:** establish identities/plans/guards and core versioned storage, then repository-backed local request/accept/ack/reply. Each is a focused PR; persistence does not wait for the review screen.
3. **F08:** fix pure matcher availability, reasons, stable ranking and explicit Reschedule candidate after the fixture is stable. Ranking must never commit a plan.
4. **F01/F02 in another checkout when available:** scalable text, meaningful contrast, control states and actual viewport diagnosis. These are required for final screen quality, but they are not the first claim.
5. **F25–F28 and F09–F14:** implement setup/settings, contacts, case forms/worklist/start-resume and the normal support/review journey. Verify blank setup and an independently created case; feature screens consume the same saved state.
6. **F19/F20:** collect proof, rehearse, record and submit. Draft the deck/script from F03 instead of waiting for every screen to finish. Keep screenshots and capability claims provisional until the relevant build passes.

F15/F16 transport and F17 voice remain conditional improvements with time-boxed proof; use the honest local/touch mode if unproven. F18 storage is core, while F21–F23 camera/AI follow it. Do not replace actual configuration with a demo-mode subsystem or a hard-coded screen sequence.

## 5. Working five-minute script

The owner confirms **five minutes: 300 seconds**. Required deck format and submission process still need confirmation. Rehearse the full time including text entry, role switches and restart. Spend the added time proving setup, a normal new case and retained use rather than adding optional AI spectacle.

Keep one presenter and one device driver where staffing permits. Begin with a plainly identified configured fictional workspace and one existing saved case; show editable settings, then create a distinct case live. The clean-install setup path must also pass independent verification before readiness is claimed. On one device, visibly switch simulated roles and show “On this device”; do not describe tab updates as distant communication.

| Time | On screen / operator action | Presenter point | Proof to leave visible |
| --- | --- | --- | --- |
| 0:00–0:25 | Problem and product loop slide | Travel disruption exposes a coordination/context gap; the app supports repeatable case work | Clear purpose, simulated scope, no invented outcome statistic |
| 0:25–1:05 | Workspace settings and contact directory; save a visible administrative edit | A facility configures its workspace and support options through normal controls | Saved configuration and a selectable named technical role |
| 1:05–1:45 | Planner: create a distinct fictional case from the supported template | This case is created with ordinary fields, not selected from a script-only screen | New case reference, schedule/site/template, useful worklist and validation |
| 1:45–2:20 | Explain the new case's logistical reason; request configured rep; explicitly accept in rep role | One plan is requested and accepted; backup and reschedule stay distinct | Actual selected role/plan and communication mode |
| 2:20–3:10 | Start recording, confirm one item, defer a required item, send the question while warning remains, then acknowledge | The app records explicit actions, pins unresolved work and keeps support accessible | Question snapshot; item remains selected/deferred after acknowledgment |
| 3:10–3:45 | Rep sees question/context, acknowledges and replies; return to Co-pilot | The recipient has the exact question and unresolved context | Explicit question acknowledgment and prominent reply |
| 3:45–4:15 | Correct a different earlier confirmed item, then open review | Original records, corrections and unresolved work remain distinguishable | Actor/source/time and retained unresolved count |
| 4:15–4:40 | Show another saved case, explicitly resume the new case and relaunch/resume if rehearsed within this window | The product retains distinct records beyond a single run | Correct case/session and persisted record/draft; no automatic sample reset |
| 4:40–5:00 | Evidence/status and closing slide | State the implemented setup/storage/communication scope and the next fictional user evaluation | Tested capabilities and unfinished institutional deployment work described accurately |

These windows total 300 seconds. Rehearse the chosen values for pacing, but the app cannot require those values or this sequence. The operator triggers the deferral. Invite a judge to choose a fictional case name or support option only if the format permits and timing is rehearsed; independent variation tests are required regardless.

Agree the exact required item and question in F03/F20. A suitable fictional question is “Which mock model reference should we use?” Any prefilled or clipboard question remains a visible, editable draft that the operator explicitly sends. No hidden acceptance, pre-sent message or pre-completed checklist should masquerade as a live action.

Keep one different confirmed item available for the correction moment; correcting it must not resolve the deliberately deferred item. The review must end with that unresolved work visible.

## 6. Slide/story map

This is a proposed six-slide outline, not a claim that a deck has been built or that six slides are required by the organizer. Use the current brand artwork and neutral typography; screenshots come from the final verified build.

| Slide | Purpose | Required content / constraint |
| --- | --- | --- |
| 1. Problem | Establish the user's coordination difficulty | One fictional site, a travel disruption, and the consequence of missing shared context. Avoid invented market/outcome statistics |
| 2. Product loop | Orient the audience before the live product | Setup → create case → Planner → Co-pilot → support → retained review; explain Connect & Intersect through actual work |
| 3. Product setup / standby | Transition into normal app controls; remain available as fallback | Configured fictional workspace and normal case creation; label any backup recording clearly |
| 4. What connects it | Explain the implemented mechanism in plain language | Shared session, explicit actions, context snapshot and actual communication mode. An architecture illustration must match the build |
| 5. Evidence and limits | Make the demonstrated scope credible | Device/build, rehearsal result, meaningful failure check, simulated-data boundary, tested vs planned features. Populate only after F19 |
| 6. Next step and credits | Close with a specific continuation | Fictional walkthrough with OR staff/device reps, one learning goal, team names and required tool/library/asset credits |

Spend most of the presentation on the live journey. There is no requirement to read every slide or explain implementation details while an operator is taking an action. Optional camera/AI belongs on the future-work area unless its own tested slice is included in the actual build.

## 7. Alternate-path verification before rehearsal sign-off

These checks protect correctness but do not all need to appear in the timed presentation. Add automated state tests where applicable and capture manual UI evidence for the relevant screen.

| Check | Expected result |
| --- | --- |
| Blank install → setup → relaunch | Saved fictional workspace and directory restore without loading seeds |
| Create independent contact and two cases | Ordinary forms/validation, no sample IDs, same supported workflow available |
| Change availability/schedule/travel; omit forecast | Matcher responds to actual inputs and represents unknowns; no scripted storm requirement |
| Save failure / corrupt or unsupported file | Draft preserved, visible error/recovery; no false Saved result or silent reset |
| Unset plan → reschedule | Records a coordinator choice, no recipient acceptance, no claim that an external booking changed |
| Ana requested → Marcus requested → late Ana acceptance | Only Marcus's current request can become accepted; Ana's obsolete acceptance stays historical/stale |
| Accepted rep → reschedule → late rep event | Reschedule remains current; a stale event cannot restore the old arrangement or overwrite the header |
| Reschedule → new named rep | New request/plan identity; explicit new acceptance required |
| Unchosen backup | Visible candidate with truthful availability; no invitation/acceptance event until selected |
| Browse/start/resume supported cases; inspect unsupported ICD row | Browsing preserves active context; explicit switch restores isolated saved record and cannot bypass a pending gate. Unsupported ICD content remains unavailable |
| Required deferral → attempt item switch/confirm/defer | Domain and UI reject the change; deferred item stays selected across all input routes |
| Support/review/tab/reply while warning pending | Support and read-only review work; warning and pinned selection survive return/incoming reply |
| Acknowledge warning | Clears the gate only; deferred state, selected item and unresolved count remain |
| Correct the triggering deferral | Explicit logged correction supersedes the gate; no silent acknowledgment or lost original record |
| Request with zero deferred items or no accepted coverage | Chosen question recipient is explicit; question works without committing coverage implicitly |
| Failed send/retry | Question/context and draft remain; retry reuses the logical message ID; no false receipt |
| Duplicate/stale/wrong-session event | No second mutation, no change to another item/case/session, visible handling where relevant |
| Transport disconnect, if included | Acceptance and connectivity remain distinct; no unsupported delivered state; reconnect is tested |
| Voice denial/noise/repeated result, if included | Touch works; no accidental or duplicate recording; actual capability is shown |

The current correction/gate policy is defined in IMPLEMENTATION_PLAN.md. If a slice changes it, update the contract and relevant tests together before rehearsing a different story.

## 8. Rehearsal, visual finish and fallback

Use one final candidate build. Record at least three consecutive successful runs within five minutes, including setup/settings, normal case creation and retained resume. Use fresh case/session IDs and the standard forms on each run; only explicitly reload sample configuration when desired. Separately pass blank installation, independently chosen values and relaunch. Relevant changes after sign-off require affected checks and the timed sequence again.

| Check | Evidence / pass condition |
| --- | --- |
| Viewport and projection | Actual iPad, OS, window/orientation and display setup recorded; no unexplained letterbox or clipped essential content. Read the question, warning, plan and reply from the audience's viewing position |
| Consistency | Approved mark proportions, neutral type, shared spacing/radii, flat controls; no decorative glow, orb or flashing border; one clear emphasis per work area |
| Interaction | Touch path passes; enlarged text remains usable; keyboard does not hide question/send. Record relevant VoiceOver/focus/contrast/Reduce Motion checks and gaps under DESIGN.md |
| Audio | If speech is included, the important alert is audible once and does not trigger voice commands. The visual state remains sufficient if room audio fails |
| Timing | Each of the last three consecutive successful runs fits the confirmed limit; include tab/role switches and any required text entry |
| Recovery | Rehearse a failed-send/disconnect drill outside the timed path; understand retained drafts and actual persistence limits |
| Backup | Play the recording end-to-end on the presentation machine, confirm audio/text legibility, and keep a directly accessible copy; label the build and communication mode |

Fallback ladder: if voice fails, use the touch control immediately. If the chosen transport fails, do not relabel it as connected; use the prepared, explicitly labeled local demonstration only if its reset/path has been rehearsed. For a core app/presentation failure, allow one brief recovery attempt of at most 10 seconds, then switch to the labeled backup recording and continue the same story. Practice the handoff so recovery does not consume the presentation.

If the core path is still incomplete at feature freeze, simplify the claimed demonstration to the working portion and label the remainder planned. Never fill an unimplemented state with hidden automatic acceptance, fake receipts or a fabricated successful record.

## 9. Owners, time gates and submission

No person is assigned by this document. Fill these roles when a person actually takes the work; the same person may hold multiple roles.

| Role | Current owner | Responsibility |
| --- | --- | --- |
| Integration owner | Unassigned | Track P0 slices, merge dependencies and identify the candidate commit/build |
| Presenter | Unassigned | Maintain factual narration, timing and fallback handoff |
| Device operator | Unassigned | Reset/setup, perform the exact primary path and run alternate checks |
| Evidence/deck owner | Unassigned | Keep screenshots, capability claims, credits and backup aligned to the candidate build |
| Submission owner | Unassigned | Verify organizer requirements, access, upload/submit, reopen final artifacts and record completion |

Recorded deadline: **Sunday, October 25, 2026, 12:00 PM CT**. Presentation duration is owner-confirmed at five minutes. Deck format, portal/repository visibility and required fields remain to be confirmed.

| Time gate | Required decision |
| --- | --- |
| Start of implementation | Claim F03 reusable content, then F24/F04/F06 and P0 storage; agree minimal setup/case fields, choose devices and assign responsibilities |
| At least 12 hours before deadline | Exercise ordinary setup/new-case/local support early; cut maps/camera/AI/extra template types/advanced administration and unproven voice/transport if behind |
| At least 6 hours before deadline | Freeze feature scope; choose the demonstrated communication/input mode from evidence; finish slide content and start final-build runs |
| At least 3 hours before deadline | Complete primary/alternate verification, record and test backup, finalize credits and fix only blocking defects |
| Final hour | Confirm required CI, final repo/artifact versions and submission access; perform authorized submission with time to verify it |

Submission checklist remains unchecked until performed:

- [ ] Five-minute timing rehearsed; deck format, deadline/time zone, required files/links and submission access confirmed.
- [ ] Blank setup, independent contact/two-case/input-change, save-error and relaunch tests passed; no seed-only behavior is presented as configurable product functionality.
- [ ] Final candidate commit/build identified; repository checks and iPad build/tests passed on that version.
- [ ] Critical proof and alternate checks have recorded results; no unresolved false-state or core-flow defect is concealed.
- [ ] Three timed successful runs and backup playback verified; actual communication mode is explicit.
- [ ] Final deck opens on the presentation machine; screenshots, diagrams and claims match the candidate build.
- [ ] Team names, credits and repository visibility/access meet the confirmed requirements; no generated project/local credentials were added.
- [ ] Authorized submission completed; reopen the submitted deck/repo links and record the completion time and confirmation.

## 10. Evidence record template

Copy this into the verification note when F19 starts; do not prefill a passing result.

| Field | Record |
| --- | --- |
| Commit/build and communication mode | Pending |
| Device/OS/window/display and settings | Pending |
| Operator/presenter and test time | Pending |
| Primary run 1 / 2 / 3 durations and results | Pending |
| Alternate checks and expected/observed results | Pending |
| Accessibility/layout/audio checks actually run | Pending |
| Evidence/backup locations and playback result | Pending |
| Open issue, severity, owner and resolution | Pending |
| Required CI and submission confirmation | Pending |

Keep this evidence with the release note/task completion, and update README/slides to match what actually passed. The immediate next implementation remains **F03** reusable template/seed content, followed by **F24/F04/F06**, guards/storage and normal setup/case flows.
