# Role control repair

A CI recording and accessibility hierarchy from run 40183913275 showed a nested Menu button that could not be activated. RootView now uses one standard button and a native role-selection confirmation dialog, followed by the existing disconnect confirmation.

Build-for-testing succeeded. All three AdaptiveShellForms tests completed successfully on iPad Pro 13-inch (M5), iOS 27.0, Xcode 27.1: portrait cancellation retains Room; accessibility XXXL landscape confirms Rep and removes recording controls; settings require explicit discard. Original screenshots and attachment manifest are included. The confirmation text was then shortened to fit more comfortably at the largest text size; its final capture is tracked separately.

An earlier test expected a Cancel button in the iPad role chooser; that popover exposes Room and Rep and uses outside dismissal. The corrected large-text test selects Rep directly. The destructive confirmation still tests Cancel in portrait. No physical VoiceOver, keyboard traversal, Reduce Motion or new contrast measurement is claimed. Required CI remains mandatory after the shared recording repair #59 merges.

CI run 40202894915 passed all tests except blank setup. Its video showed repeated drags leaving the participant field behind the open keyboard. The final setup form explicitly dismisses the keyboard when scrolling; the UI regression reveals participant/create controls and verifies exact participant input before creating the workspace. `setup-keyboard-before.png` is an unmodified frame extracted at 25 seconds from that run’s original setup screen recording. Final CI verification is still required.

Run 40204337044 passed blank workspace creation after the keyboard fix, but the first enlarged-text role activation did not present its native confirmationDialog. Its event coordinate maps to the center of the visible role button; the same tests passed in two earlier runs. The final candidate replaces the popover with a native role-selection sheet with 72-point rows. Its onDismiss requests the existing disconnect confirmation, avoiding overlapping presentations. Required final CI is pending. Earlier role-dialog screenshots above describe their stated source, not this final sheet.

The final header also uses one AnyLayout tree for its identity/context and Settings control. Regular-width windows keep a horizontal context row; compact windows stack it. This removes remaining duplicated interactive fitting branches. Earlier captures retain their stated source; final merged-candidate CI evidence remains required.
