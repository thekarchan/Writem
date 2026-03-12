import SwiftUI
import UniformTypeIdentifiers

struct EditorRootView: View {
    enum UtilityPanel {
        case frontmatter
        case preflight
        case tables
        case settings
    }

    struct EditorAlertState: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    @Binding var document: MarkdownFileDocument
    let fileURL: URL?

    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var frontmatter: Frontmatter = .empty
    @State private var utilityPanel: UtilityPanel?
    @State private var isImportingImages = false
    @State private var editorAlert: EditorAlertState?
    @State private var lastImportedAsset: ImportedImageAsset?
    @State private var pendingExport: ExportArtifact?
    @State private var isExportingFile = false

    @EnvironmentObject private var settings: EditorSettingsStore

    private var outline: [OutlineItem] {
        MarkdownAnalyzer.outline(for: document.text)
    }

    private var issues: [PreflightIssue] {
        MarkdownAnalyzer.preflightIssues(for: document.text, frontmatter: frontmatter, documentURL: fileURL)
    }

    private var errorCount: Int {
        issues.filter { $0.severity == .error }.count
    }

    private var warningCount: Int {
        issues.filter { $0.severity == .warning }.count
    }

    private var wordCount: Int {
        MarkdownAnalyzer.wordCount(for: document.text)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            OutlineSidebarView(items: outline, issues: issues) { _ in
                columnVisibility = .detailOnly
            }
        } detail: {
            VStack(spacing: 0) {
                header
                EditorCanvasView(
                    text: $document.text,
                    lineWidth: settings.lineWidthPreset.width,
                    onDropImageFiles: importImages(from:)
                )
                if let utilityPanel {
                    Divider()
                    utilityPanelView(utilityPanel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .background(Color.black.opacity(0.015))
                }
                statusBar
            }
            .background(editorBackground)
            .navigationTitle(frontmatter.title.isEmpty ? "Untitled Draft" : frontmatter.title)
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            syncFrontmatter()
        }
        .onChange(of: document.text) { _, _ in
            syncFrontmatter()
        }
        .fileImporter(
            isPresented: $isImportingImages,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                _ = importImages(from: urls)
            case .failure(let error):
                editorAlert = .init(title: "Image import failed", message: error.localizedDescription)
            }
        }
        .alert(item: $editorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .fileExporter(
            isPresented: $isExportingFile,
            document: pendingExport?.document,
            contentType: pendingExport?.contentType ?? .data,
            defaultFilename: pendingExport?.defaultFilename ?? "writem-export"
        ) { result in
            if case .failure(let error) = result {
                editorAlert = .init(title: "Export failed", message: error.localizedDescription)
            }
            pendingExport = nil
        }
        .preferredColorScheme(settings.preferredTheme.colorScheme)
    }

    private var header: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                toolbarButton(
                    title: columnVisibility == .detailOnly ? "Outline" : "Hide Outline",
                    symbol: "sidebar.left",
                    isActive: columnVisibility != .detailOnly
                ) {
                    columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
                }

                Menu {
                    ForEach(LineWidthPreset.allCases) { preset in
                        Button(preset.title) {
                            settings.lineWidthPreset = preset
                        }
                    }
                } label: {
                    toolbarLabel(title: settings.lineWidthPreset.title, symbol: "arrow.left.and.right")
                }

                Menu {
                    ForEach(SnippetLibrary.all) { snippet in
                        Button {
                            insert(snippet: snippet)
                        } label: {
                            Label(snippet.title, systemImage: snippet.symbolName)
                        }
                    }
                } label: {
                    toolbarLabel(title: "Insert", symbol: "plus.square")
                }

                toolbarButton(title: "Image", symbol: "photo") {
                    isImportingImages = true
                }

                toolbarButton(
                    title: "Frontmatter",
                    symbol: "slider.horizontal.3",
                    isActive: utilityPanel == .frontmatter
                ) {
                    utilityPanel = utilityPanel == .frontmatter ? nil : .frontmatter
                }

                toolbarButton(
                    title: "Tables",
                    symbol: "tablecells",
                    isActive: utilityPanel == .tables
                ) {
                    utilityPanel = utilityPanel == .tables ? nil : .tables
                }

