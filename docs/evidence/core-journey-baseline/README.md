# Independent core journey baseline

Owner: Rahil / Codex. Baseline app commit: `5ebeb24` (October 24, 2026).

This begins F19 evidence collection before the support integration is merged. It is not release sign-off. The production app and existing tests are unchanged.

## Scope

Existing repository and iPad build/test checks were run independently on a dedicated iPad Pro 13-inch (M5) simulator, iOS 26.5 (23F77), using Xcode 26.6 (17F113). Run completed October 24, 2026 at approximately 9:40 PM CT.

## Actual results

- `bash scripts/check-repo.sh`: passed.
- `SIMULATOR_ID=A0D41292-DA52-4113-833A-9BBBFF0CD0C5 bash scripts/check.sh`: passed; **135 unit tests and 11 UI tests, zero failures**.
- Local result bundle: `build/check.W7hqZr/Tests.xcresult`; build/test log: `build/xcodebuild.log` (both ignored local artifacts).
- Generated Xcode project and build output remain untracked. No production Swift or existing test files changed.

The unit suite includes workspace/case and recording restoration, duplicate/stale command guards, failed saves and read failures, preservation of an unreadable latest run, draft restoration and case-switch blocking while acknowledgment is pending. These are automated domain checks, not manual on-device relaunch evidence.

The 11 UI tests cover Co-pilot deferral/acknowledgment/correction, portrait and enlarged text; Planner selection/filtering without changing the active recording; local support draft/navigation/message; default/enlarged shell appearance; blank setup into the tabs; and settings rename reflected in the header. Most launch with the optional in-memory sample argument; blank setup uses the empty in-memory launch argument. Neither launch path proves durable storage across a real app relaunch through normal controls.

## Captured production evidence

The following are unchanged attachments from that local result bundle, inspected visually. Source/credit: Northstar OR's existing XCTest UI capture code and simulator-rendered app, exported with Xcode's result tool. No third-party artwork or dependency was added. The test sets landscape orientation; original image pixels and orientation metadata are retained (encoded PNG dimensions 2064 × 2752).

| File | Source test | Observation |
| --- | --- | --- |
| [copilot-required-deferral.png](copilot-required-deferral.png) | `CoPilotPresentationTests/testDeferralAcknowledgmentAndCorrection` | The selected team-brief item is deferred, a persistent acknowledgment warning is visible, and Acknowledge/Correct actions are present. |
| [copilot-largest-text.png](copilot-largest-text.png) | `CoPilotPresentationTests/testEnlargedTextWorkspace` | Accessibility XXXL capture; header and context use substantial vertical space, and the confirmation control continues below the initial viewport. The test checks existence, not action reachability at this size. |
| [created-empty-workspace.png](created-empty-workspace.png) | `WorkspaceShellTests/testCleanStartShowsSetupThenCreatedWorkspaceOpensTabs` | Normal blank setup produces the named workspace and empty Planner. No New case action is visible in this baseline. |

## Findings and remaining gates

1. **Normal workflow integration remains blocking:** the empty worklist offers no New case action; the full new-case/start/support journey cannot be demonstrated from this baseline. This matches the existing implementation owners' pending Planner integration.
2. **Largest-text reachability needs a real interaction check:** the enlarged Co-pilot test waits only for the Record confirmation button to exist. Its passing result does not establish that confirmation, defer, warning acknowledgment and support are all reachable with the large header and keyboard. Preserve this as an explicit F19 follow-up; the screenshot alone does not establish an inaccessible action.
3. **Support scope remains local and partial:** the passing support UI test sends a local message; it does not exercise an immutable question snapshot, request acceptance, question acknowledgment, transport delivery or saved support exchange after relaunch.

The full blank setup → new case → start → contextual support → retained review journey remains unverified. At this baseline, Planner lacks normal New/Edit/Start/Resume entry points and support requests/acceptance/question acknowledgment are not implemented on main. Optional sample UI tests do not establish those product capabilities.

Manual VoiceOver, hardware keyboard, physical-device touch, Reduce Motion and full failure-screen checks have not been run in this slice. The interactive Co-pilot design preview in the product chat is a separate concept, not production build evidence.
