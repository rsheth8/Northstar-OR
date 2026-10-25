# Nearby support exchange — implementation claim and verification

Owner-authorized driver: Rahil / Codex, branch `sync/nearby-support-exchange`, isolated checkout based on `d868e28`. This task owns the support exchange values, retained questions, SyncService adapter, AppModel commands, Co-pilot request/reply, Remote Support brief, nearby shell control, permission configuration, focused tests and this evidence note. Prior support orchestration is not consumed. No push is authorized.

The four owner-edited planning documents and task board in the primary checkout are preserved. This note records the bounded claim instead. Implementation and device results will be added as actually performed.

Physical two-iPad exchange, local-network permission behavior, disconnect/reconnect, VoiceOver, hardware keyboard, Reduce Motion and physical touch: **not run**. This host currently has no two paired iPads available. Simulator and in-memory-pair results will be labeled separately.

## Implemented locally

- Frozen case brief attached to a retained question; later checklist/acknowledgment context is displayed separately.
- Separate delivery receipts for question, acknowledgment and reply; explicit retry preserves message identity and snapshot.
- Independent Rep workspace inbox, per-question reply drafts, and room-only recording commands.
- Contextual request/reply in Co-pilot, retained Remote Support brief, explicit peer selection and invitation acceptance.
- Required Multipeer session encryption behind SyncService; explicit stop/background teardown; local fallback starts without discovery.

Independent read-only review found two important recovery issues: saved-question resend and stopping a disconnected link. Both were corrected and rechecked; no further critical/important findings were reported. This is a code review, not GitHub approval or physical transport proof.

## Automated and visual checks

Verification host: Xcode 26.6, iOS 26.5, dedicated iPad Pro 13-inch (M5) simulator (1376 × 1032 pt). The paired transport in tests is in-memory, not Multipeer device delivery.

- Baseline: 135 unit / 11 UI tests passed (`build/check.VnnVcm/Tests.xcresult`).
- Focused support UI: three tests passed (`build/journey-green5.log`), including request/reply during pinned warning and draft navigation. This caught and fixed a real observation issue that left Send disabled after typing.
- Final verification: 150 unit and 12 UI tests passed, including enlarged text. The complete result is in `build/check.Sgi7BH/Tests.xcresult` / `build/nearby-final3.log`. An earlier runner-launch failure and an earlier failing test-driver helper are retained in prior logs; neither was counted as a pass.
- Large-text request/brief actions passed (`build/large-final2.log`). Screenshots below were visually inspected for wrapping and reachable actions; the brief capture is at a scrolled position.
- Software-keyboard text entry, hiding keyboard, tab navigation, retained drafts and send controls are exercised by UI tests. Physical hardware keyboard remains untested.
- No further checks are being added; owner requested focus on feature delivery.
- Bonjour permission configuration inspected in built Info.plist. Apple API credit included in README.

Physical two-iPad delivery, permission denial, real disconnect/reconnect and background behavior: **not run**. VoiceOver traversal, hardware keyboard, measured contrast, physical touch and Reduce Motion interaction: **not run**. System text fields and labeled native controls are used; these are implementation choices, not accessibility certification. See [DEVICE_CHECK.md](DEVICE_CHECK.md) for the remaining reproducible check.

The primary checkout now also contains separate call/camera work. This isolated branch does not incorporate or modify that work; shared shell/project changes will need deliberate integration later.

## Captured states

Native screenshot files retain Xcode orientation metadata. Sizes refer to displayed iPad points.

- [Large-text request, 1376 × 1032 pt](ipad13-1376x1032pt-request-accessibility5.png)
- [Large-text brief, 1376 × 1032 pt](ipad13-1376x1032pt-brief-accessibility5.png)
- [Empty support, 1376 × 1032 pt, large text](ipad13-1376x1032pt-empty-accessibility5.png)

- [Reply beside pending deferral, 1032 × 1376 pt](ipad13-1032x1376pt-reply-warning.png)
