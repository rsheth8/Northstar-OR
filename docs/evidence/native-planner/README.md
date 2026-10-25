# Native Planner worklist — actual rendering evidence

CI run [40144517478](https://github.com/rsheth8/Northstar-OR/actions/runs/40144517478), commit 7ba7bb6 (this branch merged with the native shell from #34): unit tests, the shell capture tests and `PlannerPresentationTests` passed on **iPad Pro 13-inch (M5), iPadOS 26.2**. Images are actual simulator output exported from the test result, not mockups. Landscape captures were rotated upright for review; pixels are otherwise unchanged.

| File | What it shows |
|---|---|
| `planner-selected-case-default.png` | Case worklist (reference, time, town, labeled coverage risk) with the selected row's pale-blue background and narrow rail; detail in the approved order: identity, site/schedule/template/recording, coverage assessment with logistical reasons, then ranked support options marked **Not requested**. |
| `planner-filter-empty.png` | A search with no matches: the empty state explains why and offers Show all cases; the selected case detail is retained. |
| `planner-selected-case-accessibility5.png` | Accessibility XXXL text: rows and labeled fields wrap rather than truncate; risk keeps its icon and label. |

Checks actually performed: the UI test selects proc-3 while proc-1 is recording and asserts the detail reads **Not active on this device** (browsing does not move the recording), then switches tabs and asserts the selection persists. It searches for a missing case and asserts the empty state. Screenshots were inspected visually.

Fix made from this evidence: support options showed the raw role value `technicalRep`; they now show readable role labels.

Not performed: physical-device touch, VoiceOver, hardware keyboard navigation, Increase Contrast, Differentiate Without Color and Reduce Motion passes. Times show the simulator's GMT because the fictional sites record no time zone. New case, Edit case, a current coordinator plan with request state and explicit Start/Resume are deliberately absent until F11/F27/F28 land; the screen does not substitute local placeholders for them.
