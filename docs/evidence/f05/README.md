# F05 recording guard evidence

Captured 2026-10-24 on iPad Pro 13-inch (M5), iOS 26.5 simulator, landscape app viewport 1376 × 1032 points (2752 × 2064 device pixels). CUA window captures include simulator chrome; default content size Large, enlarged content size Accessibility XXXL. No real data.

- `default.png`: initial recording with selectable rail and captured touch commands.
- `pinned-warning.png`: required first item remains the displayed item; all rail selection buttons disabled. Attempted another rail selection; warning stayed on the original item.
- `pinned-after-support.png`: visited Remote Support, sent an existing local technical prompt, returned to Co-pilot. Original deferred item and warning retained; incoming message visible. This is on-device exchange, not transport/receipt proof.
- `acknowledged-deferred.png`: acknowledged warning; same item remains selected/deferred and normal recording buttons remain disabled. Then explicitly selected item two; it became current without changing item one's deferred record.
- `enlarged-text.png`, `enlarged-warning.png`: Accessibility XXXL. Deferral and acknowledgment remained actionable and warning fully visible. Existing fixed sidebars show excessive wrapping and poor information density; F09/F10 must address layout. Restored content size Large afterward.

Checks actually run: simulator pointer interactions for defer, blocked rail selection, support-tab round trip, local incoming reply, acknowledgment and explicit post-ack selection; accessibility tree exposed named rail buttons/disabled states; existing primary style minimum 72 pt and added rail min-height 44 pt inspected in source. No physical touch measurements, contrast measurements, VoiceOver speech/navigation, keyboard focus traversal or Reduce Motion setting check was performed. Those remain gaps for UI acceptance. Existing border/always-present timer and old support labels are unchanged; full UI refinement/correction controls are F09/F10/F13. Domain correction/source/identity guards have direct tests; no storage or real speech/transport capability is claimed.
