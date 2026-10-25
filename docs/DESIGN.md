# Northstar OR: UI and UX rules

The approved direction is a calm, precise workspace for institutional medical teams. Professional quality comes from readable information, consistent controls, explicit state, and dependable recovery. These are implementation and review requirements; the starter does not meet all of them yet. Product scope and clinical boundaries remain in [PRODUCT.md](PRODUCT.md).

This is the canonical product design guide. [The brand kit](brand/README.md) governs artwork; [TASKS.md](TASKS.md#ux-delivery-order) governs implementation order and ownership. Changes to shared components, state, and feature screens ship in separate small PRs.

[DESIGN_REFERENCES.md](DESIGN_REFERENCES.md) records the public medical-software examples inspected and our resulting decisions. The target is a clinical operations workspace: aligned case worklists, persistent context, task-focused controls, quiet statuses and retained records. Optional AI drafts stay secondary. Reference products inform hypotheses; Northstar earns its usability claims through its own task-based testing.

## 1. The design bar

Every screen must make the active fictional case, current work, unresolved items, and support arrangement easy to identify. The next action must be explicit, and the result must remain visible after it is taken.

- Keep one clear visual priority per work area. Use structure and spacing to create hierarchy.
- Preserve context when switching tabs, opening details, receiving a message, or recovering from an error.
- Represent recorded facts, unknown information, and pending human responses distinctly.
- Pair meaningful status with a label and icon. Color, sound, animation, and position alone are insufficient.
- Keep the team in control. Recording an item, acknowledging a warning, requesting support, and receiving support are separate actions.
- Keep decorative illustration in presentation material. The product uses the connected star/pulse signature and neutral wordmark.
- Make the app usable from a blank workspace. Actual setup/forms, clear empty states and save/relaunch behavior are part of professional quality; a prepared case is optional sample content.

This guide sets a professional design target. It does not establish clinical readiness or replace the workflow feedback described in PRODUCT.md.

## 2. Visual system

Owner-approved revision, October 24, 2026: a light hospital-worklist environment with a slim midnight-blue application header supersedes the earlier dark-first direction. Modernity comes from alignment, typography, information density, restrained branding and predictable actions. The refined Planner image is a visual concept, not evidence of implemented behavior, contrast or target sizes. Its placeholder mark and invented content must not replace approved assets or fictional templates.

The migration is staged: reconcile this guide → shared light tokens/components → shell/viewport → Planner reference screen → Co-pilot and Remote Support. Domain dependencies in TASKS.md still apply. `Northstar.Palette.Workspace` supplies the light tokens; compatibility `Palette` names and shared controls now adopt those pairs. Feature layout migrations follow separately. See [the handoff](LIGHT_WORKSPACE_HANDOFF.md).

Use `Northstar.Palette`, `Northstar.Fonts`, `Northstar.Space`, and `Northstar.Radius`. Add a reusable token or component in a shared-files PR when needed; avoid per-screen styling systems and raw hex values in views.

| Element | Rule |
| --- | --- |
| Surfaces | Soft off-white working background, white content and subtly differentiated neutral sections; slim midnight-blue header. Use aligned rows, spacing and dividers instead of floating cards. |
| Type | Neutral system typography in the app. Regular body text and semibold emphasis; monospaced digits for case references, timers and compact timestamps where useful; proportional text for descriptions and activity. Inter Display remains the outlined logo wordmark. |
| Base sizes | Body 17 pt; supporting metadata at least 13 pt; section title 24 pt; current-item title 32–40 pt. These are default-size starting points, with Dynamic Type scaling. |
| Spacing | Use the existing 4 pt spacing scale. Start with 24 pt work-area padding and panel gaps, and 16 pt internal grouping; adapt to available space. |
| Corners | Existing 6 / 10 / 12 pt radii for small / medium / large containers and controls. Rounded geometry supports grouping without dominating the screen. |
| Buttons | Flat deep-blue primary fill, quiet outlined or text secondary actions, visible pressed/disabled/focused states. Green marks recorded results. Preserve 72 × 72 pt primary targets without making every action full width. |
| Icons | Consistent SF Symbols with text for consequential actions. Expand the hit area independently of icon size. |
| Logo | Use current files from `docs/brand/`. Keep the mark modest in the app header. Preserve its proportions and connected trail. |
| Motion | Brief state transitions, normally 100–200 ms. Respect Reduce Motion. System navigation may retain its native transitions. |

Product screens must not reintroduce glowing buttons, oversized rounded display type, decorative gradients, bouncing controls, animated mascots, an “alive” voice orb, repeated pulsing, or flashing screen borders. Functional microphone feedback may show input activity alongside a readable listening state.

### Color has a job

For migrated screens, use the corresponding semantic `Palette.Workspace` tokens: `canvas`, `surface`, `surfaceSubtle`, `text`, `textSecondary`, `header`/`onHeader`, `selection`/`selectionIndicator`, `action`/`onAction`, and the named status foreground/surface pairs. Header text must use header-specific colors. Blue selection includes a narrow rail and selected accessibility state; selection is independent of recording status. Legacy names below retain their semantic meanings during migration.

| Role | Token / meaning |
| --- | --- |
| Main information | `ink`; use `inkMuted` for supporting information that remains readable. |
| Selection and information | `ice`; selection also needs an indicator or label. |
| Recorded confirmation / successful action | `aurora`, with a checkmark and explicit result. Green must not imply clinical safety or procedure readiness. |
| Attention / deferred or unresolved item | `amber`, with a named condition and available action. |
| Failure / blocked app action / destructive action | `alert`, with an explanation. It must not become a clinical instruction to stop or proceed. |
| Dividers and decorative structure | `line` and `slate`; do not assume these have enough contrast for essential control boundaries or status icons. |

Coverage risk describes logistics. Label it “Coverage risk” and show its reasons; it is distinct from clinical risk, checklist state, and connection status.

## 3. Layout and navigation

The primary demo is a landscape iPad. Layout must respond to the actual window width, safe areas, text size, and keyboard. Preserve functionality when panels stack or move into detail views. Apple's [layout guidance](https://developer.apple.com/design/human-interface-guidelines/layout) supports this adaptive approach.

- Use a slim midnight identity strip and native SwiftUI tab navigation, with native light toolbars for destination actions. The owner approved this iPad-native refinement after the initial custom navigation mockup. Do not hard-code bottom tab placement: system placement follows iPadOS. The header shows the existing connected-star identity, configured workspace, actual communication mode and Workspace settings. Let it wrap or rearrange at enlarged text; slim is not a fixed-height clipping rule. Native iPadOS 17+ navigation behavior and accessible window adaptation take precedence over literal mockup placement.
- Keep the three destinations recognizable: **Co-pilot**, **Planner**, and **Remote Support**. Use familiar native navigation and selection behavior.
- On first launch offer real workspace setup or explicit sample loading. Restore the configured worklist on later launch; provide Workspace settings in the shell. Do not silently open/reset an array-zero sample session.
- Show consistent active-case context and support status across destinations. Make an intentional case change explicit; preserve selection when switching tabs.
- Keep case identity, unresolved-item count, and support availability visible while working. Until cross-device delivery exists, label the actual mode as a local demo.
- If no session exists, show the actual empty state and a case-selection/start action rather than invented progress. Use an honest communication label such as “On this device”; identity/connection verification requires implemented evidence.
- Give the current task the most space. Avoid a tiny task panel between rigid sidebars or a large empty presentation-style canvas.
- In Co-pilot, use progress / current work / recent activity columns only when the current work area can remain at least 360 pt wide. Otherwise move secondary history into a labeled panel or stack the regions. Keep warnings, current actions, and support access reachable.
- Grow rows and controls for wrapped text. Essential labels, recipients, questions, and warnings must not be clipped or reduced to unreadable text.
- Keep message entry and its send action visible above the keyboard. Do not lose a draft on a failed send or ordinary navigation.
- Verify the app's viewport on the intended iPad before adding visual polish. Diagnose unexpected letterboxing, overflow, and unused space rather than treating them as the intended layout.

## 4. Screen contracts

These describe the target experience, including behavior still pending in TASKS.md. Show only states the implementation can actually support.

| Destination | Information priority | Essential interaction and result |
| --- | --- | --- |
| Co-pilot | Active case and facility → named support arrangement and connection → current item and unresolved items → recent activity | Record a team confirmation, defer with context, acknowledge when required, correct a record, and request support at any time. Each action leaves a visible, timestamped result. |
| Planner | Case worklist/filter and New case → selected case/risk reasons → named options/roles → one current plan/backups | Create/edit a compatible fictional case, commit one named-rep or reschedule plan, and explicitly start/resume its record. Backups stay unrequested. No preparation checklist. |
| Setup / Workspace settings, secondary flow | Fictional site/time zone → local participant and support directory → supported template selection → communication mode | Save/edit actual configuration with field validation and retained state; optional sample loading is explicit. This is not a fourth primary tab. |
| Remote Support (join brief) | Team's exact question with sender/role/time → case header (reference, site, device family, template version, communication mode, snapshot time) → unresolved now → recorded so far → coverage plan and recorded logistical reason → changes since request | Read the context without asking the team to explain it, acknowledge the question, reply with technical support, and show the request → acceptance → question acknowledgment → reply chain as separate states. Make incoming responses prominent in Co-pilot too. |
| Session review, when implemented | Session identity → unresolved items → recorded confirmations/corrections → support exchanges → sources and times | Review the record. Use “Checklist complete” only for the relevant recorded checklist state, with any unresolved items still visible. Export is a separate scoped task. |

### Planner reference layout

Use a two-pane worklist/detail layout when the actual window permits it. The left region contains date/status filters, New case and rows prioritizing case reference, schedule, site and plan state. Recording lifecycle has its own labeled field; it must not be merged into plan state. Selected rows have a pale-blue fill and narrow blue rail; rows grow for touch and wrapping. Browsing a row never switches the active recording context.

The detail order is: case reference and template/procedure label with Edit case; site, schedule/time zone, template version and recording state; coverage assessment with logistical reasons; current coordinator plan with named contact/role and actual request state; other eligible options labeled unrequested; explicit Start recording or Resume recording. Use aligned fields and flat divided sections. Keep warnings localized to coverage or the affected item. Narrow layouts navigate between list and detail without losing selection or drafts.

### Co-pilot and recipient layout

Owner-selected Focus layout: at wide sizes Co-pilot uses a horizontal workflow strip above the dominant current-item area and a persistent contextual support panel on the right. Recorded activity sits below the current work. Stack support below current work at narrow or enlarged-text sizes; preserve the 360 pt current-work minimum above. The full workflow remains available for review. Show item title/context, recorded state, pending acknowledgment, permitted recording/correction actions and Request support. Use a persistent warning beside the affected item. Acknowledgment leaves the pinned item deferred; support, read-only review and permitted correction remain available.

Remote Support places question acknowledgment beside the exact question, sender and time. Conversation and reply entry sit alongside or below the request brief; the draft and Send remain above the keyboard. Request acceptance, question acknowledgment, delivery and connection each retain their own supported state.

The Remote Support join brief answers a remote rep's first questions before they ask: what the team needs, which case, what is unresolved, what has been recorded and why support is remote. It is built from the immutable request snapshot; later events appear under a labeled “Changed since request” count rather than silently updating the brief. Missing values read “Not recorded” or “No question from the team yet”; an empty deferral list reads “No deferrals recorded.” Unrecorded items remain unresolved; a no-unresolved summary requires every applicable item to be confirmed. The brief states recorded facts only and never says ready, safe or proceed. In narrow windows stack the regions while keeping the question and Acknowledge question reachable.

Use one dominant next action in the current work area. Keep support and correction actions available without giving every control the same filled emphasis. The progress rail allows team-controlled navigation outside a pending required acknowledgment. That gate pins the deferred item; support, read-only review and its explicit correction remain available. It does not imply a universal clinical sequence.

## 5. State must be truthful

| Domain | Required distinction | Presentation rule |
| --- | --- | --- |
| Checklist item | Unrecorded / deferred / team-confirmed; current selection is separate | Required deferral pins that item while acknowledgment is pending. Acknowledgment leaves it selected/deferred. Corrections preserve history. |
| Coordinator plan | Unset, one named-rep request, or mark-to-reschedule; previous plan is superseded | Only an explicit coordinator action commits/replaces a plan. Reschedule has no rep acceptance and makes no external-booking claim. Backups are candidates, not live requests. |
| Support arrangement | Not requested / requested / accepted / unavailable; connection is separate | Name the person/role and current plan. A late acceptance of a superseded plan cannot activate it. Availability and capability do not imply acceptance. |
| Connection | Local demo / connecting / connected / reconnecting / disconnected | Acceptance persists separately from transport state. On disconnect, remove the live-connected presentation and show the last confirmed state and time. |
| Message | Local-only, sending, sent, delivered, acknowledged, or failed, as actually supported | “Delivered” requires delivery evidence; “acknowledged” requires an explicit recipient action. Do not invent backend acknowledgments. |
| Voice | Off / listening / processing / unavailable | Show an explicit state, start/stop control, and touch alternative. Indicate the recognized action and prevent duplicate commands. |
| Camera or AI | Observation / human confirmation / AI draft | Preserve source, timestamp, uncertainty, and review state. Automated output must not silently complete an item or send a handoff. |

Loading, empty, unavailable, and error states are part of each screen's design. Explain what is known, what is pending, and what the user can do next. A blank log can say “No activity recorded.” A failed request retains the question and context and offers an explicit retry or edit. Show queued/offline behavior only if it has been implemented; do not imply persistence the prototype lacks.

The target core includes versioned local persistence under PRODUCT_FOUNDATION.md. A failed save keeps the draft and shows an actionable error; never show “Saved” on failed storage or reset corrupted data silently. The current starter still lacks this implementation.

## 6. Interaction, alerts, and copy

- Primary OR actions have a minimum 72 pt height and at least 72 pt width. Other interactive targets have at least a 44 × 44 pt hit area. Leave at least 8 pt between adjacent hit areas. These are project targets; verify physical-device use with gloves in the fictional walkthrough.
- Label actions by their effect: “Record confirmation,” “Defer item,” “Request support,” “Acknowledge request,” and “Send reply.” Avoid ambiguous approval language such as “All good.”
- Keep consequential actions explicit. A double tap, duplicate voice result, tab switch, or keyboard shortcut must not bypass a required acknowledgment or produce duplicate records.
- Show ordinary updates inline. Show attention items in a persistent banner with the named item, consequence for the app workflow, and available action. Use an interrupting acknowledgment only where the product state requires it.
- Use short speech or haptic feedback for important new events, paired with visible text. Do not repeat announcements on every render or make audio essential to completing a task.
- Keep history readable and stable. Include time and source/actor when available; new events must not pull the reader away from older content they are reviewing.
- Keep copy calm and factual. Say “Awaiting support acceptance,” “Item deferred. Acknowledgment required,” or “Connection lost. Last update 14:32.” Display relevant dates and time zones for scheduled coverage.
- In the local starter, describe a recorded local interaction honestly. Do not say a remote person received a request merely because a tab updated.

## 7. Accessibility and readability

Use Dynamic Type, meaningful VoiceOver labels and reading order, keyboard access, and reduced-motion behavior. Apple documents these in its [accessibility guidance](https://developer.apple.com/design/human-interface-guidelines/accessibility). The current fixed font definitions still need an implementation pass for scaling.

Use WCAG contrast ratios as internal visual targets for the native app: **4.5:1 for text** throughout our UI, and **3:1 for essential non-text control/state indicators** against adjacent colors. Our uniform text target is deliberately simpler than the standard's large-text exception. See W3C's [text contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) and [non-text contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) guidance.

- Verify text at default, XXXL, and the largest accessibility text size. Grow or rearrange content while keeping the question, recipient, unresolved state, and actions available.
- Verify VoiceOver order: case context → support/connection state → current work and unresolved items → actions → secondary history. Give controls their name, current value/state, and purpose. Do not announce timer ticks continuously.
- Verify visible keyboard focus and a complete keyboard path through case selection, confirmation/defer, acknowledgment, and support request/reply. Essential actions must also work with touch.
- Verify Increase Contrast, Differentiate Without Color, and Reduce Motion. Recheck text and control indicators in pressed, selected, focused, disabled, and warning states.
- Distinguish decorative separators from essential boundaries. Token names alone are not evidence that a specific foreground/background pair is accessible.

Historical dark-palette calculation on 2026-10-24 (not light-theme evidence): `ink` on `bgBase` is 16.38:1 and `inkMuted` is 8.38:1. `slate` on `bgBase` is only 1.59:1; the starter's unrecorded/upcoming icon treatment needs review. These are color-pair measurements, not a full-screen accessibility audit. Light-palette measurements and remaining verification gaps are in [the foundation evidence](evidence/light-workspace/README.md).

## 8. Implementation plan and current gaps

The logo and shared neutral typography/flat-control foundation landed in PRs #9 and #8. Full screen layouts and workflow-state behavior remain starter work. Follow [the ordered UX delivery plan](TASKS.md#ux-delivery-order).

Start with reusable fictional template/seed content (F03), workspace/case contracts (F24), then session/support contracts, guards and P0 persistence (F04/F06/F05/F18/F07). Shared visuals can progress separately. Setup/directory/case/start-resume flows (F25–F28) and both visual/state foundations precede final product verification. Use [PRODUCT_FOUNDATION.md](PRODUCT_FOUNDATION.md) for repeatability and [DEMO_READINESS.md](DEMO_READINESS.md) for the five-minute presentation gate.

Known gaps include fixed Co-pilot sidebars, unscaled font sizes, 12 pt label text, low-contrast upcoming icons, missing support acceptance/delivery state, missing correction/deferred-item behavior, and clinical-direction sample copy. Track fixes as implementation tasks; do not describe the targets in this guide as already shipped.

## 9. Review evidence for a UI PR

A reviewable UI change includes the relevant screen/state, the action it supports, and what happens after that action. Use the PR template to report actual checks and outstanding gaps.

| Evidence | Required review |
| --- | --- |
| Visual | Before/after screenshots for changed screens at a named iPad/window size; include the relevant warning, empty, failure, or disconnected state. |
| Layout and access | Default and enlarged-text screenshots; check touch targets, contrast, VoiceOver/keyboard access, and Reduce Motion relevant to the change. |
| Behavior | Exercise the normal path and the changed edge cases. State/model changes get meaningful automated tests; reversible styling changes get visual verification. |
| Truthfulness | No inferred completion, acceptance, delivery, clinical readiness, or persistence. Pending and unavailable states stay visible. |
| Integration | Existing local checks and required CI pass. No generated Xcode project, unrelated feature edits, or uncredited assets. |

Before the demo, rehearse one fictional case from coverage disruption through accepted support, a recorded confirmation, a deferred item and acknowledgment, a contextual support exchange, and review. Verify that the deferred item remains unresolved until explicitly changed. Record device, text-size setting, failures, and feedback from the OR staff/device-rep walkthrough. A successful screenshot or unit test is only one part of this review.
