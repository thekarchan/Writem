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
            EditorViewCommands(settings: settings)
            EditorHelpCommands()
            #endif
        }

        #if os(macOS)
        Window("Markdown Syntax", id: "markdown-syntax") {
            MarkdownSyntaxHelpView()
        }
        .windowResizability(.contentSize)
        #endif
    }
}

#if os(macOS)
private struct EditorFileCommands: Commands {
    @ObservedObject var session: EditorSessionStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Draft") {
                session.requestNewDraft()
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        CommandGroup(after: .newItem) {
            Button("Open...") {
                session.requestOpenDocument()
            }
            .keyboardShortcut("o", modifiers: .command)

            Menu("Open Recent") {
                if session.recentDocuments.isEmpty {
                    Button("No Recent Documents") {}
                        .disabled(true)
                } else {
                    ForEach(session.recentDocuments) { item in
                        Button(item.menuTitle) {
                            session.requestOpenRecentDocument(item)
                        }
                    }

                    Divider()

                    Button("Clear Menu") {
                        session.clearRecentDocuments()
                    }
                }
            }
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

private struct EditorViewCommands: Commands {
    @ObservedObject var settings: EditorSettingsStore

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Divider()

            Menu("Editor") {
                Toggle(settings.showToolbar ? "Hide Toolbar" : "Show Toolbar", isOn: toolbarBinding)
            }

            Menu("Appearance") {
                Toggle("Auto Switch Dark Theme", isOn: autoThemeBinding)

                Divider()

                Button {
                    settings.preferredTheme = .light
                } label: {
                    themeMenuLabel(title: "Light", isSelected: !settings.autoThemeEnabled && settings.preferredTheme == .light)
                }
                .disabled(settings.autoThemeEnabled)

                Button {
                    settings.preferredTheme = .dark
                } label: {
                    themeMenuLabel(title: "Dark", isSelected: !settings.autoThemeEnabled && settings.preferredTheme == .dark)
                }
                .disabled(settings.autoThemeEnabled)
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

    @ViewBuilder
    private func themeMenuLabel(title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }
}

private struct EditorHelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .help) {
            Divider()

            Button("Markdown Syntax Reference") {
                openWindow(id: "markdown-syntax")
            }
            .keyboardShortcut("/", modifiers: [.command, .shift])
        }
    }
}
#endif
