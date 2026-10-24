# Northstar OR: configurable product foundation

Owner clarification, 2026-10-24: the presentation is **five minutes**, and Northstar must work as a configurable app beyond its prepared story. This document supersedes the earlier script-only minimum, single seeded-case restriction, and optional persistence target. It is planned work, not shipped functionality.

Keep [PRODUCT.md](PRODUCT.md)'s simulated-data and coordination-only boundaries. A configurable evaluation build lets a person set up fictional facilities, contacts and cases using normal app controls. Institutional deployment with real data remains a separate evaluation and operational program; do not describe a local role picker as authentication.

## 1. The product test

**Could someone start with an empty installation, configure a fictional facility, create two different cases, use the normal support workflow, close the app, and resume the correct records without editing source code?**

That is a required product acceptance test. The Grand Marais story is a sample dataset passing through the same forms, storage and domain actions. It must not unlock behavior unavailable to newly created cases.

- A blank workspace and an optional sample workspace are both supported entry paths.
- Case/recipient names, a particular location, array index zero, a storm, and a particular tap order never determine which features work.
- Multiple case records are supported. One session is displayed/controlled on the OR device at a time; selecting a different row in Planner does not change it implicitly.
- Configuration, records and drafts survive a tested app relaunch. An explicit sample reset affects only the selected sample workspace and never runs automatically on launch.
- Empty, invalid, missing, unavailable and disconnected states are normal product states with an available next action.

## 2. Setup and ongoing administration

Keep the three main destinations: Planner, Co-pilot and Remote Support. Add a modest **Workspace settings** entry in the shell; setup and configuration do not require a fourth main tab.

| Area | Minimum functional scope | Guardrail / acceptance |
| --- | --- | --- |
| First launch | Choose “Set up workspace” or explicitly “Load sample workspace” | Do not silently select a sample case. Explain fictional-data-only scope in calm supporting copy |
| Facility/workspace | Fictional display name, site/location label, time zone and optional room labels | Save/edit through normal controls; stable IDs survive renaming; no real hospital or patient records |
| Local participant | Fictional display name and stated coordinator / OR team / technical rep role | Label local role selection honestly; roles do not assert verified identity, credentials or permissions |
| Support directory | Add/edit fictional contact, technical role, device-family capability, availability, remote capability and simulated travel estimate | Unknown travel is unknown; unavailable contacts cannot become the available default. Editing a name does not reassign old events |
| Workflow catalog | Select one supported, versioned fictional coordination template; inspect its applicability and content source | Initially one pacemaker coordination template can support many cases. Unsupported ICD content remains unavailable; do not invent instructions for another procedure |
| Communication | Show actual mode, available recipient/peer and state; explain missing connection | “On this device” for local-only exchange; connection labels require transport evidence. No decorative “Live” label |
| Workspace maintenance | Edit configuration, inspect app/mode information and explicitly reset sample content | Never clear another workspace or session incidentally; persistence failure is visible |

Setup fields are administrative configuration. They are not the removed Planner preparation checklist. Keep setup short and editable later. Provide field-level validation, Save/Cancel, dirty-draft handling and a clear result; do not replace actual configuration with a decorative onboarding slideshow.

Seed fixtures stay in `NorthstarOR/Data/`. Runtime-created fictional configuration and records are persisted inside the app's normal sandbox through the storage service; they are not written back to source files. No new clinical identifiers, diagnoses or patient fields are required for this product slice.

## 3. Create and manage cases

Planner gains a real **New case** action. Required fields are fictional case reference/title, selected configured site, scheduled date/time with time zone, estimated logistical duration, compatible device family and a supported coordination template. Validate missing fields, impossible durations, duplicates and incompatible templates. A support recipient can be chosen later; an empty directory does not prevent saving a case.

