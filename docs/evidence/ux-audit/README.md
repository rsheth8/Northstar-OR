# Whole-product UX audit evidence

Reviewed **October 25, 2026**, against `21b107b` (merged PR #47). See [the complete audit](../../UX_AUDIT.md). These are original simulator captures of the existing app, not screenshots of a shipped redesign. No production Swift view/model/service changes are in this audit slice.

## Device and runs

- Dedicated **Northstar UX Audit** simulator (`561AAD34-62C6-4B7B-AD73-0D994BC973ED`), **iPad Pro 13-inch (M5)** device type, **iOS 26.5**.
- Landscape window: **1376 × 1032 pt**. Original simulator PNGs preserve their supplied orientation/metadata.
- Default text and launch override `UICTContentSizeCategoryAccessibilityXXXL` (largest accessibility category).
- New `UXAuditJourneyTests.testWholeProductWalkthrough`: **passed**, 55.678 s. Explicit setup/sample load → selected Planner case → New case/validation/cancel → no-active-case Co-pilot → explicit Start recording → defer → review → acknowledge → correction editor → support empty state → connect sheet → settings → contacts → New contact.
- New `UXAuditJourneyTests.testLargestTextRoomAndRep`: **passed**, 17.018 s. Captured first Co-pilot viewport, scrolled until Record confirmation was hittable, opened Remote Support and switched to rep empty state. Passing reachability does not establish a good layout; inspect captures 16–17.
- New `UXAuditJourneyTests.testSettingsSavePreservesContactEdit`: **passed**, 40.662 s. Edited Ana's fictional contact name, saved, returned to Settings, saved settings, reopened Contacts and verified the edit remained. The suspected overwrite did not reproduce.
- Existing `SupportPresentationTests`: **2 passed**, 66.503 s total. Local question/reply and reply-draft retention across tab navigation; largest-text request/brief action reachability.
- App and test runner built successfully for these runs. Full unit/all-UI suites were not rerun locally for this documentation/test-only slice; required CI is separate.
- Result bundles and logs remain in ignored `build/UXAudit.xcresult`, `UXContacts.xcresult`, `UXSupport.xcresult` and `ux-*.log` in the isolated audit checkout. The three new checks are retained as executable source in `NorthstarORUITests/UXAuditJourneyTests.swift`.

## Captures

| Flow | Original captures |
| --- | --- |
| Setup | [01 setup](01-setup.png) |
| Planner | [02 no selection](02-planner-empty-selection.png), [03 selected case](03-planner-detail.png) |
| Case form | [04 new case](04-new-case.png), [05 validation](05-case-validation.png) |
| Co-pilot | [06 no active case](06-copilot-no-case.png), [07 default](07-copilot.png), [08 required deferral](08-required-deferral.png) |
| Review/correction | [09 recorded activity](09-record-review.png), [10 correction](10-correction.png) |
| Support/connect | [11 no question](11-support-empty.png), [12 connect sheet](12-connect.png) |
| Settings/contacts | [13 settings](13-settings.png), [14 directory](14-contacts.png), [15 new contact](15-new-contact.png), [20 edited contact preserved](20-contact-after-settings-save.png) |
| Largest text | [16 initial Co-pilot](16-copilot-accessibility5.png), [17 scrolled recording action](17-record-action-accessibility5.png), [18 room support](18-support-accessibility5.png), [19 rep empty](19-rep-empty-accessibility5.png) |
| Existing support journey | [Reply draft after navigation](Remote-support-keyboard-draft.png), [local reply](Remote-support-local-message.png), [largest-text empty support](Remote-support-accessibility5-empty.png), [largest-text request](Support-request-accessibility5.png), [largest-text brief](Support-brief-accessibility5.png) |

Numbered captures have matching `*-hierarchy.txt` files with the original accessible names and frames. The existing test names its draft capture “keyboard-draft,” but it **hides the keyboard before capture**. That image does not prove the composer stays above an open keyboard.

## Actual layout and access review

**Visual:** inspected setup, selected Planner, case form, default/pending/enlarged Co-pilot, empty support, settings/contacts and the local support brief/reply captures. No native Mac window, Split View, portrait, real media, permission-denial, failed-save or failed-send screenshot was newly captured in this pass. The connected rep's question ordering was inspected in source; do not label a local room reply as a newly verified two-device handoff.

**Touch:** inspected shared 72 pt primary / 44 pt secondary design targets and the captured primary-action frames; the default Record confirmation frame is 277 × 82 pt. Largest-text Record confirmation was scrolled into a hittable state. The native role segment's accessibility frame is 120 × 32 pt; effective physical hit area was not tested. No glove or physical-device touch check was performed.

**Contrast:** calculated the opaque sRGB pairs currently defined in NorthstarWorkspacePalette.swift using WCAG relative luminance. This checks the named token pairs only; it does not verify native placeholders, disabled alpha, every rendered combination or text over media.

| Pair | Calculated ratio |
| --- | ---: |
| Body `202B38` / white | 14.34:1 |
| Supporting `526171` / canvas `F4F6F8` | 5.86:1 |
| Header secondary `CFDCE7` / header `142D43` | 10.12:1 |
| Action white / `174F85` | 8.42:1 |
| Attention `825200` / `FFF3D9` | 6.04:1 |
| Success `176842` / `EAF4EE` | 6.03:1 |
| Failure `A52932` / `FCEDEF` | 6.24:1 |
| Essential boundary `758394` / white | 3.87:1 |

**Keyboard:** automated text entry, hide-keyboard actions and reply draft navigation passed in the existing support checks. Hardware-keyboard focus/shortcuts, first-invalid-field focus, and keyboard-open composer placement were not validated.

**VoiceOver / Reduce Motion:** accessible hierarchy inspected; no VoiceOver traversal or Reduce Motion runtime walkthrough performed. No claim of full accessibility conformance. Real-device interruption/recovery and moderated OR-member/rep feedback remain required.

## Proposed interactive direction

The accompanying in-conversation proposal is a local interaction model, not an app build. It covers the three destinations plus setup/settings/contacts, case creation, retained review and explicit correction. It does not create native records, connect devices or place calls. It preserves explicit acknowledgment and records question context separately from later item changes.

A headless Chrome check exercised defer → acknowledge → question → acknowledge question → reply, case validation and correction/confirmation. No runtime script errors were observed. Root-width checks passed at 1024, 736, 360 and 320 px. This preview check is separate from native iPad accessibility evidence.
