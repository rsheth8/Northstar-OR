# Laptop rep station

Use this from the integrated checkout on branch `sync/in-app-call-integrated`. It includes both the Focus Co-pilot/nearby-iPad exchange and the call. The primary checkout’s uncommitted Cursor work is preserved separately.

1. Join the laptop and room iPad to the same phone hotspot or local network.
2. From this checkout’s root, run `node RepPage/server.mjs`.
3. On **that laptop**, open **http://localhost:8080**, click **Join call**, allow the microphone, and wear headphones. **Mute microphone / Unmute microphone** controls the laptop’s outgoing call audio. The browser requires a secure context for microphone access; localhost qualifies. Opening the laptop’s IP over HTTP does not. See [MDN getUserMedia](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia#privacy_and_security).
4. Open the app generated from **this checkout** (`xcodegen generate`, then open `NorthstarOR.xcodeproj`). On the Room iPad, tap **Call rep**, enter the `ws://<laptop-ip>:8080` address printed by the server, and tap **Start call**. Allow local network, microphone, and camera access. A denied camera permits audio only; a denied microphone blocks the call. The call sheet shows a local preview of the same room camera track sent to the laptop. Its microphone button controls outgoing call audio, independently of device playback volume.
5. Once both sides say **In call**, send a question in Co-pilot or the call sheet. An earlier saved question has **Send this saved question**. The rep can acknowledge and reply independently. The room saves these through the same support record; the deferred item remains deferred.
6. **Done** closes the sheet while the call continues. **End call**, switching Room/Rep, selecting nearby-iPad discovery, or putting the app in the background stops the call. Ending keeps saved questions and replies.
7. To reconnect, click **Join call** on the laptop, then **Restart call** on the iPad. Explicitly retry a saved question or response if needed. Do not restart the server between normal calls.

Only one room and one rep page may join this local server at a time. It is an unauthenticated fictional demo, not an internet calling service. Peer-to-peer media needs network reachability; there is no TURN relay. Audio is two-way, camera video is room-to-laptop only, and simulator capture omits the camera. The server introduces the peers; media and support envelopes use WebRTC. The browser keeps questions/replies in session storage for this tab; the iPad retains them in the workspace repository. Neither side records media.

Focused checks: `node --test RepPage/server.test.mjs`; see `docs/evidence/nearby-support/CALL_INTEGRATION.md` for the simulator/browser journey and checks still needing hardware.

## Shared case session (foundation, version 4)

Run the server from the integrated worktree, restart it after server changes, and refresh the laptop page. Both devices use the same Wi-Fi. On iPad open **Call rep**, enter the laptop's `ws://<LAN-IP>:8080`, and choose **Share current case**. On the laptop open `http://localhost:8080` and choose **Join session**. This does not open either microphone or camera. The laptop receives current checklist state, all recorded session activity, and saved contextual support questions; it can acknowledge and reply before a call. Co-pilot and the native Remote tab use the same retained questions.

For a call, separately choose **Join call** on laptop and **Start call** on iPad. End call releases media while the shared session remains connected. **Leave session** / **Stop sharing and end call** close both. Rejoin/reshare manually after a server or Wi-Fi interruption. The data server supports one room and one rep independently of the media pair.

This foundation is not the entire approved shared-session design. Generic multi-message chat, call request/accept/decline, camera switching/off-on, alerts and refined layouts still need implementation; see `docs/CURSOR_SHARED_SESSION_HANDOFF.md`. The new native/browser Wi-Fi session has a passing build and focused automated checks but still needs a physical-device walkthrough. The preceding media-only call was reported working by the owner.
