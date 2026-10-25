# Workspace shell integration evidence

Screenshots exported from successful GitHub Actions run [40150037466](https://github.com/rsheth8/Northstar-OR/actions/runs/40150037466), PR #43 head `86a65dc`, on iPad Pro 13-inch (M5). Source test bundle: `ipad-test-results/check.BFF0J5/Tests.xcresult`. These captures precede the integration merge that preserves the newer recording-restore fix; required CI reruns on that merged head.

- [Blank workspace setup](setup.png): fictional-data notice, editable setup and explicit optional samples.
- [Created empty workspace](created-empty-workspace.png): configured name, local-only mode and settings remain visible. This slice wires the shell; new-case entry is separate work.
- [Renamed header](renamed-header.png): settings save/dismiss updates the workspace header.
- [Largest accessibility text](largest-text.png): existing enlarged-workspace UI test exercises the shell with sample context. Header reflows vertically; this does not establish all setup/error screens work at every size.

Inspection confirms default setup/empty/renamed states and enlarged header text are represented. Setup-to-tabs and settings-save/rename are exercised by WorkspaceShellTests. Latest local integration passed all 135 unit tests. The merge retains current main's newest-recording restore guard and its regression test, while preserving this PR's setup/settings gate.

Unrun checks: manual VoiceOver, hardware keyboard, Reduce Motion, physical touch, and blocked-storage/save-failure screen captures. Failure handling has domain tests, which do not replace those visual/interaction checks. No claim of a complete accessibility or recovery audit. See the existing native workspace evidence for the preceding shell appearance.
