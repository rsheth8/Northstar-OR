# F01 component evidence

Captured 2026-10-24 on an isolated iPad Pro 13-inch (M5), iOS 26.5 simulator, Xcode 26.6. Screenshots are 2064 × 2752 pixels with the starter's landscape content area letterboxed in the portrait simulator display. Viewport/shell correction remains F02; this does not certify full-screen layout.

The existing DEBUG `NorthstarComponentGallery` was temporarily used as the launch view. A temporary ScrollViewReader scrolled to banners for the separate banner captures. Both harness changes were reverted before commit; production app entry and gallery source are unchanged. Default, XXXL and largest accessibility sizes were set through `simctl ui content_size`, so these captures exercise actual environment text scaling.

- [Default components](default.png)
- [XXXL components](xxxl.png)
- [Largest accessibility components](largest.png)
- [Default warning/failure/local-mode banners](banners-default.png)
- [Largest accessibility banners](banners-largest.png)

Visual inspection: typography grows, primary appearance examples switch to a vertical arrangement at enlarged sizes, banner text wraps and actions stack at the largest accessibility size. Content beyond the visible area remains in the gallery's scroll view. The preceding fixed-font app baseline is retained in [F03 evidence](../f03/README.md); there was no component gallery in that baseline.

Focused/pressed/disabled gallery cells inject appearance state; screenshots do not prove hardware-keyboard focus acquisition or disabled input behavior. No VoiceOver, physical touch/glove, keyboard, Increase Contrast, or interactive Reduce Motion check was run. The source's minimum frames and conditional animation were reviewed; those do not replace device interaction verification. Those checks remain integration/rehearsal gaps, not claims of a completed accessibility audit.

The gallery simulator build passed. Required CI still gates the final merged branch independently. No new API/library/asset source was introduced; screenshots are captures of existing project UI.
