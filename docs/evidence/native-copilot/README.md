# Native Co-pilot workspace — actual rendering evidence

CI run [40143934904](https://github.com/rsheth8/Northstar-OR/actions/runs/40143934904), commit e9b8d11 (this branch merged with the native shell from #34): unit tests, the shell capture tests and `CoPilotPresentationTests` passed on **iPad Pro 13-inch (M5), iPadOS 26.2**. Images are actual simulator output exported from the test result, not mockups. Landscape captures were rotated upright for review; pixels are otherwise unchanged.

| File | What it shows |
|---|---|
| `co-pilot-required-deferral.png` | Item 1 deferred: the localized amber warning sits with the current item, the rail item is pinned with its explanation, Acknowledge deferral and Correct record are available, and activity is in the inspector. No screen-wide border. |
| `co-pilot-acknowledged-still-deferred.png` | After acknowledgment the item remains **Deferred**; Record confirmation is not offered and the test asserts that. |
| `co-pilot-correction-sheet.png` | The correction sheet records a new state and optional reason while the earlier entry remains in history. Saving restores the unrecorded actions (asserted). |
| `co-pilot-portrait.png` | Portrait window: compact rail plus current item; activity moves to the toolbar sheet. |
| `co-pilot-accessibility5.png` | Accessibility XXXL text: the rail and inspector collapse into toolbar sheets and both primary actions remain visible. |

Checks actually performed: the UI test drives defer → acknowledge → correct with touch events on the simulator and asserts the guarded states above. The screenshots were inspected visually.

Not performed: physical-device touch, VoiceOver, hardware keyboard navigation, Increase Contrast, Differentiate Without Color and Reduce Motion passes. Support requests, acceptance and receipts remain pending F07/F12; the Support context sheet labels this build's local-only state.
