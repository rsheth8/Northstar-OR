# Working together quickly

`main` is the shared integration branch. Keep work small enough to review in a few minutes, push early, and let CI catch build/test regressions. Green tests reduce risk; they do not replace reviewing behavior or testing voice and device interactions.

## Start one task

1. Read `AGENTS.md`, `CLAUDE.md`, `PRODUCT.md`, `PRODUCT_FOUNDATION.md`, `DESIGN.md`, and `TASKS.md`. Check open PRs for work already in progress. The owner-confirmed presentation is five minutes; setup, normal case creation and retained state are core product requirements.
2. Update local `main` with `git pull --ff-only` while your workspace is clean. Never discard local edits to make it clean.
3. Create a task branch: `copilot/<task>`, `planner/<task>`, `sync/<task>`, or `pitch/<task>`.
4. Mark the task `[~] (your name)` in `TASKS.md` and push an early draft PR so the other teammate can see the claim. A claim sitting only on your laptop is invisible to them.
5. Keep changes in your lane. Agree on shared interfaces before editing models, `AppModel`, `SyncService`, or design tokens; land those changes in a small separate PR first.

## Pairing and agents

The working partner allocation is in [PARTNER_EXECUTION.md](PARTNER_EXECUTION.md); use [AGENT_BRIEFS.md](AGENT_BRIEFS.md) for the first bounded tasks. Rahil owns shared contracts/session/integration and release; Amartya owns shared UI, repository, configuration/Planner and recipient support. Rahil takes the directory after setup lands. Planned ownership is not an active claim. Start with F03 under Rahil, then F01 under Amartya once F03 is visibly claimed.

Default to two isolated code writers and one read-only reviewer. A temporary third writer replaces the reviewer only for a disjoint reserved task, within available agent slots. Name exact files including tests; shared Models/AppModel/Sync changes are serialized and repository/shell bridges have explicit handoffs. Rahil coordinates the task board and merge order with the existing steward. Dependent implementations consume merged main; do not invent private substitute contracts while an upstream PR is unfinished.

When pairing on one branch, choose one driver who edits and pushes; the navigator reviews. When working independently, use separate branches and preferably separate checkouts/worktrees. Never run two writing agents in the same checkout at once: checking out a branch changes the files for both agents.

Give each agent the task, allowed folders, expected behavior, and tests. Ask it to inspect existing code before adding an abstraction. An agent must disclose what it actually tested and must not approve its own PR. Agent review and passing CI are the default; a teammate can review when useful, but a human approval is not required.

## Check, review, merge

```sh
bash scripts/check-repo.sh
bash scripts/check.sh
```

The second command generates the Xcode project, selects an installed iPad runtime between the app minimum (iOS 17) and the active simulator SDK, waits for boot readiness, then builds and runs the unit/UI suites without signing. This keeps a pinned Xcode job from silently switching its baseline when a newer simulator runtime is installed. The selector’s mixed-runtime CLI tests also run in repository checks. Install XcodeGen with `brew install xcodegen`. To pick a specific simulator, use `SIMULATOR_ID=<udid> bash scripts/check.sh`. Results and logs are in ignored `build/`.

Open the draft for review once ready. Explain the behavior and verification in the PR template; include a screenshot for visible changes. Review shared state, failure/disconnect paths, and product boundaries. Avoid cosmetic churn in unrelated files.

For UI changes, use [the design guide](DESIGN.md#9-review-evidence-for-a-ui-pr): include before/after screenshots at a named iPad/window size, enlarged-text evidence, and the relevant empty, warning, disconnected, or failure state. Record the touch-target, contrast, VoiceOver, keyboard, and Reduce Motion checks actually performed, plus unresolved gaps. State/model changes need meaningful behavior tests; reversible styling changes need visual verification. Documentation-only PRs can mark the UI section not applicable. These are review requirements, not an additional human-approval requirement.

GitHub protection was enabled on 2026-10-24 with these settings:

- PR required for `main`, including administrators; direct pushes are blocked.
- No mandatory human approval; all review conversations resolved.
- Required checks: `Repository checks` and `iPad build and tests`, against current `main`.
- Squash merges only, automatic deletion of merged branches, and an Update branch button.
- Auto-merge available: enable it only when ready; GitHub waits for required checks and branch rules.
- Force pushes and branch deletion blocked on `main`.

Check Settings → Branches for the live policy. Human review is optional; repository stewardship is delegated to an agent as described below.

Before opening a PR, rebase on current `origin/main`. If another PR lands during review, use GitHub's Update branch button (safe on a shared branch), or rebase only your own task branch with `git push --force-with-lease`. A rebase rewrites commits and triggers fresh checks. Never force-push a branch another teammate is actively using without coordinating.

CI runs on every PR to `main` and after merges. It checks generated/local files and conflict markers, then builds/tests on macOS 15 with Xcode 16.4. Actions are pinned to commit IDs; Dependabot proposes updates weekly. Older runs on the same PR are cancelled, failures retain logs/results for seven days, and no signing credentials are needed. macOS runs consume the private repository's Actions allowance; no spending limit is changed by this setup.

After merging, pull current `main`, regenerate the project, and mark the task `[x]` in the next task-board update. Delete your local task branch when it is no longer needed.

## If something breaks

Stop dependent merges. Open a small fix PR or revert the offending PR through GitHub, run CI, and have the agent review the diff before merging. Keep unrelated unfinished work on its existing branch. For demo readiness, manually rehearse the full simulated journey on the actual devices; a passing unit suite cannot verify microphone behavior, UI usability, or cross-device delivery.

## Repository steward

The owner has authorized an agent to monitor this repository and manage routine PR integration without mandatory teammate approvals. A heartbeat named **Northstar OR repo steward** is scheduled every 15 minutes in the owner’s Codex chat; this schedule is an app setting and does not travel with a Git clone. GitHub enforces required checks continuously; the recurring agent run handles follow-up on a schedule. This is not continuous live supervision.

For ready PRs, the steward reviews the diff and CI, updates the branch from `main` when needed, and enables squash auto-merge. Drafts, explicit holds, failed checks, unresolved conversations, unclear intent, and unsafe conflicts block integration. The steward can propose small targeted fixes, but must not bypass protections, rewrite active teammate branches, discard work, invent completed validation, or broaden product scope. It stays quiet when there is nothing actionable and reports meaningful merges, failures, or decisions requiring the team.
