> Cursor handoff plan, preserved for context. The integrated implementation and actual verification supersede the original standalone payload and laptop-IP browser instructions: see `docs/evidence/nearby-support/CALL_INTEGRATION.md` and `RepPage/README.md`.

# In-app nearby call for an iPad and a laptop

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The room iPad places an in-app audio and video call to a rep page on a laptop. The rep hears the room with echo cancellation, sees the room camera, and receives the same support question the iPad recorded.

**Architecture:** Use WebRTC, the open-source real-time stack. The iPad app uses the prebuilt `stasel/WebRTC` binary. The laptop opens a small Northstar rep page in a browser, which already contains WebRTC. A signaling server on the laptop only exchanges the offer, answer, and network candidates. After that, audio, video, and the support question travel peer to peer on the local network. WebRTC's audio engine supplies Opus, acoustic echo cancellation, noise suppression, and the jitter buffer. Do not send raw microphone samples over Multipeer.

**Tech Stack:** `https://github.com/stasel/WebRTC` release `155.0.0` (official WebRTC, BSD). Connection flow adapted from `https://github.com/stasel/WebRTC-iOS` (Apache-2.0). Browser rep page uses the built-in `RTCPeerConnection`. No FaceTime. No paid call vendor.

**Spec:** This file. Question values stay in `NorthstarOR/Models/SupportExchange.swift` on `sync/nearby-support-exchange`. Send those envelopes on the WebRTC data channel. The silent JPEG plan in `2026-10-24-nearby-camera.md` is not the demo.

## Global Constraints

- The call UI lives inside Northstar on the iPad. The laptop client is `RepPage/index.html` from this repo, not FaceTime, Discord, or Meet.
- Views never import `WebRTC`. `Services/NearbyCallSession.swift` owns the peer connection. `AppModel` starts and stops it.
- Audio is two-way. Video is one-way, from the room iPad's back camera to the laptop. The laptop sends a microphone and no camera.
- Capture at 640×480 and 24 fps. Do not pick the camera's largest format. Large frames add delay.
- Audio session mode is `.voiceChat` with category `.playAndRecord`, so WebRTC can cancel echo. Preferred IO buffer is 20 ms.
- The support question, acknowledgment, and reply are JSON `SupportEnvelope` values on an ordered, reliable data channel named `northstar`. A video frame never changes a checklist item.
- Signaling URL is typed into both sides. It is `ws://<laptop-LAN-ip>:8080`. Do not use `localhost`. Google's public STUN servers are allowed only to gather candidates: `stun:stun.l.google.com:19302`. Media should use a local host candidate. If the venue network blocks device-to-device traffic, move both devices to a phone hotspot and try again.
- Same-room speaker feedback can still beat echo cancellation. The rep uses headphones. The iPad speaker plays the rep for the audience.
- Credit WebRTC's BSD license and the Apache-2.0 demo the signaling server is adapted from in `README.md` in this change.
- Do not stage the dirty planning docs in the primary checkout. Do not push unless asked.
- Unit tests do not open a camera or a socket. They cover envelope bytes on a fake data channel and the rule that a call message cannot confirm a checklist item.

## File structure

- Create `NorthstarOR/Services/NearbyCallSession.swift` — peer connection, audio, camera, data channel.
- Create `NorthstarOR/Features/CoPilot/NearbyCallView.swift` — in-app call controls and remote-status label.
- Create `RepPage/index.html` — laptop rep station.
- Create `RepPage/server.mjs` — local signaling server adapted from the WebRTC-iOS Node broadcast server.
- Modify `project.yml` — Swift package and privacy strings.
- Modify `NorthstarOR/App/AppModel.swift` — start, stop, mute, and forward envelopes.
- Modify `README.md` — credits.
- Modify `docs/evidence/nearby-support/README.md` — device checks left as not run.

---

### Task 1: Add the binary and the call session

**Files:**
- Modify: `project.yml`
- Create: `NorthstarOR/Services/NearbyCallSession.swift`
- Test: `NorthstarORTests/NearbyCallTests.swift`

**Interfaces:**
- Produces: `NearbyCallSession.start(signalingURL:)`, `stop()`, `setMuted(_:)`, `send(_ envelope: SupportEnvelope)`, `onEnvelope`, `onState`.

