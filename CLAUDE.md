# Northstar OR: instructions for agents and teammates

Read this before changing anything. Then read `docs/PRODUCT.md`, `docs/PRODUCT_FOUNDATION.md`, `docs/DESIGN.md`, `docs/TEAM_WORKFLOW.md`, and `docs/TASKS.md`, and claim a task.

## What we're building
A native SwiftUI iPad app (iPadOS 17+) for a 24-hour Medtronic hackathon. Prompt: *Connect & Intersect*.
Three features, one app, three tabs: **Co-pilot** (the demo star), **Planner** with the Coverage Matcher, and **Remote Support Link**.
Deadline: slide deck and repo due **Sunday 12:00 PM CT**. Polish beats breadth.

Product bar: functional fictional workspace setup, editable contacts, normal case creation/start/resume and retained records. Samples are optional content, never the only working code path. The presentation is **five minutes** and demonstrates that normal product workflow. See `docs/PRODUCT_FOUNDATION.md` for core scope; persistence is P0. The current starter has not implemented that scope yet.

## Hard rules
- **Simulated data only.** No real patients, hospitals' real data, or real people. Keep fake data in `NorthstarOR/Data/`.
- **The app prompts and documents. It never makes clinical decisions.** Don't write copy or features that diagnose, dose, or tell a surgeon what to do clinically.
- **Code written during the event only.** Don't paste in old personal projects.
- **Credit every new library, API, or asset** in the README's credits section in the same PR that adds it.
- **No Timberwolves or other team marks.** Use the brand in `docs/brand/`.

## How we work in parallel
- **Never commit `.xcodeproj`.** It's generated from `project.yml` with `xcodegen generate`. New Swift files under `NorthstarOR/` are picked up automatically; only edit `project.yml` for build settings, Info.plist keys, or new targets.
- **All agents:** preserve teammate edits, use separate checkouts for concurrent writers, and report only checks actually run. Review your diff and rely on required CI; human approval is optional. Never fabricate a GitHub approval.
- Follow `docs/PARTNER_EXECUTION.md` for Rahil/Amartya ownership and shared-file reservations; `docs/AGENT_BRIEFS.md` contains bounded task prompts. Planned ownership is not an active claim. Use merged interfaces and one driver per checkout/file set.
- **One task = one branch = one small PR.** Branch names: `copilot/...`, `planner/...`, `sync/...`, `pitch/...`. Rebase on `main` before opening the PR.
- **Stay in your lane's folders** (see `docs/TASKS.md`). Shared files (`Models/`, `App/AppModel.swift`, `Services/SyncService.swift`, `DesignSystem/`) change in their own small PRs so conflicts stay tiny.
- **Features talk to the backend only through `SyncService`.** Don't call a network SDK from a view.
- Mark your task `[~] (name)` in `docs/TASKS.md` when you start and `[x]` when merged.
- Keep `NorthstarORTests` passing: `xcodebuild test -scheme NorthstarOR -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` (pick any installed iPad simulator).

## Design system
- Follow the screen contracts, state rules, and review criteria in `docs/DESIGN.md`. The approved direction is restrained institutional software: neutral type, flat controls, quiet surfaces, and the connected star/pulse identity.
- Use the operational patterns in `docs/DESIGN_REFERENCES.md`: case worklists, persistent workspace/case/support context, clear forms and accountable actions. Optional AI drafts are secondary; public vendor material is inspiration, not proof of Northstar validation.
- Use `Northstar.Palette`, `Northstar.Fonts`, `Northstar.Space`, `Northstar.Radius` from `DesignSystem/NorthstarTheme.swift`. No raw hex colors in views.
- Dark theme, landscape iPad first; adapt to available window space and Dynamic Type. Primary actions are at least 72 pt high and 72 pt wide; other hit areas are at least 44 × 44 pt.
- Color meaning: aurora green = go/done, amber = skipped step / warning, red (`alert`) = stop. Always pair color with an icon and a label.
- Color describes the recorded workflow or app state, never clinical readiness. Availability, acceptance, connection, delivery, and acknowledgment are distinct; show only states the implementation supports.
- Keep warnings persistent and purposeful. No decorative glow, bouncing controls, voice orb, repeated pulsing, or flashing screen borders. Respect Reduce Motion and retain touch alternatives to voice.
- Voice: calm and short. Speak only for important moments, e.g. "Step 4 was deferred. Acknowledgment required."
- Logo files: `docs/brand/` (SVG). App icon lives in the asset catalog.
- UI PRs include named-size screenshots, relevant empty/failure/warning states, and enlarged-text evidence. Report the contrast, touch, VoiceOver, keyboard, and Reduce Motion checks actually run, with remaining gaps.

## Architecture in one breath
`AppModel` (Observable) holds sample data, the active `CoPilotSession`, and a `SyncService`.
The planner sends `SyncEvent`s (e.g. `.reducedSupportChanged`) through `SyncService`; `AppModel` routes them into the co-pilot session.
`CoverageMatcher` is pure and rule-based so it's testable and explainable to judges.
