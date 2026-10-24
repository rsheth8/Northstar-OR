# Light workspace foundation evidence

Date: October 24, 2026. Scope: canonical design rules and additive, currently unused Swift color tokens. No application screen changes or new assets.

## Checks performed

- Inspected the owner's refined Planner image: aligned worklist/detail, light working surfaces, dark header, localized coverage warning and blue selection. This is concept review, not native UI verification.
- Ran `python3 docs/evidence/light-workspace/measure_contrast.py`; every listed opaque sRGB pair meets the internal 4.5:1 text / 3:1 essential-indicator targets. [Full results](contrast.md). The script reads the Swift definitions directly. It is a reproducible design calculation, not a behavioral test or full accessibility audit.
- Ran `bash scripts/check-repo.sh`: passed.
- Ran `bash scripts/check.sh`: stopped with `Install XcodeGen: brew install xcodegen`.
- Ran `xcodebuild -version`: failed because the selected developer directory is CommandLineTools, not Xcode. No Xcode application is installed in `/Applications`.
- Reviewed the scoped diff and ran `git diff --check`.

## Not performed / required on migration

No build, simulator test, named-size screenshots, enlarged-text rendering, touch interaction, VoiceOver, keyboard, Increase Contrast, Differentiate Without Color or Reduce Motion run was possible here. No UI readiness claim is made. Existing F01 evidence describes the old dark components and does not verify the new palette. CI results are separate from local results and must be checked before merge.

No component or screen consumes these opt-in tokens yet. Before adoption, inspect native control/sheet appearance, selection, focus gaps, disabled controls, warning/failure surfaces, wrapping, and all relevant actual color pairs. Dark header colors are intentionally separate from working-area colors. Do not use the decorative divider as an essential boundary.