- [ ] **Step 1: Add the package**

In `project.yml`, at the top level:

```yaml
packages:
  WebRTC:
    url: https://github.com/stasel/WebRTC.git
    exactVersion: 155.0.0
```

On the app target dependencies:

```yaml
dependencies:
  - package: WebRTC
    product: WebRTC
```

Replace the microphone usage string with: `Northstar OR uses the microphone for the in-app call with a nearby technical rep and for spoken checklist commands. Audio is not saved.`

Add: `INFOPLIST_KEY_NSCameraUsageDescription: "Northstar OR uses the room iPad camera so the nearby rep can see a fictional device label during the in-app call. Video is not saved and does not confirm a checklist item."`

Run `xcodegen generate`. Do not commit the generated project.

- [ ] **Step 2: Write a failing rule test**

```swift
func testCallPayloadDoesNotConfirmTheDeferredLine() throws {
    let session = try makeRoomSession()
    _ = try session.apply(try XCTUnwrap(session.makeCommand(.deferItem)))
    let before = session.recordingState
    let envelope = SupportEnvelope.question(try makeQuestion())
    XCTAssertFalse(NearbyCallMessage.isChecklistCommand(envelope))
    XCTAssertEqual(session.recordingState, before)
}
```

`NearbyCallMessage.isChecklistCommand` returns false for every `SupportEnvelope`. The test's `makeQuestion` uses the real `SupportQuestion.make` from the Codex branch. Expected before the helper exists: compile failure.

- [ ] **Step 3: Build a thin peer connection**

Adapt the flow in `stasel/WebRTC-iOS` `WebRTCClient.swift`. Do not copy that demo's UI. In `NearbyCallSession`:

- `RTCPeerConnectionFactory` once.
- `RTCConfiguration` with the Google STUN URL and `continualGatheringPolicy = .gatherContinually`.
- `sdpSemantics = .unifiedPlan`.
- Audio track with default constraints. Before capture, set `RTCAudioSession` category `.playAndRecord` and mode `.voiceChat`.
- Video track from `RTCCameraVideoCapturer` on the back camera, 640×480, 24 fps. On the simulator, skip capture and expose `Camera unavailable in the simulator`.
- Data channel label `northstar`, ordered and reliable. Outgoing `SupportEnvelope` is JSON. Incoming JSON calls `onEnvelope`.
- `start` connects a `URLSessionWebSocketTask` to the signaling URL. The room sends an offer. The laptop page sends the answer. ICE candidates are forwarded as they arrive.
- States shown to the app: `Signing in`, `In call`, `Call failed`, `Call ended`.

- [ ] **Step 4: Run the unit test**

Expected: the checklist assertion passes. The peer connection is not opened in the test.

- [ ] **Step 5: Commit**

```bash
git add project.yml NorthstarOR/Services/NearbyCallSession.swift NorthstarORTests/NearbyCallTests.swift
git commit -m "$(cat <<'EOF'
Add an in-app WebRTC call that leaves checklist state unchanged.

EOF
)"
```

---

### Task 2: Laptop rep page and local signaling

**Files:**
- Create: `RepPage/server.mjs`
- Create: `RepPage/index.html`
- Create: `RepPage/README.md`

- [ ] **Step 1: Signaling server**

`server.mjs` listens on `0.0.0.0:8080`. It broadcasts each JSON message to every other connected socket. Messages are `{ "type": "offer"|"answer"|"candidate", "payload": ... }`. It also serves `index.html` on `http://0.0.0.0:8080/`. No npm dependencies. Use `node RepPage/server.mjs`.

- [ ] **Step 2: Rep page**

The page uses the browser's `RTCPeerConnection`. It gets microphone audio only, receives the iPad video into a `<video autoplay playsinline>`, and opens the `northstar` data channel when the iPad creates it.

Visible regions, in order: the video, `In call` or `Waiting for the room iPad`, the latest question text, unresolved line titles from the envelope snapshot, **Acknowledge question**, a reply field, and **Send reply**. Acknowledgments and replies are `SupportEnvelope` JSON on the data channel. A line under the video reads `This call does not confirm a checklist item.`

