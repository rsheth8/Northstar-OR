# Native iPad shell — actual rendering evidence

CI run [40142953421](https://github.com/rsheth8/Northstar-OR/actions/runs/40142953421), commit 0c72050: 69 unit tests and two UI capture tests passed. The runner selected **iPad Pro 13-inch (M5), iPadOS 26.2**, landscape. The app deployment target remains iPadOS 17. Screenshots are actual simulator output at default and accessibility5 text; they are not mockups. Native iPadOS 26 tab placement is at the top, rather than the iPadOS 17-style bottom tabs in the concept.

Inspected the default Co-pilot/Planner and accessibility5 Co-pilot captures. The native tab/shell and light surface migration render. These are **before feature-layout migration**: the old Co-pilot columns still squeeze enlarged text and its upcoming icons lack contrast. The separate Co-pilot PR addresses those layouts and indicators. Planner currently shows its original selection-empty view. Screenshots of final feature layouts will be recorded in their slices.

The first capture exposed black status-bar text over navy. Follow-up confines the navy header background to its own safe bounds so the status area uses the light canvas. Verification of that follow-up is the next CI run.

Local repository and whitespace checks passed. The existing opaque-pair contrast calculation passed; primary controls retain 72 pt minimum dimensions and secondary controls 44 pt by code inspection. No physical-device touch, VoiceOver, keyboard navigation, Increase Contrast, Differentiate Without Color or Reduce Motion interaction pass was performed. UI captures do not prove those checks. No native build was run on this Mac because full Xcode/XcodeGen are absent; CI performs the native build/tests.

No new libraries, APIs or application artwork were introduced. The identity strip uses the existing BrandMark asset. Workspace setup/settings and actual support request/receipt state remain pending domain slices; the shell honestly labels the current sample workspace and local communication mode.
