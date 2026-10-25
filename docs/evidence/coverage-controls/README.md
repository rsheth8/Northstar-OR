# Coverage controls verification — October 25, 2026

Base: merged #55 (`1ad2b4d`). Candidate: `planner/coverage-controls`, including the changes accompanying this evidence commit. Three CoveragePlanPresentationTests passed on iPad Pro 13-inch (M5), iOS 27.0, Xcode 27.1. Tests requested landscape orientation, 1376 × 1032 pt; original screenshot files and orientation metadata are preserved. Default text and accessibility XXXL are included. The baseline shell here precedes #53; these captures do not establish integrated shell polish.

The actual normal controls request remote support, retain revision 1 awaiting response/on this device, cancel replacement, and explicitly replace it with revision 2 reschedule intention. Another test changes the device to Rep using its normal role control and opens an honestly empty inbox. No transport receipt or acceptance is fabricated for these screenshots.

- `coverage-request-default.png`, `coverage-replaced-default.png`: normal-text pending request and explicit reschedule intention.
- `coverage-request-largest-text.png`, `coverage-replaced-largest-text.png`: the same actions remain reachable by scrolling at the largest text size.
- `coverage-rep-inbox-empty-disconnected.png`: recipient empty/disconnected state.
- `manifest.json`: original Xcode attachment provenance.

Build-for-testing succeeded. Repository and whitespace checks passed. The #55 contract recovery separately passed 57 focused model/repository/integration tests and required CI before merge. Those injected-transport tests are not a new physical-device proof for these screens.

Review: original default/largest request, reschedule and inbox images were inspected. The shared large button styles preserve minimum targets in code; automated tapping proves the tested controls were reachable, not physical usability with gloves. No new contrast measurement, VoiceOver traversal, hardware-keyboard, Reduce Motion, Catalyst, real-device accept/decline/reconnect or failed-send screenshot is claimed. Existing model tests cover exact revision/mode, late obsolete responses, save failure and stable retry. Physical recipient workflow and integrated accessibility remain release gates.
