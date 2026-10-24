# Northstar OR: instructions for agents and teammates

Read this before changing anything. Then read `docs/PRODUCT.md`, `docs/TEAM_WORKFLOW.md`, and `docs/TASKS.md`, and claim a task.

## What we're building
A native SwiftUI iPad app (iPadOS 17+) for a 24-hour Medtronic hackathon. Prompt: *Connect & Intersect*.
Three features, one app, three tabs: **Co-pilot** (the demo star), **Planner** with the Coverage Matcher, and **Remote Support Link**.
Deadline: slide deck and repo due **Sunday 12:00 PM CT**. Polish beats breadth.

## Hard rules
- **Simulated data only.** No real patients, hospitals' real data, or real people. Keep fake data in `NorthstarOR/Data/`.
- **The app prompts and documents. It never makes clinical decisions.** Don't write copy or features that diagnose, dose, or tell a surgeon what to do clinically.
- **Code written during the event only.** Don't paste in old personal projects.
- **Credit every new library, API, or asset** in the README's credits section in the same PR that adds it.
- **No Timberwolves or other team marks.** Use the brand in `docs/brand/`.

## How we work in parallel
- **Never commit `.xcodeproj`.** It's generated from `project.yml` with `xcodegen generate`. New Swift files under `NorthstarOR/` are picked up automatically; only edit `project.yml` for build settings, Info.plist keys, or new targets.
- **All agents:** preserve teammate edits, use separate checkouts for concurrent writers, and report only checks actually run. The other teammate reviews; never approve your own work.
- **One task = one branch = one small PR.** Branch names: `copilot/...`, `planner/...`, `sync/...`, `pitch/...`. Rebase on `main` before opening the PR.
- **Stay in your lane's folders** (see `docs/TASKS.md`). Shared files (`Models/`, `App/AppModel.swift`, `Services/SyncService.swift`, `DesignSystem/`) change in their own small PRs so conflicts stay tiny.
- **Features talk to the backend only through `SyncService`.** Don't call a network SDK from a view.
- Mark your task `[~] (name)` in `docs/TASKS.md` when you start and `[x]` when merged.
- Keep `NorthstarORTests` passing: `xcodebuild test -scheme NorthstarOR -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` (pick any installed iPad simulator).

## Design system
- Use `Northstar.Palette`, `Northstar.Fonts`, `Northstar.Space`, `Northstar.Radius` from `DesignSystem/NorthstarTheme.swift`. No raw hex colors in views.
- Dark theme, landscape iPad, glove-friendly targets (min 72 pt for primary actions).
- Color meaning: aurora green = go/done, amber = skipped step / warning, red (`alert`) = stop. Always pair color with an icon and a label.
- Voice: calm and short. Speak only for important moments, e.g. "Step 4 was skipped. Confirm to continue."
- Logo files: `docs/brand/` (SVG). App icon lives in the asset catalog.

## Architecture in one breath
`AppModel` (Observable) holds sample data, the active `CoPilotSession`, and a `SyncService`.
The planner sends `SyncEvent`s (e.g. `.reducedSupportChanged`) through `SyncService`; `AppModel` routes them into the co-pilot session.
`CoverageMatcher` is pure and rule-based so it's testable and explainable to judges.
