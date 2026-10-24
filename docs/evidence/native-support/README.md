# Native Remote Support presentation — actual rendering evidence

CI run [40144471146](https://github.com/rsheth8/Northstar-OR/actions/runs/40144471146), commit 7c5f10a (this branch merged with the native shell from #34): unit tests, the shell capture tests and `SupportPresentationTests` passed on **iPad Pro 13-inch (M5), iPadOS 26.2**. Images are actual simulator output exported from the test result, not mockups. Landscape captures were rotated upright for review; pixels are otherwise unchanged.

| File | What it shows |
|---|---|
| `remote-support-keyboard-draft.png` | A suggested reply placed in the draft, kept after switching to Planner and back (asserted), with the on-screen keyboard up and Send locally reachable above it (asserted hittable). |
| `remote-support-local-message.png` | After sending, the message appears in the conversation with sender and time, and the draft is cleared. |
| `remote-support-accessibility5.png` | Accessibility XXXL text: the brief stacks above the conversation and the composer stays pinned to the bottom with its actions visible. |

The brief leads with the team question slot, then current case context, unresolved items before recorded confirmations, and the support context label. It states plainly that this is live local context, not a request snapshot, and that requests and question acknowledgment are not available in this build.

Fix made from this evidence: the first capture showed the newest message clipped when the keyboard shortened the conversation pane. The conversation now anchors to its newest message (`defaultScrollAnchor(.bottom)`, iPadOS 17+); the capture above is after that fix.

Not performed: physical-device touch, VoiceOver, hardware keyboard navigation, Increase Contrast, Differentiate Without Color and Reduce Motion passes. Failed-send recovery is implemented (the draft is kept with an explanation) but has no capture, because the local route cannot currently be made to fail. Immutable request snapshots, acceptance, delivery receipts and question acknowledgment remain pending F07/F12.
