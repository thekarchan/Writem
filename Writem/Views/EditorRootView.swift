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

    @State private var mode: EditorMode = .writing
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var frontmatter: Frontmatter = .empty
    @State private var utilityPanel: UtilityPanel?
    @State private var jumpToLine: Int?
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
            OutlineSidebarView(items: outline, issues: issues) { item in
                mode = .reading
                jumpToLine = item.lineNumber
            }
        } detail: {
            VStack(spacing: 0) {
                header
                Divider()
                EditorCanvasView(
                    text: $document.text,
                    mode: mode,
                    lineWidth: settings.lineWidthPreset.width,
                    documentURL: fileURL,
                    jumpToLine: jumpToLine,
                    onDropImageFiles: importImages(from:)
                )
                if let utilityPanel {
                    Divider()
                    utilityPanelView(utilityPanel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .background(Color.white.opacity(0.58))
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(frontmatter.title.isEmpty ? "Writem" : frontmatter.title)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                    Text("Single-column Markdown editing for iPhone, iPad, and Mac.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Picker("Mode", selection: $mode) {
                    ForEach(EditorMode.allCases) { item in
                        Label(item.rawValue, systemImage: item.symbolName).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    pillButton(
                        title: columnVisibility == .detailOnly ? "Outline" : "Hide Outline",
                        symbol: "sidebar.left",
                        tint: Color(red: 0.16, green: 0.22, blue: 0.30)
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
                        pillLabel(title: settings.lineWidthPreset.title, symbol: "arrow.left.and.right")
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
                        pillLabel(title: "Insert", symbol: "plus.square.on.square")
                    }

                    pillButton(
                        title: "Import Image",
                        symbol: "photo.badge.plus",
                        tint: Color(red: 0.13, green: 0.40, blue: 0.34)
                    ) {
                        isImportingImages = true
                    }

                    pillButton(
                        title: "Frontmatter",
                        symbol: "slider.horizontal.3",
                        tint: Color(red: 0.34, green: 0.22, blue: 0.16)
                    ) {
                        utilityPanel = utilityPanel == .frontmatter ? nil : .frontmatter
                    }

                    pillButton(
                        title: "Tables",
                        symbol: "tablecells",
                        tint: Color(red: 0.22, green: 0.34, blue: 0.56)
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
                        pillLabel(title: "Export", symbol: "square.and.arrow.up")
                    }

                    pillButton(
                        title: "Preflight \(errorCount)E/\(warningCount)W",
                        symbol: "checklist",
                        tint: Color(red: 0.60, green: 0.22, blue: 0.20)
                    ) {
                        utilityPanel = utilityPanel == .preflight ? nil : .preflight
                    }

                    pillButton(
                        title: "Settings",
                        symbol: "gearshape",
                        tint: Color(red: 0.30, green: 0.30, blue: 0.36)
                    ) {
                        utilityPanel = utilityPanel == .settings ? nil : .settings
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 18)
        .background(Color.white.opacity(0.68))
    }

    private var statusBar: some View {
        HStack(spacing: 18) {
            Label("\(wordCount) words", systemImage: "text.word.spacing")
            Label("\(outline.count) headings", systemImage: "list.bullet.indent")
            Label("\(issues.count) checks", systemImage: "checkmark.seal")
            Label(settings.showCodeLineNumbers ? "Code lines on" : "Code lines off", systemImage: "number")
            if let lastImportedAsset {
                Label(lastImportedAsset.relativePath, systemImage: "photo")
                    .lineLimit(1)
            } else if fileURL == nil {
                Label("Save document to enable assets", systemImage: "externaldrive.badge.plus")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.38))
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
            PreflightPanelView(issues: issues) { issue in
                if let lineNumber = issue.lineNumber {
                    mode = .reading
                    jumpToLine = lineNumber
                }
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
            mode = .writing
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
                Color(red: 0.95, green: 0.92, blue: 0.86),
                Color(red: 0.99, green: 0.98, blue: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func pillButton(title: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            pillLabel(title: title, symbol: symbol)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 1)
        .background(
            Capsule()
                .fill(tint.opacity(0.92))
        )
        .foregroundStyle(.white)
    }

    private func pillLabel(title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
    }
}
