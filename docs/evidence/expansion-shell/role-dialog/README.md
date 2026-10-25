# Role control repair

A CI recording and accessibility hierarchy from run 40183913275 showed a nested Menu button that could not be activated. RootView now uses one standard button and a native role-selection confirmation dialog, followed by the existing disconnect confirmation.

Build-for-testing succeeded. All three AdaptiveShellForms tests completed successfully on iPad Pro 13-inch (M5), iOS 27.0, Xcode 27.1: portrait cancellation retains Room; accessibility XXXL landscape confirms Rep and removes recording controls; settings require explicit discard. Original screenshots and attachment manifest are included. The confirmation text was then shortened to fit more comfortably at the largest text size; its final capture is tracked separately.

An earlier test expected a Cancel button in the iPad role chooser; that popover exposes Room and Rep and uses outside dismissal. The corrected large-text test selects Rep directly. The destructive confirmation still tests Cancel in portrait. No physical VoiceOver, keyboard traversal, Reduce Motion or new contrast measurement is claimed. Required CI remains mandatory after the shared recording repair #59 merges.
