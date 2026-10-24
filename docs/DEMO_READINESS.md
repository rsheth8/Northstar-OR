# Northstar OR: presentation delivery plan

Planning review: **2026-10-24**, against `main` at `29d999f` plus the owner's implementation-plan edits. This document is a build/rehearsal contract. The app remains a starter; writing this plan does not establish that any gate has passed.

Use [PRODUCT.md](PRODUCT.md) for scope, [DESIGN.md](DESIGN.md) for UI requirements, [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) for F01–F23 dependencies, and [TASKS.md](TASKS.md) to claim work. Only simulated data is permitted.

## 1. What the audience should understand

**When travel disrupts technical coverage, Northstar helps a rural team choose a support plan, share the actual question and context, and keep unresolved work visible.**

Connect the prompt, *Connect & Intersect*, to behavior the audience sees: Planner intersects simulated skill/availability/travel constraints; the support flow connects people around one shared session record. Present this as the team's framing, not an official judging rubric.

The three destinations form one story: **coverage decision → explicit acceptance → team-reported progress → contextual question → human acknowledgment/reply → review**. Keep the same fictional case, named role, question and unresolved item throughout.

The presentation must make six things clear:

1. Why the coordinator needs a different support arrangement.
2. Which single plan is current, who accepted it, and which options remain unrequested.
3. What the team recorded and what remains deferred.
4. What the representative received and explicitly acknowledged.
5. How the reply and correction appear in the shared record.
6. Which communication mode is actually running and which extensions remain planned.

## 2. Scope that must stay fixed

- **Primary case:** fictional Grand Marais pacemaker coordination. Reset restores the same scenario offsets with a new session ID.
- **Planner context:** Worthington and Bemidji remain visible for ranking/browsing. They do not replace Grand Marais during this demonstration. The ICD row cannot launch the reused implant checklist.
- **Primary coverage path:** explicitly request Ana, then explicitly accept as the simulated rep. Marcus and Reschedule are visible choices and separately tested alternatives.
- **One current plan:** before commitment it is unset; after commitment it is one named-rep request or mark-to-reschedule. Backup options are unrequested candidates with truthful availability.
- **No Planner preparation checklist.** Put the effort into the decision, acceptance and handoff.
- **Primary input:** touch. Voice and cross-device communication enter the script only after their own gates pass.
- **Warnings:** required deferral pins that item. Confirmation, additional deferral and item switching are blocked. Support, read-only review and pinned-item correction remain available. Acknowledgment leaves it selected and deferred.
- **Support:** a real question, timestamped context snapshot, explicit question acknowledgment, and a reply visible in Co-pilot. A question may be sent before coverage acceptance; it does not silently commit a coverage plan.
- **Record:** review is in-memory until durable recovery is implemented and tested. Preserve original/corrected events and unresolved work.
- **Optional:** maps, camera, AI, rich attachments, video, additional active procedures and persistence are outside the required three-minute path.

## 3. Must-work proof matrix

All rows are **not yet verified** at this planning baseline. F19 records the actual results; a PR merge alone does not mark a manual gate passed.

| Proof | Implementation slices | Observable pass condition | Baseline gap |
| --- | --- | --- | --- |
| Explain the coverage problem | F03, F08, F11 | Grand Marais shows 110-minute travel versus closure in 90 minutes; logistical reasons and ranked secondary cases are readable | Matcher reasons/availability and decision UI need work |
| Commit exactly one plan | F04, F06, F07, F11, F12 | Ana is requested then explicitly accepted; Marcus remains unrequested. Reschedule and plan replacement pass alternate checks | No current-plan or acceptance model |
| Demonstrate the Co-pilot moment | F05, F09, F10 | Defer a required item, keep it pinned, request help while the warning persists, acknowledge without resolving it | Starter advances selection and lacks domain gate guards |
| Close the support loop | F06, F07, F12, F13 | Rep sees the exact question/unresolved snapshot, explicitly acknowledges it, replies, and Co-pilot displays that reply | No question/request/receipt state or prominent incoming reply |
| Show a trustworthy record | F04, F05, F14 | Review matches recorded states, retains correction history, and still names the deferred item | Text-only in-memory log; no correction/review flow |
| Look coherent on the presentation device | F01, F02, F09–F14 | Full intended viewport, calm shared styling, readable projected labels, reachable actions and keyboard-safe question entry | Viewport diagnosis, scaling and responsive feature layouts pending |
| Finish and recover on time | F03, F19, F20 | Three consecutive primary runs within the time limit, deterministic reset, failure drill and playable same-build backup | No rehearsal evidence, final script recording or submission evidence |

