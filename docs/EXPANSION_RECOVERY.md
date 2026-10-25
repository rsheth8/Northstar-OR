# Product expansion recovery — October 25, 2026

Recovery began from merged `main` at `b57383f` after the owner reported that the partner agent exhausted its usage mid-implementation. Preserve the existing PRs and their authorship; use isolated checkouts and append ordinary commits, without rewriting the partner branches. This is an implementation inventory, not release sign-off.

## What reached main before recovery

- #47/#48: native nearby Mac/iPad shared sessions, retained messaging, contextual support and calls alongside the workspace. Earlier owner-confirmed basic audio/video evidence remains valid; no new physical-device claim is made here.
- #51: persisted, revisioned fictional planning evidence; migration of legacy forecasts; matcher consumption of saved evidence. Normal evidence editing and graphs did not ship with this contract.

## Expansion inventory

| Roadmap area | Existing implementation | Remaining work |
| --- | --- | --- |
| 1. Shell/recovery | #53 deliberate device-role switching, reduced chrome, persistent save error | Complete visual/accessibility verification; role-change and link interruption walkthrough |
| 2. Forms | #53 labels, discard guards, nested contact save preservation, date-specific time-zone names, optional fictional coordinates | First-error focus; comprehensive dismissal/save-failure UI proof |
| 3. Worklist | #52 recording and site-local-day filters, independent selection, empty actions | Site scope/day grouping; integrate explicit ended lifecycle; larger-text and narrow-window proof |
| 4. Co-pilot/support/review | #53 question-first recipient flow; #54 growing workflow tiles/current-item priority and unresolved-first review; #56 explicit recording end/reopen domain contract | End/reopen controls after contract merge; integrated question/ack/reply, correction, keyboard and call-access proof |
| 5. Coverage plans | #55 versioned requests/responses, retained history, exact-mode/revision guards, receipts/retries | Planner request/replace/reschedule controls and recipient accept/decline controls; physical two-device proof |
| 6. Planning evidence/map | #51 shared evidence; #52 native recorded-site map/list; #53 coordinate editing | Normal evidence editor; offline map/Catalyst/attribution checks; evidence applicability/staleness review |
| 7. Weather/timeline | #52 summary screen; recovery connects it and reports to the same evidence revision as matcher | Recorded hourly graph/table and travel/case/explicit-closure projection; no fabricated hourly weather |
| 8–9. Voice | #54 exact vocabulary, final-only recognition, captured mutation previews, explicit touch commit, interruption guards | Integrated automated checks; actual permission/audio/quiet/noisy-device evidence. Parser tests do not validate microphone behavior |
| 10. Reports | #52 frozen, case/session-isolated text report with explicit sharing; recovery retains evidence revision/source | Current coverage-plan snapshot, paginated export/accessibility proof and any later operational metric definitions |
| 11. Release proof | Existing core/native baselines; focused recovery checks | One integrated candidate, blank setup/two independently created cases, relaunch/failure/accessibility and physical rehearsal |
| 12. Later projects | No implementation claimed | AI, camera interpretation, extra templates, coverage what-if and internet/verified identity remain separate projects |

## Concrete recovery defects

1. #53 could not compile: `WorkspaceContractError.invalidCoordinates` requires a site ID. Pass the validated site's identity and inject deterministic generated IDs in the regression test.
2. #55 conflicted with #51 in AppModel/repository snapshots. Preserve both coverage plans and planning evidence in construction, validation and decoding. Add a regression saving both, relaunching, and editing evidence without losing the plan.
3. #52 displayed/reported the legacy forecast dictionary while matcher consumed saved revisions. Use the authoritative evidence projection and freeze its revision/source in reports.
4. #52's enlarged-text test assumed a lazy case row existed before scrolling below the new filters. Give the worklist a stable identifier and verify the row can be revealed and tapped.
5. #50's task-board conflict pitted the planning claim against the approved implementation claim. Preserve both; no implementation becomes complete merely because the roadmap exists.
6. The #53 largest-text capture exposed overlapping device-action labels. Let their horizontal row measure its full width, fall back to stacking, and use the shared supporting font.

## Next delivery order

First finish and integrate the existing focused PRs through their required checks. Build coverage-plan screens only against merged #55 and lifecycle controls only against merged #56. Then add the normal planning-evidence editor and weather/timeline consumers in separate PRs. Run the integrated fictional journey and document physical voice/call limitations before calling the expansion finished. Do not mark the twelve roadmap tasks complete based on this recovery inventory.
