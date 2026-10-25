# Laptop rep station

Use this from the integrated checkout on branch `sync/in-app-call-integrated`. It includes both the Focus Co-pilot/nearby-iPad exchange and the call. The primary checkout’s uncommitted Cursor work is preserved separately.

1. Join the laptop and room iPad to the same phone hotspot or local network.
2. From this checkout’s root, run `node RepPage/server.mjs`.
3. On **that laptop**, open **http://localhost:8080**, click **Join call**, allow the microphone, and wear headphones. The browser requires a secure context for microphone access; localhost qualifies. Opening the laptop’s IP over HTTP does not. See [MDN getUserMedia](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia#privacy_and_security).
4. Open the app generated from **this checkout** (`xcodegen generate`, then open `NorthstarOR.xcodeproj`). On the Room iPad, tap **Call rep**, enter the `ws://<laptop-ip>:8080` address printed by the server, and tap **Start call**. Allow local network, microphone, and camera access. A denied camera permits audio only; a denied microphone blocks the call.
5. Once both sides say **In call**, send a question in Co-pilot or the call sheet. An earlier saved question has **Send this saved question**. The rep can acknowledge and reply independently. The room saves these through the same support record; the deferred item remains deferred.
6. **Done** closes the sheet while the call continues. **End call**, switching Room/Rep, selecting nearby-iPad discovery, or putting the app in the background stops the call. Ending keeps saved questions and replies.
7. To reconnect, click **Join call** on the laptop, then **Restart call** on the iPad. Explicitly retry a saved question or response if needed. Do not restart the server between normal calls.

Only one room and one rep page may join this local server at a time. It is an unauthenticated fictional demo, not an internet calling service. Peer-to-peer media needs network reachability; there is no TURN relay. Audio is two-way, camera video is room-to-laptop only, and simulator capture omits the camera. The server introduces the peers; media and support envelopes use WebRTC. The browser keeps questions/replies in session storage for this tab; the iPad retains them in the workspace repository. Neither side records media.

Focused checks: `node --test RepPage/server.test.mjs`; see `docs/evidence/nearby-support/CALL_INTEGRATION.md` for the simulator/browser journey and checks still needing hardware.
