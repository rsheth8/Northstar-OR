<p align="center"><img src="docs/brand/lockup-horizontal-dark@2x.png" alt="Northstar OR" width="420"></p>

# Northstar OR

**A storm-aware surgical co-pilot for rural Minnesota hospitals.** Built in 24 hours for the Medtronic × UMN Social Coding Club hackathon, prompt: *Connect & Intersect*.

When a blizzard prevents an expert from reaching a small-town hospital, Northstar OR helps the team arrange support, track reported workflow progress, and share context. Device representatives provide technical device support; clinical specialists have distinct roles and responsibilities.

- **Planner + Coverage Matcher.** Surfaces coverage risk and ranks logistical options for human review. Planned readiness tracking distinguishes an available rep from someone who has accepted a support request.
- **iPad Co-pilot.** Tracks team-reported checklist progress, surfaces unresolved confirmations, and records timestamped events. Voice controls and focused camera observations are planned extensions. It prompts and documents; it never makes clinical decisions.
- **Remote Support Link.** Prepares context so a human expert can join with the team's question, current workflow, and unresolved items. Teams should be able to request help at any time; a deviation is not a prerequisite.

> All data is simulated. Northstar OR is a hackathon demonstration and is not validated or intended for clinical use. It does not verify surgical correctness or determine whether a procedure should proceed.

## Start here with your partner

Read [the product brief](docs/PRODUCT.md) for the agreed experience, boundaries, camera/AI scope, and demo. Read [the team workflow](docs/TEAM_WORKFLOW.md), then claim one task in [the task board](docs/TASKS.md). Build one coherent simulated procedure before broadening to other procedure types.

**Core journey:** coverage disruption → a human accepts support → the team records progress → a team member requests help → the expert receives context → the team reviews the session record.

## What works today

This repository contains a starter app, not the full experience described above.

| Capability | Current implementation | Next intended behavior |
| --- | --- | --- |
| Planner | Fictional forecasts, rule-based coverage options, reasons, and a reduced-support flag | Support readiness, named owner, and accepted coverage |
| Co-pilot | Touch checklist, skip acknowledgment, spoken skip alert, timestamped in-memory log | Connected voice controls, deferred/unrecorded states, corrections, and prominent support messages |
| Voice input | Command parser and recognition service exist; the view does not use them | Explicit complete / skip / confirm commands with listening status and touch fallback |
| Remote support | Context package and text prompts between tabs in one app instance | Requests at any time, recipient acknowledgment, and communication across devices |
| Sync | `LocalSyncService` distributes events within one process | Separate-device transport with honest delivery/connection status |
| Camera / computer vision | Not implemented | Narrow observations of fictional labels or training materials, shown for human confirmation |
| Conversational AI | Not implemented; spoken alerts use text-to-speech | Session-grounded questions and reviewable handoff drafts |
| Session record | In-memory log; no durable export | Reviewable summary with source labels; persistence/export scope still to be decided |

Known scaffold gaps: the ICD generator-change sample reuses pacemaker implant steps; some sample copy sounds like clinical instruction; the completion screen says "Procedure complete" although it only tracks checklist progress. These are explicit follow-up tasks, not validated procedure workflows.

## Run it

Requirements: Xcode 15+, iPadOS 17+, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate          # creates NorthstarOR.xcodeproj from project.yml
open NorthstarOR.xcodeproj
```

Pick your own team under *Signing & Capabilities*, then run on an iPad (landscape). The `.xcodeproj` is generated and git-ignored, so re-run `xcodegen generate` after pulling changes that add files.

## Before opening a PR

Run `bash scripts/check-repo.sh` and `bash scripts/check.sh`. GitHub runs repository checks and the iPad build/tests on every PR. See [the team workflow](docs/TEAM_WORKFLOW.md) for branches, review, pairing, and recovery.

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
docs/               PRODUCT.md (agreed direction), TASKS.md (work), brand/ (logos)
```

## Team

- Rahil Sheth ([@rsheth8](https://github.com/rsheth8))
- *Partner: add your name here*

## Tools, libraries, and AI credits

Required by the hackathon rules. Keep this list up to date.

- Swift, SwiftUI, Observation, AVFoundation (text-to-speech), Speech (on-device recognition), MapKit
- XcodeGen for project generation
- GitHub Actions with `actions/checkout` and `actions/upload-artifact` for CI; Dependabot for action updates
- Inter Display (SIL Open Font License) for the logo wordmark
- Blender (GPL) to model and render the 3D emblem; Google Chrome (headless) to export the logo PNGs. Both are build tools only, run from `docs/brand/source/`.
- AI assistance: Claude (Anthropic) helped with brainstorming, the pitch proposal, the brand and logo, and the starter code scaffold. All code was written during the event.
- AI assistance: OpenAI Codex helped review the starter implementation and document the product direction, implementation status, and task roadmap. No AI runtime or new camera library was added by this documentation update.
