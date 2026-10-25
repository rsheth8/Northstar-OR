# Calls alongside the workspace

Owner-authorized follow-up to PR #47, branch `copilot/workspace-calls`.

## Behavior

- Request call appears in Co-pilot support, Request support, and Remote Support beside messaging. The paired participant accepts/declines; requesting does not start capture. A draft remains saved when requesting a call.
- Incoming requests appear in a workspace panel; accepting closes the old call sheet. The room keeps its Focus checklist and the rep keeps the live session record, selected item and messages.
- Wide windows reserve a 320 pt call dock. Float video opts into a draggable, clamped in-app tile; Dock video restores the reserved space. Narrow windows and accessibility text use a bottom panel with compact/expand controls.
- Video can be hidden without stopping audio or camera sharing. Your preview, camera status, mute/unmute, camera off/on, flip when supported, and end call are available. Mute/camera/end stay outside the media scroll region at standard text sizes; accessibility text scrolls the controls together so large labels remain reachable. This is in-app video, not system Picture in Picture/background calling.
- Both native participants request camera permission after acceptance. Rep starts with the front camera; room starts with the back camera. Denied/unavailable local camera preserves receive-video and audio capability. Local camera state and peer camera state are separate; turning off your camera does not hide their feed.
- Request support now exposes explicit “Ask about this item” buttons; tapping adds a topic to the retained question draft without sending or changing a checklist state. The recorded status labels are read-only. Send question is beside the question, above the attached context.
- The existing native session transport retains its case scoping, room recording authority, invitation expiry, message receipt and disconnect behavior. No new dependency or transport.

## Verification

- 157 existing unit tests passed after the call changes; no domain behavior was changed by the subsequent question-topic scroll feedback fix.
- Two focused UI checks passed on iPad Pro 13-inch (M5, 12 GB), iOS 26.5, landscape, standard and accessibility XXXL text. They verify call entry is correctly disabled without a peer, draft survives close/reopen, a topic action inserts text, Send question works, and the pending deferral remains unresolved.
- `help-landscape-disconnected.png` and `help-accessibility5-disconnected.png` are original simulator captures from that passing run (2064 × 2752 pixel buffers with landscape orientation metadata).
- Signed Mac Catalyst and physical-iPad builds succeeded. Repository checks and whitespace checks passed.

 Physical recheck is required for the new Mac camera feed, minimizing/floating while making checklist changes, mute/camera controls, and end/repeat call. Earlier owner confirmation of native two-way audio and room video applies to PR #47, not a fresh validation of this follow-up.

Touch sizes use existing 72 pt request and 44 pt secondary controls. No animation added; drag is direct manipulation and Dock video offers a touch alternative. VoiceOver labels are provided; full VoiceOver navigation, keyboard-only operation, contrast measurement and physical Reduce Motion remain unrun.
