# Connected support: approved interaction handoff

Owner direction, October 24, 2026: make Co-pilot and Remote Support feel more interactive and useful through contextual support and brief, purposeful motion. The owner approved a clickable concept in the product chat. This document translates that direction into implementation and verification criteria; it does not claim the concept is shipped or validated with OR staff.

Use the existing [screen and state contracts](DESIGN.md), [product foundation](PRODUCT_FOUNDATION.md), and [five-minute delivery gate](DEMO_READINESS.md). This is a bounded refinement of F12/F13/F14, not another architecture or optional-feature assignment.

## Ownership and integration boundary

Amartya's active core-demo claims retain ownership of support contracts/orchestration and the Co-pilot, Remote Support, Planner and review integration. This documentation slice reserves only this file and its own TASKS.md row. It transfers no Swift files or existing F-number claims. Do not start another screen writer against those reservations.

Rahil/Codex supplies the interaction criteria and verification specification here. F19 execution and its exact test/evidence filenames must be claimed separately after the relevant merged interfaces are available. There is no claim of a completed end-to-end test in this handoff.

At the inspected main commit `5ebeb24`, #40/#41 provide workspace/contact and case forms, #42 provides the persisted state hub, and #43 wires setup/settings into the shell. Planner still lacks normal case-form and Start/Resume entry points. The support-orchestration branch is unmerged. Its author should integrate current main and present a focused PR before dependent screen changes consume its interfaces. Avoid copying the older branch's shared files over the newer storage/restore safeguards.

## The three interactions

| Moment | Visible behavior | Invariant |
| --- | --- | --- |
| Team asks for help | Request support is reachable beside the current work, including with zero deferrals or a pending warning. Enter the exact question, see the named recipient/role and attached context, then explicitly send. | Sending preserves selection, recording state, and the deferral gate. No acceptance or receipt is invented. |
| Rep joins | Lead with the exact question and sender/time, then case identity, unresolved work, recorded confirmations and the recorded logistical/support reason. Keep conversation secondary to this brief. | Build the brief from the immutable request snapshot. Label later events as changed since request. Missing information stays missing. |
| Reply returns | Show the named sender, time and reply prominently in Co-pilot, with access to the exchange while keeping the current item in place. | A reply, request acceptance or question acknowledgment never confirms a checklist item. The deferred item remains visible until an explicit permitted correction. |

Use configured contacts, the actual coordinator plan and merged commands. The concept's fictional names, item numbers, device label and preselected recipient are illustrative; they are not production fixtures, a new supported template, or required IDs. Keep simulated records under Data. Preserve one current plan and visible unrequested backups. Request acceptance, question acknowledgment, message state and transport state remain independent.

The concept demonstrates acceptance followed by question acknowledgment and reply. It does not authorize an extra domain gate requiring that sequence; production action availability follows the merged support contracts. Do not make conversation or read-only review inaccessible while a deferral warning is pending.

## Motion and touch behavior

- Use a brief native transition, approximately 160–220 ms, to reveal the context composer or an incoming reply and explain the local state change. System behavior is preferable where it already communicates the action.
- Make changes visible with stable text, icons, sender and timestamp. A transition is supplemental; it must not be the only evidence of a request, reply, failure or acknowledgment.
- Keep the current item and persistent warning anchored. Do not automatically navigate, scroll a person away from older activity, or delay an action until an animation ends. Opening the rep's brief is an explicit choice in the product; the concept's immediate tab change demonstrates both roles on one device.
- Respect the system Reduce Motion setting. Use an immediate update or restrained opacity change instead of translation when enabled. Essential information and controls stay available in either setting.
- Keep primary actions at least 72 × 72 pt and other targets at least 44 × 44 pt. Preserve the approved light surfaces, midnight header, native typography and Northstar tokens. Grow or stack content with enlarged text and narrow windows.
- Keep motion discrete. No looping pulse, decorative glow, bouncing controls, voice orb or flashing warning border. Green describes a recorded successful app action, never clinical readiness.

## Merge-sized implementation order

1. **Support core, existing owner:** integrate and verify the current support branch, keeping request/plan revision and case/session identities, immutable context, explicit acceptance/acknowledgment, persisted exchanges and failure behavior. Maintain the reviewed repository and newest-recording restoration fixes from main.
2. **Reachable normal workflow, existing owner:** connect the merged case form and explicit Start/Resume controls. Blank setup and independently created cases must reach the same support journey as optional samples.
3. **Contextual screens, existing owner:** implement the three interactions against merged commands. Preserve form drafts and case context, and show only actual request/message state. Add brief motion after the touch journey works.
4. **Independent verification, separately claimed:** exercise the matrix below on one candidate commit, capture evidence and report remaining gaps. Use findings for the five-minute presentation and backup recording.

Keep each implementation in its own reserved branch/PR. This handoff adds no dependency, asset, voice/camera/AI work, or transport choice. Use “On this device” until separate-device delivery is implemented and proven.

## Verification matrix for the integrated candidate

These are acceptance checks to execute, not results. Record commit, device/runtime, window size, text size and actual outcome with each evidence set.

| Check | Action | Required observation |
| --- | --- | --- |
| Normal entry | Set up a blank fictional workspace, add a technical rep, create two independently named compatible cases and explicitly start one. | No source edits, sample loading or fixed IDs are required. Browsing the other case does not switch recording. |
| Help without a deviation | Request support before deferring anything. | Question and actual unresolved context are attached; no deferral prerequisite. |
| Help during a warning | Defer a required item, then request support without acknowledging the warning. | Support remains reachable. Confirmation, further deferral and item/case switching remain guarded. |
| Distinct acknowledgments | Accept support and acknowledge the question separately; also acknowledge the deferral warning. | Each action has its own recorded state. Acknowledging the warning leaves the item selected and deferred. |
| Snapshot and subsequent change | Send a question, then acknowledge the deferral or record another permitted event. | Original snapshot is unchanged. Subsequent context is labeled separately with its actual source/time. |
| Incoming reply | Send a technical-support reply and return to Co-pilot. | Sender/time/reply are prominent; selection is preserved and the deferred item is still unresolved. |
| Draft and failure | Inject a supported failed send/save; navigate away and back and retry. | Draft and context are kept, failure stays actionable, retry has no duplicate effect, and “Saved”/“Delivered” is not claimed without evidence. |
| Plan replacement | Replace the coordinator plan, then attempt acceptance of the old plan. | Only the current plan can activate support. Backups stay unrequested. |
| Isolation and relaunch | Use the second case, then relaunch and explicitly resume each saved case. | Questions, replies, drafts, actors, corrections and unresolved states belong to the correct records. |
| Access and motion | Exercise default and largest accessibility text, narrow layout, keyboard, VoiceOver and Reduce Motion on the chosen device/runtime. | Essential question/recipient/current item/actions remain reachable; motion is optional and no warning is hidden. Report unrun checks explicitly. |

Use focused domain tests for identity, supersession, duplicate actions and storage. Use actual simulator/device interactions for visibility, focus, keyboard/composer behavior and motion. Passing domain tests alone does not establish usable layouts or physical-device behavior.

## Presentation proof

Rehearse a short support segment within the existing five-minute journey: the team asks while the deferred item stays visible; the rep reads the brief before asking for context, explicitly acknowledges and replies; the team sees the reply with the same item still deferred. Then review the retained record. The visible communication mode remains accurate.

Only capture final slides and backup footage from the verified integrated build. Prototype clicks are design feedback, not build evidence. Test the proposed usefulness in a fictional walkthrough with an OR nurse and device rep; do not claim measured time savings, clinical outcomes or workflow validation without evidence.
