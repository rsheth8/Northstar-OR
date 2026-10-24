# Northstar OR: bounded agent briefs

Use with [PARTNER_EXECUTION.md](PARTNER_EXECUTION.md). These are copyable task prompts, not running agents or completed implementation claims. Each human supplies a clean isolated checkout and checks current PRs/claims first. Human owners supervise the resulting behavior.

## 1. Rahil's kickoff: core builder, F03 only

```text
Build Northstar OR slice F03: reusable fictional coordination content and optional seeds.
Human owner: Rahil. One task, one pitch/ branch, one isolated checkout, one small PR.

Read AGENTS.md/CLAUDE.md and the required PRODUCT, PRODUCT_FOUNDATION, DESIGN,
TEAM_WORKFLOW and TASKS documents. Also read PARTNER_EXECUTION and F03's detailed
acceptance in IMPLEMENTATION_PLAN. Inspect current consumers/tests before editing.
Check current main, open PRs and claims. Ask the integration driver to publish your
F03 claim, or reserve and update just its TASKS line yourself; open a draft early.

Allowed: NorthstarOR/Data/, focused fixture tests, your reserved claim/handoff.
Identify exact existing copy-consumer files needed and coordinate those reservations
before editing. Amartya's F01 worker is restricted to DesignSystem during this slice.
Do not redesign screens, rewrite AppModel/SyncService or introduce a parallel Models
schema. If a missing shared type is essential, describe the smallest F24 dependency
and agree a compiling boundary instead of silently enlarging this PR.

Deliver one versioned supported fictional pacemaker coordination template, reusable
optional seed/factory inputs with injected time/IDs, and calm non-directive recording
copy. New compatible case/contact IDs must not require Grand Marais, Ana or array zero.
Represent the supported/unsupported template distinction so the ICD example cannot
launch reused implant instructions. Empty data remains valid; full runtime setup and
sample loading land in their later slices. Do not claim those are implemented here.

Test the meaningful fixture/template behavior and boundaries; run repository checks
and the applicable iPad build/tests. Review the diff, preserve teammate edits, and
never commit generated .xcodeproj. Use only simulated data under Data and keep prompts
coordination-only. Credit any new dependency/API/asset in README in this same PR.

Return the PR URL, actual checks/results, exact public content/API handoff, remaining
gaps and next F24 dependency. Stop after this slice; do not start F24 automatically.
Do not send messages to external people or other user chats.
```

## 2. Amartya's kickoff: operations builder, F01 only

```text
Build Northstar OR slice F01: accessible shared components and typography.
Human owner: Amartya. One task, one pitch/ branch, own isolated checkout, one small PR.

Read AGENTS.md/CLAUDE.md and all required product/design/workflow/task documents,
PARTNER_EXECUTION and the F01 acceptance in IMPLEMENTATION_PLAN. Inspect existing
tokens and consumers. Check main/open PRs and that F03 is visibly claimed before
starting implementation. Publish your shared-UX/F01 claim through the integration
driver or reserve just that task line. Open an early draft PR.

Allowed: NorthstarOR/DesignSystem/, focused component previews/evidence, reserved
claim/handoff. No feature redesign, RootView, Models, AppModel or SyncService edits.
If a consumer change is necessary, name its exact file and obtain a file reservation
first; do not broaden the PR or invent a domain API.

Implement scalable neutral typography, supporting labels at least 13 pt at default,
readable essential status/control indicators, flat primary/secondary controls and
visible pressed/disabled/focus states. Use Northstar tokens and the approved navy/ice
identity. Preserve at least 72x72 pt primary and 44x44 pt other targets with spacing.
Respect Reduce Motion. No orb, glow, bouncing, decorative gradients or AI dashboard.

Capture component evidence at a named iPad/window size with default, XXXL and largest
accessibility text where tooling permits, including relevant warning/disabled states.
Measure actual foreground/background contrast; report touch/focus/VoiceOver/keyboard/
Reduce Motion checks actually run and any gaps. Do not write token-literal tests.
Run repository checks and applicable iPad build/tests; review your diff. Never commit
generated .xcodeproj or unrelated edits; credit any new library/API/asset in README.

Return PR, actual checks/evidence, public component handoff and gaps. Stop after F01;
do not start F02 or edit feature views automatically. Do not send external messages.
```

## 3. Later slice work order

