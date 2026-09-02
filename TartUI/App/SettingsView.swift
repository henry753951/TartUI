import AppKit
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem { Label("General", systemImage: "gearshape") }

            AboutSettingsView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 560, height: 430)
    }
}

private struct GeneralSettingsView: View {
    @Bindable var settings: AppSettings
    private let hostIntegration = HostIntegrationService()
    private let locator = TartExecutableLocator()

    var body: some View {
        Form {
            Section("Tart") {
                LabeledContent("Executable") {
                    HStack {
                        Text(executableDescription)
                            .font(.system(.callout, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Button("Choose…") {
                            if let url = hostIntegration.chooseExecutable() {
                                settings.tartExecutablePath = url.path
                            }
                        }
                        Button("Automatic") {
                            settings.tartExecutablePath = ""
                        }
                        .disabled(settings.tartExecutablePath.isEmpty)
                    }
                }

                TextField("Default OCI image", text: $settings.defaultImageReference)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Connections") {
                TextField("Default SSH username", text: $settings.sshUsername)
                Picker("Default IP resolver", selection: $settings.ipResolver) {
                    ForEach(IPResolver.allCases) { resolver in
                        Text(resolver.title).tag(resolver)
                    }
                }
            }

            Section("Language") {
                LabeledContent("App language", value: String(localized: "Follows macOS language settings"))
                Text(
                    "TartUI uses Apple String Catalog localization. Change the per-app language in System Settings when available."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Restore Defaults", role: .destructive) {
                    settings.resetGeneralSettings()
                }
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }

    private var executableDescription: String {
        locator.resolve()?.path ?? String(localized: "Not found")
    }
}

private struct AboutSettingsView: View {
    @State private var isShowingLicenses = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TartUI")
                            .font(.title2.weight(.semibold))
                        Text(versionDescription)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(
                    "TartUI is a small macOS companion for viewing Tart images and working with local virtual machines."
                )
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    Link(destination: URL(string: "https://github.com/henry753951")!) {
                        AboutRow(
                            systemName: "person.crop.circle",
                            title: "Henry753951",
                            subtitle: "Project author",
                            trailingSystemName: "arrow.up.right"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 48)

                    Button {
                        isShowingLicenses = true
                    } label: {
                        AboutRow(
                            systemName: "doc.text",
                            title: "Software Licenses",
                            subtitle: "TartUI and related projects",
                            trailingSystemName: "chevron.right"
                        )
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 48)

                    Link(destination: URL(string: "https://github.com/henry753951/TartUI")!) {
                        AboutRow(
                            systemName: "chevron.left.forwardslash.chevron.right",
                            title: "Source Code",
                            subtitle: "View the project on GitHub",
                            trailingSystemName: "arrow.up.right"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(
                    "TartUI connects to a separately installed Tart CLI. It is a community project, not an official OpenAI or Cirrus Labs product."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
        }
        .sheet(isPresented: $isShowingLicenses) {
            LicenseBrowserView()
        }
    }

    private var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return String(localized: "Version \(version) (\(build))")
    }
}

private struct AboutRow: View {
    let systemName: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let trailingSystemName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: trailingSystemName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}
