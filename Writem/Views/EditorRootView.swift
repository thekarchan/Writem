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
                GeometryReader { proxy in
                    editorWorkspace(in: proxy.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                statusBar
            }
            .background(editorBackground)
            .navigationTitle(frontmatter.title.isEmpty ? "Untitled" : frontmatter.title)
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
                menuBarButton(
                    title: "Outline",
                    symbol: "sidebar.left",
                    isActive: columnVisibility != .detailOnly
                ) {
                    columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
                }

                Menu {
                    Button(columnVisibility == .detailOnly ? "Show Outline" : "Hide Outline") {
                        columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
                    }

                    Divider()

                    ForEach(LineWidthPreset.allCases) { preset in
                        Button {
                            settings.lineWidthPreset = preset
                        } label: {
                            if settings.lineWidthPreset == preset {
                                Label(preset.title, systemImage: "checkmark")
                            } else {
                                Text(preset.title)
                            }
                        }
                    }
                } label: {
                    menuBarMenuLabel(title: "View", symbol: "text.alignleft", isActive: false)
                }

                Menu {
                    Section("Markdown") {
                        ForEach(SnippetLibrary.all) { snippet in
                            Button {
                                insert(snippet: snippet)
                            } label: {
                                Label(snippet.title, systemImage: snippet.symbolName)
                            }
                        }
                    }

                    Section("Assets") {
                        Button {
                            isImportingImages = true
                        } label: {
                            Label("Import Image", systemImage: "photo")
                        }
                    }
                } label: {
                    menuBarMenuLabel(title: "Insert", symbol: "plus.square")
                }

                Menu {
                    utilityPanelMenuButton(.frontmatter)
                    utilityPanelMenuButton(.tables)
                    utilityPanelMenuButton(.preflight, titleOverride: "Checks \(errorCount)/\(warningCount)")
                    utilityPanelMenuButton(.settings)
                    if utilityPanel != nil {
                        Divider()
                        Button("Hide Panel") {
                            toggleUtilityPanel(utilityPanel ?? .frontmatter)
                        }
                    }
                } label: {
                    menuBarMenuLabel(
                        title: utilityPanel.map(utilityPanelTitle(for:)) ?? "Panels",
                        symbol: utilityPanel.map(utilityPanelSymbol(for:)) ?? "sidebar.trailing",
                        isActive: utilityPanel != nil
                    )
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
                    menuBarMenuLabel(title: "Export", symbol: "square.and.arrow.up")
                }

                Spacer(minLength: 18)

                HStack(spacing: 10) {
                    if let utilityPanel {
                        Label(utilityPanelTitle(for: utilityPanel), systemImage: utilityPanelSymbol(for: utilityPanel))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary.opacity(0.78))
                    }

                    Text(frontmatter.title.isEmpty ? "Untitled" : frontmatter.title)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .opacity(0.82)
                }
                .padding(.leading, 14)
                .padding(.trailing, 6)
                .frame(maxWidth: 320, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.54))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.black.opacity(0.04))
                        .frame(height: 1)
                }
        )
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Text("\(wordCount) words")
            Text("\(outline.count) headings")
            Text("\(issues.count) checks")
            if let lastImportedAsset {
                Text(lastImportedAsset.relativePath)
                    .lineLimit(1)
            } else if fileURL == nil {
                Text("Save to enable assets")
            }
        }
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(Color.secondary.opacity(0.82))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.black.opacity(0.035))
                        .frame(height: 1)
                }
        )
    }

    @ViewBuilder
    private func editorWorkspace(in size: CGSize) -> some View {
        let usesPinnedSidebar = size.width >= 1080

        if usesPinnedSidebar {
            HStack(spacing: 18) {
                EditorCanvasView(
                    text: $document.text,
                    lineWidth: settings.lineWidthPreset.width,
                    onDropImageFiles: importImages(from:)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let utilityPanel {
                    utilitySidebar(for: utilityPanel)
                        .frame(width: utilitySidebarWidth(for: size.width))
                        .frame(maxHeight: .infinity)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: utilityPanel)
        } else {
            ZStack(alignment: .topTrailing) {
                EditorCanvasView(
                    text: $document.text,
                    lineWidth: settings.lineWidthPreset.width,
                    onDropImageFiles: importImages(from:)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let utilityPanel {
                    utilitySidebar(for: utilityPanel)
                        .frame(width: floatingSidebarWidth(for: size.width))
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                        .padding(.bottom, 12)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.9), value: utilityPanel)
        }
    }

    @ViewBuilder
    private func utilityPanelView(_ panel: UtilityPanel) -> some View {
        switch panel {
        case .frontmatter:
            FrontmatterPanelView(frontmatter: $frontmatter) { updated in
                document.text = FrontmatterParser.merge(updated, into: document.text)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        case .tables:
            TableEditorPanelView(markdown: document.text) { updatedMarkdown in
                document.text = updatedMarkdown
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        case .preflight:
            PreflightPanelView(issues: issues) { _ in
                columnVisibility = .detailOnly
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        case .settings:
            SettingsPanelView()
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
        }
    }

    private func utilitySidebar(for panel: UtilityPanel) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Label(utilityPanelTitle(for: panel), systemImage: utilityPanelSymbol(for: panel))
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Color(red: 0.34, green: 0.29, blue: 0.25))

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                        utilityPanel = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.52))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.black.opacity(0.05))
                .frame(height: 1)

            utilityPanelView(panel)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.82),
                            Color(red: 0.985, green: 0.982, blue: 0.975).opacity(0.96)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(red: 0.59, green: 0.54, blue: 0.49).opacity(0.14), lineWidth: 0.9)
        }
        .shadow(color: Color.black.opacity(0.03), radius: 18, x: 0, y: 8)
        .shadow(color: Color(red: 0.41, green: 0.36, blue: 0.30).opacity(0.08), radius: 28, x: 0, y: 20)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func syncFrontmatter() {
        frontmatter = FrontmatterParser.parse(document.text)
    }

    private func toggleUtilityPanel(_ panel: UtilityPanel) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
            utilityPanel = utilityPanel == panel ? nil : panel
        }
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

    private func utilitySidebarWidth(for availableWidth: CGFloat) -> CGFloat {
        min(max(availableWidth * 0.27, 320), 380)
    }

    private func floatingSidebarWidth(for availableWidth: CGFloat) -> CGFloat {
        min(max(availableWidth - 28, 280), 360)
    }

    private func utilityPanelTitle(for panel: UtilityPanel) -> String {
        switch panel {
        case .frontmatter:
            return "Frontmatter"
        case .preflight:
            return "Checks"
        case .tables:
            return "Tables"
        case .settings:
            return "Settings"
        }
    }

    private func utilityPanelSymbol(for panel: UtilityPanel) -> String {
        switch panel {
        case .frontmatter:
            return "slider.horizontal.3"
        case .preflight:
            return "checklist"
        case .tables:
            return "tablecells"
        case .settings:
            return "gearshape"
        }
    }

    @ViewBuilder
    private func utilityPanelMenuButton(_ panel: UtilityPanel, titleOverride: String? = nil) -> some View {
        Button {
            toggleUtilityPanel(panel)
        } label: {
            if utilityPanel == panel {
                Label(titleOverride ?? utilityPanelTitle(for: panel), systemImage: "checkmark")
            } else {
                Label(titleOverride ?? utilityPanelTitle(for: panel), systemImage: utilityPanelSymbol(for: panel))
            }
        }
    }

    private func menuBarMenuLabel(title: String, symbol: String, isActive: Bool = false) -> some View {
        HStack(spacing: 6) {
            menuBarLabel(title: title, symbol: symbol, isActive: isActive)
            Image(systemName: "chevron.down")
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundStyle(menuBarForeground(isActive: isActive).opacity(0.75))
        }
        .contentShape(Rectangle())
    }

    private func menuBarForeground(isActive: Bool) -> Color {
        isActive ? Color(red: 0.33, green: 0.28, blue: 0.25) : Color.secondary
    }

    private func menuBarButton(title: String, symbol: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            menuBarLabel(title: title, symbol: symbol, isActive: isActive)
        }
        .buttonStyle(.plain)
    }

    private func menuBarLabel(title: String, symbol: String, isActive: Bool = false) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(menuBarForeground(isActive: isActive))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isActive ? Color.black.opacity(0.05) : Color.clear)
            )
        .contentShape(Rectangle())
    }
}
