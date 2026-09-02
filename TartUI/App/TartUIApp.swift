import SwiftUI

@main
struct TartUIApp: App {
    @State private var model = TartAppModel()

    private var verificationColorScheme: ColorScheme? {
        if CommandLine.arguments.contains("--force-light") { return .light }
        if CommandLine.arguments.contains("--force-dark") { return .dark }
        return nil
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .frame(minWidth: 1100, minHeight: 680)
                .preferredColorScheme(verificationColorScheme)
        }
        .defaultSize(width: 1280, height: 820)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView(settings: .shared)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Link("TartUI on GitHub", destination: URL(string: "https://github.com/henry753951/TartUI")!)
                Link("Henry753951 on GitHub", destination: URL(string: "https://github.com/henry753951")!)
            }
        }
    }
}
