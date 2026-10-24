<p align="center"><img src="docs/brand/lockup-horizontal-dark@2x.png" alt="Northstar OR" width="420"></p>

# Northstar OR

**A storm-aware surgical co-pilot for rural Minnesota hospitals.** Built in 24 hours for the Medtronic × UMN Social Coding Club hackathon, prompt: *Connect & Intersect*.

When a blizzard keeps the device rep or a visiting specialist from reaching a small-town hospital, Northstar OR connects the hospital team, the expert who can't get there, and the storm in between:

- **Planner + Coverage Matcher.** Ranks upcoming procedures by storm risk and matches each one to the best help: a rep who can still drive in, a remote rep on standby, or a reschedule.
- **iPad co-pilot.** A voice-driven step checklist for the OR team. It flags skipped required steps, says alerts out loud, and writes a timestamped log. It prompts and documents. It never makes clinical decisions.
- **Remote Support Link ("pull, don't call").** The remote rep is pulled in only when something deviates, and gets an auto-built context package instead of a cold video call.

> All data is simulated. Northstar OR is a hackathon prototype, not a medical device.

## Run it

Requirements: Xcode 15+, iPadOS 17+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate          # creates NorthstarOR.xcodeproj from project.yml
open NorthstarOR.xcodeproj
```

Pick your own team under *Signing & Capabilities*, then run on an iPad (landscape). The `.xcodeproj` is generated and git-ignored, so re-run `xcodegen generate` after pulling changes that add files.

## Project layout

```
NorthstarOR/
  App/              entry point, AppModel (shared state), RootView tabs
  DesignSystem/     NorthstarTheme.swift (colors, type, spacing, buttons)
  Models/           Hospital, DeviceRep, Procedure, LogEntry, ...
  Data/             SampleData (all simulated)
  Services/         SyncService (backend boundary), voice in/out
  Features/
    CoPilot/        CoPilotSession state machine + iPad view
    Planner/        CoverageMatcher engine + planner view
    RemoteSupport/  ContextPackage + remote rep view
NorthstarORTests/   unit tests for the matcher, session, and voice parsing
docs/               TASKS.md (who's doing what), brand/ (logo files)
```

## Team

- Rahil Sheth ([@rsheth8](https://github.com/rsheth8))
- *Partner: add your name here*

## Tools, libraries, and AI credits

Required by the hackathon rules. Keep this list up to date.

- Swift, SwiftUI, Observation, AVFoundation (text-to-speech), Speech (on-device recognition), MapKit
- XcodeGen for project generation
- Inter Display (SIL Open Font License) for the logo wordmark
- AI assistance: Claude (Anthropic) helped with brainstorming, the pitch proposal, the brand and logo, and the starter code scaffold. All code was written during the event.
