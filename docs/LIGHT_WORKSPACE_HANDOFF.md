# Light workspace migration handoff

The owner approved a light hospital worklist with a midnight-blue header on October 24, 2026. DESIGN.md is canonical; this handoff explains the implementation boundary. The reference concept was inspected directly. Its placeholder wordmark, fictional rows, control sizes and proposed states are not implementation specifications or verification evidence.

## Foundation delivered

`Northstar.Palette.Workspace` adds opaque semantic colors for light surfaces, dark text, header, actions, selection, focus and recorded states. It does not change existing consumers. This avoids recoloring light-on-dark custom controls or system controls before their complete foreground/background treatment is migrated. Existing F01 Dynamic Type, target and spacing tokens remain applicable. No new dependency or asset was added.

Use `text`/`textSecondary` on working surfaces and `onHeader`/`onHeaderSecondary` only on `header`. Use `onAction` on `action` or `actionPressed`. A selected row uses `selection`, `text`, and a narrow `selectionIndicator` rail, plus the accessibility selected trait. Keep green confirmation independent of selection. Use status foregrounds on their paired surfaces, with icons and explicit labels. `divider` is decorative; use `boundary` for essential outlines. Never derive text contrast by reducing opacity.

## Next bounded slices

1. **Shared controls:** migrate primary/secondary/status/banner controls together with a named light component gallery. Standard primary actions use blue; success remains a recorded-state treatment. Preserve dynamic labels, 72 pt primary and 44 pt secondary targets, gaps, pressed/disabled/focus treatments. Use proportional activity text and monospaced digits where useful. Verify default, XXXL and accessibility5, localized warning, empty and failed-send examples before changing existing palette consumers.
2. **F02 shell:** reserve RootView and any necessary app bootstrap settings separately. Use approved logo assets, midnight header, workspace/actual mode/settings and native destination navigation. Inspect actual iPadOS 17+ viewport and narrow-window behavior. Existing forced-dark environment settings must be reconciled with native forms and sheets during migration. Do not invent configured workspace or working settings while F25/F07 are missing.
3. **Planner reference:** after F07/F18/F25/F26/F27 and matcher dependencies merge, migrate F11/F28 using DESIGN.md's detail order and worklist structure. Browse selection remains distinct from active recording. Show only implemented request/recording states. No local substitute stores or decorative New case/Start controls.
4. **Co-pilot F09/F10:** use the shared shell/components and merged session contract. Collapse activity before current work, remove the whole-screen warning border, and retain the pinned deferral guard and available support/correction. These changes belong to its feature owner.
5. **Remote Support F12:** use the immutable request snapshot after shared orchestration lands. Place acknowledgment near the exact question, separate later changes, and keep draft/send reachable with the keyboard. Preserve failed drafts.

The user-approved visual reference puts Planner first for the full visual treatment; state and ownership dependencies remain unchanged. Setup/persistence and ordinary case workflows are still acceptance requirements, not claims made by this foundation PR.

## Verification gate

See [actual foundation evidence](evidence/light-workspace/README.md). Full Xcode and simulator tooling are absent on this machine. Required CI must verify compilation. Before screen migration is considered complete, obtain named-size before/after and default/enlarged-text images, relevant empty/warning/failure states, and actual touch, VoiceOver, keyboard, Increase Contrast, Differentiate Without Color and Reduce Motion checks. The opt-in palette has no visible application effect yet.
