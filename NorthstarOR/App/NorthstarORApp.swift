import SwiftUI

@main
struct NorthstarORApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(.dark)
                .tint(Northstar.Palette.aurora)
        }
    }
}