The page uses the Northstar light background `#F4F7FB` and ink `#122033` if those tokens are the current palette; otherwise use the values already in `Northstar.Palette`. No orb, no pulsing border.

- [ ] **Step 3: Run instructions**

`RepPage/README.md` says: connect the laptop and iPad to the same hotspot, run `node RepPage/server.mjs`, open `http://<laptop-ip>:8080` on the laptop, and paste `ws://<laptop-ip>:8080` into the iPad. Headphones on the laptop.

- [ ] **Step 4: Commit**

```bash
git add RepPage README.md
git commit -m "$(cat <<'EOF'
Add the laptop rep page for the in-app nearby call.

EOF
)"
```

The README commit in Task 4 adds the license credit. This commit may include only `RepPage/`.

---

### Task 3: iPad call controls

**Files:**
- Create: `NorthstarOR/Features/CoPilot/NearbyCallView.swift`
- Modify: `NorthstarOR/Features/CoPilot/CoPilotView.swift`
- Modify: `NorthstarOR/App/AppModel.swift`

- [ ] **Step 1: Controls**

A field labeled `Signaling server`, placeholder `ws://192.168.1.20:8080`. Buttons: **Start call**, **Mute**, **End call**. Each is at least 44 pt. **Start call** is 72 pt. Status uses `NorthstarStatusLabel`: `In call`, `Signing in`, `Call failed`, or `Call ended`. The local camera is not a second full-screen view. The rep's voice plays through the speaker.

Starting the call does not defer, confirm, or acknowledge a checklist item. Ending the call leaves the question on screen.

When a question is sent, `AppModel` also calls `nearbyCall.send(envelope)` if the call state is `In call`. Incoming envelopes use the existing `SupportExchange.apply` path. A failed call send keeps the local question and shows `Not sent. Your question is kept.`

- [ ] **Step 2: Build the app**

`xcodegen generate`, then build the NorthstarOR scheme for a generic iOS Simulator. Expected: BUILD SUCCEEDED. Camera and microphone prompts are not exercised here.

- [ ] **Step 3: Commit**

```bash
git add NorthstarOR/Features/CoPilot/NearbyCallView.swift NorthstarOR/Features/CoPilot/CoPilotView.swift NorthstarOR/App/AppModel.swift
git commit -m "$(cat <<'EOF'
Put the nearby call controls on the room iPad.

EOF
)"
```

---

### Task 4: Credits and the device check

**Files:**
- Modify: `README.md`
- Modify: `docs/evidence/nearby-support/README.md`

- [ ] **Step 1: Credits**

Add a credits entry: WebRTC, BSD-3-Clause, `https://webrtc.googlesource.com/src`, binary distribution `https://github.com/stasel/WebRTC` 155.0.0. Signaling behavior adapted from `https://github.com/stasel/WebRTC-iOS`, Apache-2.0. State that the call audio processing, Opus, and video codecs come from that library.

- [ ] **Step 2: Checks, left as not run until a human does them**

1. Laptop runs `node RepPage/server.mjs`. iPad starts the call. Both say `In call` within 10 seconds on a phone hotspot.
2. A person speaking at the iPad is intelligible in the laptop headphones. The rep's reply is intelligible from the iPad speaker. No persistent echo.
3. The room defers a line and sends a question. The laptop shows that text and the deferred line. The rep replies. The iPad shows the reply and the line is still deferred.
4. End the call. The question remains. Covering the camera changes the picture and does not change the checklist.

- [ ] **Step 3: Commit**

```bash
git add README.md docs/evidence/nearby-support/README.md
git commit -m "$(cat <<'EOF'
Credit WebRTC and list the in-app call checks still to run.

EOF
)"
```

## Demo setup

1. Phone hotspot, laptop and iPad both joined.
2. `node RepPage/server.mjs` on the laptop. Open the page. Headphones on.
3. iPad: **Start call** with `ws://<laptop-ip>:8080`.
4. Defer a line, send the question, answer it on the laptop, show the reply on the iPad with the line still open.
5. If the call fails, keep the question flow and say the call did not connect. Do not switch to FaceTime during the talk.

## Out of scope

- A second native Mac target, CallKit, push notifications, recording, a TURN server, and two-way video.
- Multipeer as the audio path.
- Treating the browser page as a hospital system.
