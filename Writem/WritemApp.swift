import SwiftUI

#if os(macOS)
import AppKit
#endif

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
            EditorEditCommands(session: session, settings: settings)
            EditorViewCommands(settings: settings)
            EditorSettingsCommands(settings: settings)
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
            Menu("Draft") {
                Button("New Draft") {
                    session.requestNewDraft()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        CommandGroup(after: .newItem) {
            Menu("Open") {
                Button("Open...") {
                    session.requestOpenDocument()
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

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
        }

        CommandGroup(replacing: .saveItem) {
            Menu("Save") {
                Button(session.fileURL == nil ? "Save..." : "Save") {
                    session.requestSave(forceSaveAs: false)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As...") {
                    session.requestSave(forceSaveAs: true)
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])

                Divider()

                Button("Reveal in Finder") {
                    guard let fileURL = session.fileURL else { return }
                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                }
                .disabled(session.fileURL == nil)
            }
        }
    }
}

private struct EditorViewCommands: Commands {
    @ObservedObject var settings: EditorSettingsStore

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Divider()

            Button(settings.showToolbar ? "Hide Toolbar" : "Show Toolbar") {
                settings.showToolbar.toggle()
            }

            Menu("Theme") {
                Picker("Theme", selection: preferredThemeBinding) {
                    Text("Auto").tag(EditorTheme.system)
                    Text("Light").tag(EditorTheme.light)
                    Text("Dark").tag(EditorTheme.dark)
                }
            }
        }
    }

    private var preferredThemeBinding: Binding<EditorTheme> {
        Binding(
            get: {
                settings.autoThemeEnabled ? .system : settings.preferredTheme
            },
            set: { newValue in
                switch newValue {
                case .system:
                    settings.autoThemeEnabled = true
                case .light, .dark:
                    settings.autoThemeEnabled = false
                    settings.preferredTheme = newValue
                }
            }
        )
    }
}

private struct EditorEditCommands: Commands {
    @ObservedObject var session: EditorSessionStore
    @ObservedObject var settings: EditorSettingsStore
    @Environment(\.undoManager) private var undoManager

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button("Undo") {
                undoManager?.undo()
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!(undoManager?.canUndo ?? false))

            Button("Redo") {
                undoManager?.redo()
            }
            .keyboardShortcut("Z", modifiers: [.command, .shift])
            .disabled(!(undoManager?.canRedo ?? false))
        }

        CommandGroup(after: .textEditing) {
            Divider()

            Menu("Find") {
                Button("Find...") {
                    session.requestFind()
                }
                .keyboardShortcut("f", modifiers: .command)

                Button("Replace...") {
                    session.requestReplace()
                }
                .keyboardShortcut("f", modifiers: [.command, .option])

                Divider()

                Button("Find Next") {
                    session.requestFindNext()
                }
                .keyboardShortcut("g", modifiers: .command)

                Button("Find Previous") {
                    session.requestFindPrevious()
                }
                .keyboardShortcut("G", modifiers: [.command, .shift])
            }

            Menu("Font") {
                ForEach(EditorFontStyle.allCases) { fontStyle in
                    Button {
                        settings.editorFontStyle = fontStyle
                    } label: {
                        fontMenuLabel(title: fontStyle.title, isSelected: settings.editorFontStyle == fontStyle)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fontMenuLabel(title: String, isSelected: Bool) -> some View {
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

private struct EditorSettingsCommands: Commands {
    @ObservedObject var settings: EditorSettingsStore

    var body: some Commands {
        CommandMenu("Settings") {
            Toggle("iCloud Sync", isOn: iCloudSyncBinding)
        }
    }

    private var iCloudSyncBinding: Binding<Bool> {
        Binding(
            get: { settings.iCloudConfigSyncEnabled },
            set: { settings.iCloudConfigSyncEnabled = $0 }
        )
    }
}
#endif