Store absolute scheduled times. Forecast/travel inputs remain clearly simulated, carry an as-of time, and can be absent. Ordinary scheduling and remote-support requests must work without a storm. Missing forecast must not turn into invented weather, certain travel or a claimed accepted plan.

The worklist shows cases with sortable/filterable schedule, site, device family, logistical risk/unknown reason, current plan and recorded session state. Use real state projections; do not invent analytics or a numerical readiness score. Start with useful date/status filtering and selection; advanced search, drag scheduling and charts are later scope.

Each case supports one current coordinator plan: unset, named-rep request, or mark-to-reschedule. Preserve the previous plan and protect against late obsolete acceptance. Reschedule records a coordinator's intent and does not update an external booking automatically.

“Start recording” creates a session from the selected case's pinned template version. “Resume recording” restores that case's existing session. An explicit active-case switch preserves the previous case and unsent drafts; it cannot clear a pending acknowledgment or silently change its selected item. Browse other cases freely while that acknowledgment is pending; acknowledge/correct the pinned item before changing the active recording context.

Session lifecycle describes the app record: not started, recording, recording ended/reviewable, archived if implemented. It must not assert that a clinical procedure started, ended or was successful. Ending a recording may retain unresolved items and must say so.

Editing schedule/site/support inputs changes planning data explicitly; it does not rewrite historical snapshots or the workflow content of an existing session. Archive is preferable to deleting a case with records. Unsupported deletion/export behavior remains unavailable rather than pretending a record was removed or transmitted.

## 4. Shared models, storage and integration

Extend the existing architecture in small PRs; do not build an enterprise platform during the hackathon.

| Contract | Proposed responsibility |
| --- | --- |
| Workspace / site | Stable ID, fictional names, time zone, optional rooms and configuration version |
| Participant / support contact | Stable ID, stated role, capabilities and availability; distinguish local display identity from later authenticated identity |
| Coordination template | ID/version, applicability/device family, reviewed fictional items, content source and supported state |
| Case | Workspace/site IDs, fictional reference, schedule/duration, device family, pinned template version and current plan identity |
| Session | Unique session ID, case/workspace IDs, lifecycle, independent selection/item status, events, support exchanges and pending acknowledgment |
| Repository / store | Load/save workspace, contacts, cases, sessions and drafts; observable write errors; schema version and bounded recovery |
| SyncService | Actual transport, submission/receipt outcomes and connection state; shared events carry workspace/case/session/plan IDs as relevant |

Move `AppModel` away from unconditional `SampleData` initialization and `procedures[0]`. Inject the repository and optional seed factory; represent “no workspace,” “no case,” and “no active session” explicitly. Preview/test fixtures remain convenient dependency choices. Views do not own independent shadow copies of the record or talk directly to storage/network SDKs.

F18 becomes **P0 persistence**, beginning with a small local store for one configured fictional workspace, its contacts/cases/sessions and drafts. Use a versioned format, atomic writes and an injectable store for tests. A failed write must not display “Saved”; preserve the unsaved draft/state and expose retry. Unsupported/corrupt data must not trigger silent reset or overwrite. Exact file-format implementation is decided in that PR; no new dependency is selected here.

Checklist/plan/message commands retain the existing ID, source, version and duplicate guards. Persist their accepted state consistently with the event/receipt record. On restore, pending messages require reconciliation; restore no unproven delivery or connection state. Bounded local persistence is not an institutional audit, backup or access-control system.

Keep workspace/case/session IDs on queries and events even if the first build has one configured workspace. Test with different workspace IDs to catch leakage. Concurrent multi-writer editing, multi-hospital server administration, verified accounts, SSO, real notifications, EHR integration and production operations are separate work.

## 5. New slices and dependencies

These extend the existing IDs rather than renumbering active references. All are pending. F03 remains the first implementation claim, now creating reusable seed/template content and a factory rather than constraining the app to a presentation-only case.