The human fills every field below from the allocation table and the merged upstream PR. Do not paste an unspecified ID, base or file list into a writing agent.

```text
Task: [one F-number and its concrete behavior]. Human owner: [Rahil or Amartya].
Base: [current main commit]. Merged dependencies: [PRs/commits and public commands].
Branch: [allowed prefix/task]. Checkout: [this worker's isolated absolute path].
Allowed files/test files: [exact reservation]. Shared-file driver: [named owner].
Acceptance: [the slice's actual success, empty/unknown/failure and invariant checks].
Consumer/handoff: [next owner, types/commands, schema/version and error semantics].

Read the repository's required instructions and relevant product/design/plan sections.
Check open PRs/claims before changing anything. Publish just this task's claim through
the integration driver or its reserved task line; open a draft early. Inspect current
code and extend it in compiling slices. No architecture rewrite or shadow models.

Stay in the reserved files. If a required shared command/type/consumer is missing,
report the exact dependency and coordinate a separate contract/bridge PR. Do not
silently edit another worker's files or implement against unmerged local changes.
Use SyncService for cross-feature/backend exchanges, the agreed repository/application
boundary for retained state, and domain commands for recording/plan mutations.

Keep fictional data and coordination-only copy. Verify relevant domain invariants:
one current plan, separate acceptance/connection/question acknowledgment, stable
workspace/case/session/intent IDs, pinned required deferral, explicit correction,
immutable request snapshot, draft retention, honest save/submission/receipt results.
No sample-name dependency or hidden automatic completion/acceptance. Preserve existing
records and teammate edits. New libraries/APIs/assets require same-PR README credits.

Run meaningful behavior tests and repository/iPad checks appropriate to the change.
UI changes require named device/window/default/enlarged-text and relevant failure/
empty/warning evidence. State checks run and gaps; no invented device/clinical proof.
Review the diff and satisfy required CI. Never commit generated .xcodeproj, bypass
branch protections, force-push a teammate's branch or fabricate GitHub approval.

Return PR, exact checks/results, evidence, public handoff and blockers. Stop after the
one slice. Mark complete only after merge via the next task-board update. Do not send
external messages or other user-chat messages without direct human authorization.
```

## 4. F18 repository handoff details

Amartya's F18 work order follows merged F24/F04/F06. Reserve new repository files under `Services/` and focused persistence tests. Coordinate snapshot/DTO additions separately; Rahil retains AppModel/SyncService integration in F07.

- Store one configured fictional workspace, directory, cases, session state/events and drafts. Version the format and write atomically; inject the store/clock for meaningful tests.
- Publish exact load/save/restore results and visible error semantics. Failed writes retain unsaved state/drafts and never produce a false “Saved.”
- Corrupt or unsupported data must not silently reset/overwrite. Optional sample loading/reset is explicit and scoped; launch never restores seeds automatically.
- Restore pending submissions for reconciliation without inventing receipt, acknowledgment, acceptance or live connectivity.
- Test independent IDs/cases, relaunch mid-draft/send, failure/corruption/version mismatch and round trips. This is bounded local storage, not institutional audit/backup/security.
- Hand the concrete repository contract to Rahil's F07 and Amartya's F25 before forms integrate. Do not start a network backend, event-sourcing framework or enterprise account system.

## 5. Independent review brief

```text
Review [PR URL and slice] against current main, its declared files and acceptance.
Read the applicable product/design/instructions. Read-only: do not edit, branch, claim,
commit, merge or submit a GitHub approval. This is review feedback for the integrator.

Find actionable correctness/integration problems: wrong case/session or stale target,
duplicate mutation, bypassed required acknowledgment, implicit plan replacement or
acceptance, false saved/delivered/connected state, lost draft/history, unsupported
template launch, clinical-direction copy, unmerged dependency or shadow store.
Check shared-file reservations and whether meaningful tests cover the changed behavior.

For UI, inspect provided named-size/default/enlarged-text and failure/empty/warning
evidence against DESIGN. Distinguish inspected evidence from checks you did not run.
Report prioritized findings with exact file/line, trigger and impact. If none, state
no actionable findings and the actual review scope/remaining evidence gaps. Do not
claim device usability, hospital readiness or delivery based on code inspection alone.
```

One independent reviewer can rotate between both lanes. The author still reviews their own diff; passing CI and a review do not replace the product/device tests in [DEMO_READINESS.md](DEMO_READINESS.md).
