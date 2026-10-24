# Task board

Claim a task by changing `[ ]` to `[~] (your name)`. Mark `[x]` when it's merged.
One task per branch and PR. Lanes keep people and agents out of each other's files.

## Agreed product direction

Read [PRODUCT.md](PRODUCT.md) before choosing implementation work. Northstar helps teams coordinate support, track reported progress, and hand off context. It prompts and documents; it does not assess clinical correctness.

Priority: one coherent simulated procedure and a reliable support journey before additional procedure types, maps, or visual effects. The items below are implementation work, not claims that these capabilities already exist.

## Next implementation tasks (one task per branch/PR)
- [x] (Codex) **Shared design:** establish restrained clinical typography, flat controls, and quiet surfaces in `DesignSystem/`; preserve action sizes and semantic status colors (merged in [PR #8](https://github.com/rsheth8/Northstar-OR/pull/8)).
- [ ] **Shared state:** model support requests with requested / accepted / connected / unavailable states, named recipient, and support role; keep device reps distinct from clinical specialists (`Models/`, `App/AppModel.swift`, `Services/SyncService.swift`; shared-files PR).
- [ ] **Co-pilot:** distinguish unrecorded, deferred, and team-confirmed items; support corrections and prevent actions from bypassing a pending acknowledgment (`Features/CoPilot/`; separate shared-model PR if needed).
- [ ] **Co-pilot:** wire voice commands with visible listening state, duplicate-command handling, and touch fallback; require an explicit command rather than inferring completion from conversation (`Features/CoPilot/`, `Services/Voice*`).
- [ ] **Planner + Remote Support:** allow a team member to request help at any time; include their question, current context, unresolved items, recipient acknowledgment, and prominent incoming messages (`Features/Planner/`, `Features/RemoteSupport/`; coordinate shared state first).
- [ ] **Sync:** connect separate devices through `SyncService`, show connection state, and test disconnected behavior without implying a message was delivered (`Services/`; coordinate shared state first).
- [ ] **Shared data and copy:** make one fictional pacemaker workflow coherent; remove clinical-direction copy, replace "Procedure complete" with "Checklist complete," and stop reusing implant steps for the ICD generator-change example (`Data/` and feature copy; small coordinated PR).
- [ ] **Camera observation:** on mock labels only, show a captured frame, extracted text, proposed match, and explicit confirmation; unreadable or unseen means unknown, never skipped (feature implementation after a small shared-state PR).
- [ ] **AI assistant:** answer session questions and draft handoffs from recorded events; label drafts, preserve event sources, and review before sharing; choose an integration through `SyncService` and credit it before implementation.
- [ ] **Session review:** summarize confirmations, deferred items, corrections, and support interactions; label automated observations separately and decide persistence/export scope before implementing.
- [ ] **User validation:** review the workflow with an OR nurse and device rep; document assumptions and feedback without recording real case data (`docs/`).

## Open decisions (team call)
- [ ] **Sync backend.** Recommended: **MultipeerConnectivity**. It works with no Wi-Fi or accounts, which suits a hackathon room and the "works when the storm cuts the internet" story, and the iPad app also runs on Apple-silicon Macs for the laptop screen. Alternative: Firebase Firestore (easier across networks, but needs internet and setup).
- [ ] **Planner device for the demo.** Same app on the Mac (Designed for iPad), or a second iPad/iPhone.

## Lane A: Co-pilot (folders: `Features/CoPilot/`, `Services/Voice*`)
- [ ] Wire `VoiceCommandService` into `CoPilotView` (complete / skip / confirm), with a pulsing mic indicator
- [ ] Skipped-step moment: amber edge flash, pulsing step, spoken alert, haptic
- [ ] Smooth step transitions and the "alive" voice orb/waveform
- [ ] Reduced-support badge plus "normally covered by rep" hints styled per brand
- [ ] Show incoming remote prompts as a banner over the current step
- [ ] Test voice on the real iPad in a noisy room (early, not at hour 22)

## Lane B: Planner + Remote Support (folders: `Features/Planner/`, `Features/RemoteSupport/`)
- [ ] Minnesota map (MapKit) with hospital pins colored by risk
- [ ] Procedure detail: "why" reasons, ranked coverage options, one-tap flag to co-pilot
- [ ] Remote rep view: context package, live log, quick prompts
- [ ] Coverage Matcher: add a score breakdown so judges see why rep X won
- [ ] Optional after the core demo: evaluate weather integration against the simulated-data-only rule before implementation; keep the demo on fictional forecasts

## Lane C: Sync (folder: `Services/`)
- [ ] Implement the chosen backend as a `SyncService` conforming type
- [ ] Two-device test: planner flag flips the iPad into reduced-support mode live
- [ ] Stream co-pilot log entries to the remote rep view

## Lane D: Pitch and demo
- [x] (Codex) Refine the identity for institutional medical software: a restrained connected star/pulse, neutral wordmark, editable masters, and app assets (`docs/brand/`, app asset catalog; merged in [PR #9](https://github.com/rsheth8/Northstar-OR/pull/9)). Rural scenes are preserved as presentation artwork.
- [x] (Codex) Set up GitHub build/test checks, protected main without mandatory human approvals, PR defaults, and teammate/agent collaboration guide (merged in [PR #3](https://github.com/rsheth8/Northstar-OR/pull/3)); scheduled repo stewardship in the owner’s Codex chat every 15 minutes.
- [x] (Codex) Document agreed product direction, current implementation limits, and prioritized roadmap (`README.md`, `docs/PRODUCT.md`, `docs/TASKS.md`; merged in [PR #1](https://github.com/rsheth8/Northstar-OR/pull/1))
- [ ] Slide deck (due Sunday 12:00 PM CT)
- [ ] 3-minute demo script, judge triggers the skipped-step alert
- [ ] Record a backup screen capture of a perfect run
- [ ] Update the demo to show coverage disruption → support acceptance → recorded progress → support request with context; add camera/AI only when implemented and tested
- [ ] Update README credits and team names before submission