| ID | Priority / folder owner | Depends on | Deliverable / meaningful acceptance |
| --- | --- | --- | --- |
| F24 | P0 / shared Models | F03 content agreement | Workspace/site/contact/template/case contracts. Stable IDs, pinned template version, validity rules and Codable round trips; no patient schema |
| F18 | P0 / Services and shared state | F24, F04, F06 | Repository/local store and relaunch restoration; save failure, corruption, schema mismatch, draft and pending-send tests. Can precede final review UI |
| F25 | P0 / setup UI and shared shell | F01, F02, F24, F18 | Blank-workspace setup/settings, explicit sample loading, recoverable validation and retained setup; no implicit sample overwrite |
| F26 | P0 / workspace directory UI | F25, F24, F18 | Add/edit contacts and capability/availability; names/IDs propagate through ordinary support selection; no hard-coded sender |
| F27 | P0 / Planner case form | F25, F24, F04, F18 | Create/edit two fictional cases from one supported template; invalid/incompatible input blocks save; new case works without sample IDs |
| F28 | P0 / Planner and session orchestration | F27, F05, F07, F11, F18 | Worklist/filter, explicit start/resume, preserved context and session history; switching/relaunch cannot mix or erase cases |

F04 includes workspace/case identity after F24; F07 uses repository-backed state; F08 accepts arbitrary configured inputs; F11 and F12 read configured contacts/cases; F14 reads retained session events. F19 adds blank-start and second-case proof. F20 rehearses the normal product, including setup, over the confirmed five-minute window.

Shared contracts/storage land before dependent forms. Keep each PR focused; split setup, sample loading or directory changes if a review grows too large. Add a `Features/Workspace/` folder for setup/settings/directory UI; keep shared orchestration and persistence in their own PRs. No new agents or concurrent writers are authorized by this lane description.

## 6. Product acceptance, beyond a scripted run

- [ ] Clean install can set up a fictional workspace and save it without loading Grand Marais.
- [ ] User can create/edit a fictional support contact and select that contact through the standard support flow.
- [ ] User can create two cases with different names/times/sites using a supported template; neither requires seed IDs.
- [ ] A newly created case supports the same plan, warning, question/ack/reply, correction and review behavior as a sample case.
- [ ] Changing an input has a real effect: unavailable support is handled truthfully; edited schedule/travel changes matcher reasoning; missing forecast remains unknown.
- [ ] Case browsing does not change the active session; explicit start/resume preserves each case's record and respects a pending acknowledgment.
- [ ] Relaunch restores configured workspace, cases, recorded state and drafts; it does not reload seed content or recreate acceptance automatically.
- [ ] Save failure/corrupt input has a recoverable, visible outcome; sample reset is explicit and scoped.
- [ ] Empty worklist, no contacts, no selected session and unsupported workflow all have useful next actions.
- [ ] Actual communication mode and local role identity remain honest; local persistence is never presented as distant delivery or verified institutional access.

Use at least one independently named case/contact and an input change chosen during verification, not only the presentation's prepared values. These tests are the evidence that the app is reusable.

## 7. Capacity and cut lines

This is a real scope increase. The prior 22–38 person-hour estimate covered a narrower in-memory journey; it no longer describes the revised target. Workspace/case contracts, storage and setup/forms add a rough **10–18 person-hours**, giving **32–56 person-hours** before optional transport/voice. These are planning ranges, not a deadline promise; re-estimate after inspecting each slice.

Protect a minimal functional setup, ordinary case creation, persistence, core support loop and clean institutional UI. Reduce configuration breadth to one workspace, a small directory and one supported template first. Cut advanced analytics, maps, video, rich attachments, arbitrary workflow editing and camera/AI before cutting product repeatability. Do not save time by hard-coding names or a tap sequence.

If this complete target cannot pass before submission, show the implemented subset with accurate boundaries and label the missing setup/recovery capability. Five minutes increases presentation space, not engineering capacity or evidence of hospital deployment.
