# Task board

Claim a task by changing `[ ]` to `[~] (your name)`. Mark `[x]` when it's merged.
One task per branch and PR. Lanes keep people and agents out of each other's files.

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
- [ ] Optional: live weather (NWS API) behind a toggle, falling back to sample data

## Lane C: Sync (folder: `Services/`)
- [ ] Implement the chosen backend as a `SyncService` conforming type
- [ ] Two-device test: planner flag flips the iPad into reduced-support mode live
- [ ] Stream co-pilot log entries to the remote rep view

## Lane D: Pitch and demo
- [ ] Slide deck (due Sunday 12:00 PM CT)
- [ ] 3-minute demo script, judge triggers the skipped-step alert
- [ ] Record a backup screen capture of a perfect run
- [ ] Update README credits and team names before submission
