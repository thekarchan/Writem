import SwiftUI

struct SettingsPanelView: View {
    @EnvironmentObject private var settings: EditorSettingsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.title3.weight(.bold))
                        Text("Editor preferences are stored locally and can sync through iCloud when the capability is enabled.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Theme")
                        .font(.subheadline.weight(.semibold))
                    Picker("Theme", selection: $settings.preferredTheme) {
                        ForEach(EditorTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Writing Width")
                        .font(.subheadline.weight(.semibold))
                    Picker("Width", selection: $settings.lineWidthPreset) {
                        ForEach(LineWidthPreset.allCases) { preset in
                            Text(preset.title).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle("Show line numbers in code blocks", isOn: $settings.showCodeLineNumbers)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Sync preferences through iCloud", isOn: $settings.iCloudConfigSyncEnabled)
                    Label(settings.iCloudStatus.title, systemImage: iconName(for: settings.iCloudStatus))
                        .font(.headline)
                        .foregroundStyle(color(for: settings.iCloudStatus))
                    Text(settings.iCloudStatus.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Refresh iCloud Status") {
                        settings.refreshICloudStatus()
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                )
            }
        }
    }

    private func iconName(for status: ICloudSyncStatus) -> String {
        switch status {
        case .checking:
            return "arrow.triangle.2.circlepath"
        case .available:
            return "icloud.fill"
        case .unavailable:
            return "icloud.slash"
        }
    }

    private func color(for status: ICloudSyncStatus) -> Color {
        switch status {
        case .checking:
            return .secondary
        case .available:
            return .green
        case .unavailable:
            return .orange
        }
    }
}