For each row record commit, device/OS/window, operator, date/time, result, evidence location and unresolved issue. A false confirmation/acceptance/delivery, wrong-session update, lost draft on the supported path, or hidden essential action blocks the corresponding readiness claim.

## 4. Implementation order that protects the presentation

1. **F03 first:** settle the fixture, exact recording labels, scenario clock/reset, visible ranking rows and supported active case. This locks the story and avoids reworking the script later.
2. **F04, then F05/F06, then F07:** introduce session/item/intent identities; implement pinned-warning invariants; represent current/superseded coordinator plans; connect the local request/accept/ack/reply flow. Each is a separate focused PR.
3. **F08:** fix pure matcher availability, reasons, stable ranking and explicit Reschedule candidate after the fixture is stable. Ranking must never commit a plan.
4. **F01/F02 in another checkout when available:** scalable text, meaningful contrast, control states and actual viewport diagnosis. These are required for final screen quality, but they are not the first claim.
5. **F09–F14:** connect Co-pilot, Planner, support composer/reply and review to the merged contracts. First make the touch journey complete; then verify changed layouts and failure states.
6. **F19/F20:** collect proof, rehearse, record and submit. Draft the deck/script from F03 instead of waiting for every screen to finish. Keep screenshots and capability claims provisional until the relevant build passes.

F15/F16 transport and F17 voice are conditional improvements with a time-boxed proof. A failed proof means using the labeled local/touch path. F18 recovery and F21–F23 camera/AI follow the core. Do not implement a new demo-mode subsystem, backend or animation just to make the presentation seem more complete.

## 5. Working three-minute script

The task board currently assumes **three minutes**. Confirm the organizer's actual duration, required deck format and submission process before finalizing assets. If the limit changes, retime and rehearse; do not silently add optional branches.

Keep one presenter and one device driver where staffing permits. On a single device, visibly switch the simulated OR/rep roles and retain the local-demo label. Do not describe tab updates as communication with a distant person.

| Time | On screen / operator action | Presenter point | Proof to leave visible |
| --- | --- | --- | --- |
| 0:00–0:20 | Problem slide with one fictional scenario | Travel disruption creates a coordination problem: who can support the team, and what context will they have? | No clinical-outcome or unsupported time-savings claim |
| 0:20–0:35 | Simple three-destination solution slide, then Planner | Northstar connects the coverage decision, workflow record and support exchange | Same fictional case identity |
| 0:35–0:55 | Planner: select Grand Marais, explain one reason, request Ana | Roads close in 90 minutes; the drive is 110. The coordinator chooses one technical-support plan | Ana requested; Marcus/Reschedule visible but uncommitted |
| 0:55–1:10 | Remote Support: explicitly accept Ana's invitation; return to Co-pilot | Availability becomes an accepted arrangement only when the recipient accepts | Named role, accepted state, actual communication mode |
| 1:10–1:50 | Record one confirmation; defer the agreed required item; request help while its warning remains; return and acknowledge | The item stays pinned and support remains accessible. Acknowledging the warning leaves the confirmation unresolved | Exact question sent; named item still deferred and selected |
| 1:50–2:15 | Rep view: show question/context, acknowledge the question and send a short technical-reference reply; return to Co-pilot | The rep joins with the team's actual question and unresolved context | Explicit question acknowledgment and incoming reply |
| 2:15–2:35 | Correct the earlier confirmed record, then open review | The record keeps what was originally reported, its correction, and the still-deferred item | Sources/times, original plus correction, unresolved count |
| 2:35–2:50 | Build/status slide | Explain the implemented transport, human-controlled records and demonstrated boundaries; identify optional extensions accurately | Tested capabilities separated from planned camera/AI/other work |
| 2:50–3:00 | Closing slide | Restate the coordination benefit and the next fictional workflow evaluation with users | A clear, factual closing point |

These windows total 180 seconds. Cut narration and transitions to fit; do not rush through the evidence. Keep the main run deterministic: Ana is the chosen path, and the operator triggers the deferral. Invite a judge to act only if the format permits and that interaction has been rehearsed.