                Menu {
                    ForEach(ExportFormat.allCases) { format in
                        Button {
                            export(format)
                        } label: {
                            Label(format.title, systemImage: format.symbolName)
                        }
                    }
                } label: {
                    toolbarLabel(title: "Export", symbol: "square.and.arrow.up")
                }

                toolbarButton(
                    title: "Checks \(errorCount)/\(warningCount)",
                    symbol: "checklist",
                    isActive: utilityPanel == .preflight
                ) {
                    utilityPanel = utilityPanel == .preflight ? nil : .preflight
                }

                toolbarButton(
                    title: "Settings",
                    symbol: "gearshape",
                    isActive: utilityPanel == .settings
                ) {
                    utilityPanel = utilityPanel == .settings ? nil : .settings
                }
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.86))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(height: 1)
                }
        )
    }

    private var statusBar: some View {
        HStack(spacing: 14) {
            Label("\(wordCount) words", systemImage: "text.word.spacing")
            Label("\(outline.count) headings", systemImage: "number")
            Label("\(issues.count) checks", systemImage: "checkmark.seal")
            if let lastImportedAsset {
                Label(lastImportedAsset.relativePath, systemImage: "photo")
                    .lineLimit(1)
            } else if fileURL == nil {
                Label("Save to enable assets", systemImage: "externaldrive.badge.plus")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.7))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 1)
                }
        )
    }

    @ViewBuilder
    private func utilityPanelView(_ panel: UtilityPanel) -> some View {
        switch panel {
        case .frontmatter:
            FrontmatterPanelView(frontmatter: $frontmatter) { updated in
                document.text = FrontmatterParser.merge(updated, into: document.text)
            }
            .padding(20)
        case .tables:
            TableEditorPanelView(markdown: document.text) { updatedMarkdown in
                document.text = updatedMarkdown
            }
            .padding(20)
        case .preflight:
            PreflightPanelView(issues: issues) { _ in
                columnVisibility = .detailOnly
            }
            .padding(20)
        case .settings:
            SettingsPanelView()
                .padding(20)
        }
    }

    private func syncFrontmatter() {
        frontmatter = FrontmatterParser.parse(document.text)
    }

    private func insert(snippet: Snippet) {
        let trimmed = document.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            document.text = snippet.content + "\n"
        } else {
            document.text += "\n\n" + snippet.content
        }
    }

    private func export(_ format: ExportFormat) {
        Task {
            do {
                let artifact = try await DocumentExportService.makeArtifact(
                    format: format,
                    markdown: document.text,
                    frontmatter: frontmatter,
                    documentURL: fileURL,
                    showCodeLineNumbers: settings.showCodeLineNumbers
                )
                pendingExport = artifact
                isExportingFile = true
            } catch {
                editorAlert = .init(title: "Export failed", message: error.localizedDescription)
            }
        }
    }

    @discardableResult
    private func importImages(from urls: [URL]) -> Bool {
        let imageURLs = urls.filter { ImageResourceManager.canImport($0) }
        guard !imageURLs.isEmpty else {
            editorAlert = .init(title: "Image import failed", message: "No supported image files were selected.")
            return false
        }

        do {
            let importedAssets = try ImageResourceManager.importImages(from: imageURLs, into: fileURL)
            guard !importedAssets.isEmpty else {
                return false
            }

            let references = importedAssets.map(\.markdownReference)
            document.text = appendedMarkdownReferences(references, to: document.text)
            lastImportedAsset = importedAssets.last
            return true
        } catch {
            editorAlert = .init(
                title: "Image import failed",
                message: error.localizedDescription
            )
            return false
        }
    }

    private func appendedMarkdownReferences(_ references: [String], to text: String) -> String {
        let insertion = references.joined(separator: "\n\n")
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return insertion + "\n"
        }

        return trimmed + "\n\n" + insertion + "\n"
    }

    private var editorBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.975, green: 0.972, blue: 0.965),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func toolbarButton(title: String, symbol: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            toolbarLabel(title: title, symbol: symbol, isActive: isActive)
        }
        .buttonStyle(.plain)
    }

    private func toolbarLabel(title: String, symbol: String, isActive: Bool = false) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundStyle(isActive ? Color.primary : Color.secondary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? Color.black.opacity(0.06) : Color.clear)
            )
    }
}
