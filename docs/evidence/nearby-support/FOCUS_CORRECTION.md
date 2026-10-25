# Focus layout correction

Owner selected Focus in the interactive Co-pilot concept; the delivered vertical workflow layout did not match it. This correction uses that existing approval, without reopening design exploration.

- Horizontal workflow strip and progress above the current item.
- Dominant current work, restrained actions, reply and recorded activity below.
- Persistent contextual support composer/request on the right at landscape widths; stack below current work in narrow/enlarged windows.
- Preserve existing recording, warning, correction, persistence and nearby support commands. Use actual configured contacts/template/session content, not mockup seed labels.

Implementation: adjust CoPilotView and add a feature-local support panel. Keep modal request available as an alternate path. No model, storage or transport changes. Verify build and one support UI journey; capture a landscape screenshot for comparison. No broad test expansion.

Result: native build and focused support journey passed (`build/focus-inline.log`, `build/DerivedData/Logs/Test/Test-NorthstarOR-2026.10.24_23-01-11--0500.xcresult`). The journey sends from the persistent inline composer during a pending deferral warning, records acknowledgment/reply, and verifies that the warning remains. Landscape screenshot visually compared with the selected concept: [Focus, 1376 × 1032 pt](focus-ipad13-1376x1032pt.png).

No full-suite rerun or additional test expansion. New layout at enlarged text/narrow windows, VoiceOver, hardware keyboard, and physical two-iPad delivery remain unverified in this correction. Existing narrow/enlarged stacking is implemented, not claimed as newly checked. The real app retains its native shell and actual configured template/contact content rather than copying mockup seed content.
