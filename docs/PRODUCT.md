# Northstar OR: product direction

This brief records the agreed direction. It is a design plan, not a claim that every feature is implemented. See the README for current status and TASKS.md for ownership.

The approved visual and interaction rules are in [DESIGN.md](DESIGN.md). Use its screen contracts, accessibility targets, and review evidence alongside this brief. [The UX delivery order](TASKS.md#ux-delivery-order) turns that direction into small implementation tasks.

[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) expands the current starter into state contracts, screen specifications, PR dependencies, verification gates, and a staged continuation beyond the hackathon. It does not broaden these product boundaries or mark proposed work as shipped.

[DEMO_READINESS.md](DEMO_READINESS.md) defines the presentation-critical proof, timed primary path, alternate checks, rehearsal and submission gates. Start implementation with the fictional fixture and shared state contracts; shared visual work can progress in a separate checkout.

## Purpose and users

Help a rural OR team coordinate technical support, maintain shared workflow context, and hand off information when weather disrupts the usual support arrangement.

The initial users are a coordinator arranging coverage, an OR team member recording confirmations and requesting help, and a remote device representative providing technical support. Clinical specialists are a distinct role; availability of a device rep must not imply clinical coverage.

Every feature must answer: whose work does this make easier, at what moment, and how will we demonstrate that it worked?

## Product boundaries

- Fictional people, facilities, records, forecasts, and training materials only. Keep simulated records in `NorthstarOR/Data/`.
- The app prompts and documents. It does not diagnose, recommend treatment, verify surgical technique, or decide whether a procedure can proceed.
- Checklist content must be reviewed for the specific workflow. AI must not invent procedure instructions.
- A team statement, camera observation, and AI draft are different sources of information. Preserve that distinction in the interface and log.
- Acknowledging a warning does not complete the underlying item. An unseen event is unknown, not proof that a step was skipped.
- Remote support supplements coordination; a disconnected service or unanswered request must remain visibly disconnected or unanswered.

## The experience we intend to build

### Before the procedure: choose a coverage plan

Planner shows the selected fictional procedure, device family, logistical coverage risk and reasons, named support options/roles, and one current coordinator plan. The coordinator can request one named rep or mark the case to reschedule. Other eligible options remain visible as unrequested backups. There is no Planner preparation checklist in the presentation scope.

Coverage Matcher ranks logistical options for human review, including Reschedule where applicable; it never commits a plan. "Can support remotely" is a capability, not acceptance of a particular case. Track request, acceptance and connection separately. Marking to reschedule records a human coordinator's planning choice without rep acceptance or a claim that an external booking changed. Replacing a plan supersedes its request; a late acceptance cannot reactivate the old plan.

### During the workflow: capture explicit confirmations

Co-pilot shows current context and unresolved items with large touch controls and optional explicit voice commands. Support unrecorded, deferred, and team-confirmed items, with corrections and a visible history. Do not infer task completion from ambient conversation.

Use short, purposeful alerts. A pending required acknowledgment pins the item just deferred and blocks confirmation, further deferral, and item switching through every input path. Support requests, read-only review and explicit correction of that pinned item remain available. Acknowledgment leaves the item selected and deferred; later navigation is explicit. Outside that gate the team controls navigation rather than following a universally fixed sequence.

### When help is needed: request it with context

Allow a team member to request support at any time, even if nothing is marked skipped. Include the team's actual question, current workflow context, unresolved items, relevant recent events, and deliberately shared evidence.

Show the recipient, role, request state, and acknowledgment. Do not equate sending a request with receiving a response. Surface incoming messages prominently. Use `SyncService` for cross-device/backend communication.

### After the session: review the record

Prepare a reviewable summary of confirmations, deferred items, corrections, support exchanges, and automated observations. Keep sources and timestamps visible. "Checklist complete" describes checklist state; it does not certify the procedure or clinical outcome. Decide durable storage and export scope in a separate implementation task.

## Camera and AI: narrow jobs with visible evidence

Neither camera analysis nor conversational AI is currently implemented. Do not pitch them as working until the end-to-end behavior is demonstrated.

### First camera use case

On a mock device label, capture a frame, extract a fictional model number, compare it with the simulated case record, and display the image, extracted text, and proposed match. Ask a person to confirm or correct it. Record the observation separately from the human confirmation.

If the frame is unreadable or the object is not visible, report "Unable to determine." Do not automatically complete a checklist item. A label match does not establish sterility, correct placement, or clinical suitability. A camera preview, sharing video with a person, and interpreting images are separate implementation capabilities.

### First conversational AI use cases

- "What confirmations are still unresolved?"
- "What changed since the rep joined?"
- "Draft a handoff for the rep."

Ground answers in recorded session events and identify missing information. Label generated handoffs as drafts and review them before sharing. Explicit workflow commands should use controlled actions; free-form model output must not silently mutate checklist state. Keep voice commands usable without the conversational service and show when AI is unavailable. Any remote service integration goes through `SyncService`; choose and credit the provider in its implementation PR.

### How to evaluate the prototype

Use independently labeled fictional examples for readable, unreadable, mismatched, and absent labels. Record false matches, missed observations, and response delay rather than claiming general accuracy. Test voice in noise, duplicate recognition results, unavailable permissions, corrections, and interrupted connectivity. Verify AI summaries preserve unresolved items and never invent completion or receipt of a message.

## Supporting multiple procedures

Reuse the coordination framework: support requests, explicit confirmations, observations, messages, and review. Give each supported procedure its own reviewed fictional workflow, device requirements, support roles, and references.

Start with one coherent Grand Marais pacemaker demonstration. Keep Worthington and Bemidji in Planner to demonstrate ranking and case browsing, without changing the active Co-pilot session. The current ICD generator-change example reuses implant steps; its Planner row must not launch an active checklist or imply a reviewed generator-change workflow. Broad autonomous recognition across procedures is outside the hackathon scope.

## Intended demonstration

1. A fictional Grand Marais hospital has a case in eight hours. Roads are expected to close in 90 minutes; the qualified rep is 110 minutes away.
2. Planner explains the coverage risk and retains visible unrequested backup options. On the primary presentation path the coordinator requests Ana; she explicitly accepts. Verify Marcus/reschedule/plan replacement separately.
3. The OR view reflects the support arrangement. A team member records progress with voice or touch.
4. A fictional required confirmation is deferred. Co-pilot pins that item, displays and speaks a short alert, and still allows a support request. Acknowledgment leaves the item selected and unresolved.
5. While the warning remains, the team sends its question with current context, then acknowledges the warning without resolving the item. The rep explicitly acknowledges the question; a reply appears prominently in Co-pilot.
6. If implemented and tested, capture a mock label and confirm its proposed match. If AI is implemented, request a session-grounded handoff draft and review it.
7. Review the session record, including unresolved items and information sources.

For the current starter, support interactions only work between tabs on the same app instance. Use that honestly until cross-device sync is implemented. Keep a reliable touch-based demo; camera and AI are additions after the core support journey works.

## Design grounding and remaining validation

These are product hypotheses requiring feedback from OR staff and device reps, not a validated clinical workflow. WHO emphasizes local adaptation and multidisciplinary involvement in checklist implementation. AHRQ emphasizes receiver acknowledgment and opportunities for questions in handoffs.

- [WHO checklist implementation guidance](https://www.who.int/publications/i/item/9789241598590)
- [AHRQ TeamSTEPPS handoff guidance](https://www.ahrq.gov/teamstepps-program/curriculum/communication/tools/handoff.html)

Before broadening scope, review a fictional walkthrough with an OR nurse and a device rep. Ask what interrupts them, what information they need when joining, and which confirmations this app should capture. Do not collect real case data for this prototype.
