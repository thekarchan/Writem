import SwiftUI

@main
struct WritemApp: App {
    @StateObject private var settings = EditorSettingsStore()
    @StateObject private var session = EditorSessionStore()

    @SceneBuilder
    var body: some Scene {
        WindowGroup {
            EditorRootView()
                .environmentObject(session)
                .environmentObject(settings)
        }
        .commands {
            #if os(macOS)
            EditorFileCommands(session: session)
            EditorEditCommands(settings: settings)
            #endif
        }
    }
}

#if os(macOS)
private struct EditorFileCommands: Commands {
    @ObservedObject var session: EditorSessionStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Draft") {
                session.restoreScratchDraft()
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(after: .newItem) {
            Button("Open...") {
                session.requestOpenDocument()
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandGroup(replacing: .saveItem) {
            Button(session.fileURL == nil ? "Save..." : "Save") {
                session.requestSave(forceSaveAs: false)
            }
            .keyboardShortcut("s", modifiers: .command)

            Button("Save As...") {
                session.requestSave(forceSaveAs: true)
            }
            .keyboardShortcut("S", modifiers: [.command, .shift])
        }
    }
}

private struct EditorEditCommands: Commands {
    @ObservedObject var settings: EditorSettingsStore

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Divider()

            Toggle(settings.showToolbar ? "Hide Toolbar" : "Show Toolbar", isOn: toolbarBinding)

            Toggle("Auto Switch Dark Theme", isOn: autoThemeBinding)

            if !settings.autoThemeEnabled {
                Picker("Theme", selection: themeBinding) {
                    Text("Light").tag(EditorTheme.light)
                    Text("Dark").tag(EditorTheme.dark)
                }
            }
        }
    }

    private var toolbarBinding: Binding<Bool> {
        Binding(
            get: { settings.showToolbar },
            set: { settings.showToolbar = $0 }
        )
    }

    private var autoThemeBinding: Binding<Bool> {
        Binding(
            get: { settings.autoThemeEnabled },
            set: { settings.autoThemeEnabled = $0 }
        )
    }

    private var themeBinding: Binding<EditorTheme> {
        Binding(
            get: {
                settings.preferredTheme == .system ? .light : settings.preferredTheme
            },
            set: { settings.preferredTheme = $0 }
        )
    }
}
#endif