Agree the exact required item and question in F03/F20. A suitable fictional question is “Which mock model reference should we use?” Any prefilled or clipboard question remains a visible, editable draft that the operator explicitly sends. No hidden acceptance, pre-sent message or pre-completed checklist should masquerade as a live action.

Keep one different confirmed item available for the correction moment; correcting it must not resolve the deliberately deferred item. The review must end with that unresolved work visible.

## 6. Slide/story map

This is a proposed six-slide outline, not a claim that a deck has been built or that six slides are required by the organizer. Use the current brand artwork and neutral typography; screenshots come from the final verified build.

| Slide | Purpose | Required content / constraint |
| --- | --- | --- |
| 1. Problem | Establish the user's coordination difficulty | One fictional site, a travel disruption, and the consequence of missing shared context. Avoid invented market/outcome statistics |
| 2. Product loop | Orient the audience before the live demo | Planner → Co-pilot → Remote Support → review; explain Connect & Intersect through actual constraints/communication |
| 3. Demo entry / standby | Transition to the app; remain available as a fallback | Same case and selected rep. If used as backup, label screenshots/recording clearly |
| 4. What connects it | Explain the implemented mechanism in plain language | Shared session, explicit actions, context snapshot and actual communication mode. An architecture illustration must match the build |
| 5. Evidence and limits | Make the demonstrated scope credible | Device/build, rehearsal result, meaningful failure check, simulated-data boundary, tested vs planned features. Populate only after F19 |
| 6. Next step and credits | Close with a specific continuation | Fictional walkthrough with OR staff/device reps, one learning goal, team names and required tool/library/asset credits |

Spend most of the presentation on the live journey. There is no requirement to read every slide or explain implementation details while an operator is taking an action. Optional camera/AI belongs on the future-work area unless its own tested slice is included in the actual build.

## 7. Alternate-path verification before rehearsal sign-off

These checks protect correctness but do not all need to appear in the timed presentation. Add automated state tests where applicable and capture manual UI evidence for the relevant screen.

| Check | Expected result |
| --- | --- |
| Unset plan → reschedule | Records a coordinator choice, no recipient acceptance, no claim that an external booking changed |
| Ana requested → Marcus requested → late Ana acceptance | Only Marcus's current request can become accepted; Ana's obsolete acceptance stays historical/stale |
| Accepted rep → reschedule → late rep event | Reschedule remains current; a stale event cannot restore the old arrangement or overwrite the header |
| Reschedule → new named rep | New request/plan identity; explicit new acceptance required |
| Unchosen backup | Visible candidate with truthful availability; no invitation/acceptance event until selected |
| Browse Worthington/Bemidji/ICD row | Planner selection changes; active Grand Marais session does not. ICD launch unavailable with an explanation |
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

Use the final candidate build, not a mixture of screenshots and behaviors from different commits. Record at least three consecutive timed successful primary runs on that candidate. Reset between runs and confirm the same case/forecast offsets with a fresh session ID. If a relevant code change lands after sign-off, repeat the affected checks and the timed-run sequence before updating the backup.

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

Recorded deadline: **Sunday, October 25, 2026, 12:00 PM CT**. Organizer-specific duration, format, portal/repository visibility and required fields are not supplied here; confirming them is a task, not an assumed checkmark.

| Time gate | Required decision |
| --- | --- |
| Start of implementation | Claim F03, agree fixture/plan/pinned-item semantics, choose actual devices and assign integration/presentation responsibilities |
| At least 12 hours before deadline | Integrate enough of the local core to rehearse; cut optional maps/camera/AI/extra active cases and unproven voice/transport if behind |
| At least 6 hours before deadline | Freeze feature scope; choose the demonstrated communication/input mode from evidence; finish slide content and start final-build runs |
| At least 3 hours before deadline | Complete primary/alternate verification, record and test backup, finalize credits and fix only blocking defects |
| Final hour | Confirm required CI, final repo/artifact versions and submission access; perform authorized submission with time to verify it |

Submission checklist remains unchecked until performed:

- [ ] Actual presentation time/format, deadline/time zone, required files/links and submission access confirmed from the organizer's requirements.
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

Keep this evidence with the release note/task completion, and update README/slides to match what actually passed. The immediate next implementation remains **F03**, followed by the separate shared contracts/state PRs.
