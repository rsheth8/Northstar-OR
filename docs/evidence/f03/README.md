# F03 content and recording-copy evidence

Captured 2026-10-24 by Rahil's Codex integration driver. Baseline `c0bba2b`; implementation `eb9dd3a` (evidence-only commit follows). Device: iPad Pro 13-inch (M5), iOS 26.5 simulator, Xcode 26.6, landscape full display 1376 × 1032 pt. Raw simulator captures are 2064 × 2752 pixels with landscape content rotated; rotate clockwise to inspect upright. No image content was edited.

- [Before, default Large text](before-default.png): old clinical instructions and Skip/Complete controls.
- [After, default Large text](after-default.png): fictional case, team-report prompts, Defer item/Record confirmation.
- [Warning, largest accessibility text setting](warning-largest.png): named deferred item and Acknowledge warning; separate confirmation/defer/alert log entries.
- [After acknowledgment, largest accessibility text setting](after-largest.png): item remains deferred and history explicitly records acknowledgment only.

## Checks actually performed

- Built the baseline, installed the final F03 app, and inspected changed copy at default and `accessibility-extra-extra-extra-large`. Restored simulator content size to Large afterward.
- Used simulator touch actions to record item one, defer item two, and acknowledge its warning. New labels/history appeared; item two remained deferred. The existing next-item advance is visible and still belongs to F05.
- Inspected accessibility-tree labels for Record confirmation, Defer item and Acknowledge warning. This is not a spoken VoiceOver/reading-order test.
- Final implementation passed the complete iPad build/test run: 14 tests, zero failures, including eight new fixture/content behavior tests. Repository and whitespace checks passed. Independent read-only source review found no actionable F03 issue.

## Remaining evidence and product gaps

F01 scalable fonts are not merged: the enlarged setting grows system symbols while the existing custom text remains largely fixed. This is captured as a known gap, not an accessibility pass. No XXXL intermediate capture, physical-device/glove touch check, measured screen contrast, keyboard traversal, spoken VoiceOver or Reduce Motion test was performed. No animation or layout redesign was introduced here. Unsupported/empty/altered template and deferred-end summary states were verified by unit tests, not reached through a UI-only fixture route.

F24 owns canonical persisted template pinning/planning timestamps; F05 owns pending-warning pinning and domain guards; F07/F25 own empty startup, explicit optional loading and removal of array-zero activation. Co-pilot layout, connection labels and contextual support exchange remain later slices. These captures do not establish those workflows, persistence, clinical validation or delivery to another device.
