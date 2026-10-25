# Two-iPad demonstration check — NOT RUN

Use fictional workspaces, contacts and cases only. This is a nearby coordination demo; peer names and Room/Rep roles do not verify identity. No clinical readiness is inferred.

1. Install this branch on two iPads. Create independent fictional workspaces. Choose Room on A and Rep on B. Confirm starting or recording a checklist is unavailable on B.
2. On A start a fictional case and defer an item. Keep its acknowledgment warning pending. Request support, review the unresolved-item preview, and send a question while offline. It must say **On this device** and remain after closing/reopening the app.
3. On both devices open Nearby iPad and choose Look for nearby iPad. Record local-network permission behavior. On A select B's device name; accept explicitly on B. Both should name the connected peer. Record device models, OS, permission state and network setup below.
4. Open the saved question on A and choose Send this saved question. B must receive its case/site/template/item brief without sharing A's workspace. A changes to **Received by peer** only after B receives and saves it.
5. B acknowledges the question and replies. Record independent delivery labels for question, acknowledgment and reply. A sees reply text, author and time beside its original current item. The warning remains pending and the item remains Deferred.
6. A acknowledges the warning. B must show acknowledgment context changed and **0 checklist lines changed**. Deferred remains unresolved. The original snapshot stays frozen.
7. Start another case on A. A late reply to the first case must remain with the original session and must not select or change the second case.
8. Stop nearby link explicitly. It must return to On this device. Restart, disconnect the peer, then stop from Disconnected as well. Attempt a send with discovery active but no connected peer: retain question/draft, show failure, and offer explicit retry. Reconnect and retry; the same question ID/snapshot appears once.
9. Relaunch both apps. Retained questions, acknowledgments, replies and drafts remain. Nearby discovery requires explicit restart. Existing checklist history is unchanged.
10. Check portrait/narrow windows, enlarged text, hardware keyboard, VoiceOver labels/order, touch targets, and Reduce Motion. Deny Local Network access and verify a persistent actionable message plus local fallback. Record actual outcomes only.

Airplane mode alone is not a deterministic disconnect test: Wi-Fi/Bluetooth may remain enabled. Use Stop nearby link for the reproducible fallback check.

## Result record

- Build / commit: pending
- iPad A model / OS: not available
- iPad B model / OS: not available
- Network / permissions: not run
- Pairing / question / acknowledgment / reply: not run
- Disconnect / retry / relaunch: not run
- Accessibility / keyboard / touch: not run
- Tester / date / exceptions: pending
