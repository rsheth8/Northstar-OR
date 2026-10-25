import SwiftUI

@main
struct NorthstarORApp: App {
    @State private var model = AppModel.launching()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(.light)
                .tint(Northstar.Palette.ice)
        }
        .onChange(of: scenePhase) { _, phase in
            // Coalesced draft saves are written before the app leaves the foreground.
            if phase != .active { model.flushPendingSave() }
        }
    }
}
