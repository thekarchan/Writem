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

    private enum PendingTransitionAction {
        case newDraft
        case openDocument
    }

    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var frontmatter: Frontmatter = .empty
    @State private var utilityPanel: UtilityPanel?
    @State private var isImportingDocument = false
    @State private var isImportingImages = false
    @State private var editorAlert: EditorAlertState?
    @State private var lastImportedAsset: ImportedImageAsset?
    @State private var pendingDocumentSave = MarkdownFileDocument(text: "")
    @State private var isSavingDocument = false
    @State private var documentSaveDefaultName = "Untitled"
    @State private var pendingExport: ExportArtifact?
    @State private var isExportingFile = false
    @State private var pendingCanvasCommand: EditorCanvasCommand?
    @State private var pendingImageImportInsertionRange: NSRange?
    @State private var pendingTransitionAction: PendingTransitionAction?
    @State private var isShowingUnsavedChangesDialog = false

    @EnvironmentObject private var session: EditorSessionStore
    @EnvironmentObject private var settings: EditorSettingsStore
    @Environment(\.colorScheme) private var colorScheme

    private var outline: [OutlineItem] {
        MarkdownAnalyzer.outline(for: session.text)
    }

    private var issues: [PreflightIssue] {
        MarkdownAnalyzer.preflightIssues(for: session.text, frontmatter: frontmatter, documentURL: session.fileURL)
    }

    private var errorCount: Int {
        issues.filter { $0.severity == .error }.count
    }

    private var warningCount: Int {
        issues.filter { $0.severity == .warning }.count
    }

    private var wordCount: Int {
        MarkdownAnalyzer.wordCount(for: session.text)
    }

    private var currentDocumentTitle: String {
        let explicitTitle = sanitizedTitle(frontmatter.title)
        if !explicitTitle.isEmpty {
            return explicitTitle
        }

        if let derivedTitle = derivedTitleFromFirstLine {
            return derivedTitle
        }

        return "Writem"
    }

    private var derivedTitleFromFirstLine: String? {
        guard let firstLine = session.text
            .components(separatedBy: .newlines)
            .map({ sanitizedTitle($0) })
            .first(where: { !$0.isEmpty }) else {
            return nil
        }

        return String(firstLine.prefix(16))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            OutlineSidebarView(items: outline, issues: issues) { _ in
                columnVisibility = .detailOnly
            }
        } detail: {
            VStack(spacing: 0) {
                if settings.showToolbar {
                    header
                }
                GeometryReader { proxy in
                    editorWorkspace(in: proxy.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if settings.showToolbar {
                    statusBar
                }
            }
            .background(editorBackground)
            .navigationTitle(currentDocumentTitle)
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            syncFrontmatter()
        }
        .onChange(of: session.text) { _, _ in
            syncFrontmatter()
        }
        .onChange(of: session.transitionRequest?.id) { _, _ in
            guard let transitionRequest = session.transitionRequest else { return }
            session.consumeTransitionRequest()
            handleTransitionRequest(transitionRequest.action)
        }
        .onChange(of: session.saveRequest?.id) { _, _ in
            guard let saveRequest = session.saveRequest else { return }
            session.consumeSaveRequest()
            handleSaveRequest(saveRequest)
        }
        .fileImporter(
            isPresented: $isImportingDocument,
            allowedContentTypes: MarkdownFileDocument.readableContentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                openDocument(from: url)
            case .failure(let error):
                guard (error as NSError).code != NSUserCancelledError else {
                    return
                }
                editorAlert = .init(title: "Open failed", message: error.localizedDescription)
            }
        }
        .fileImporter(
            isPresented: $isImportingImages,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            let insertionRange = pendingImageImportInsertionRange
            pendingImageImportInsertionRange = nil

            switch result {
            case .success(let urls):
                _ = importImages(from: urls, replacing: insertionRange)
            case .failure(let error):
                guard (error as NSError).code != NSUserCancelledError else {
                    return
                }
                editorAlert = .init(title: "Image import failed", message: error.localizedDescription)
            }
        }
        .fileExporter(
            isPresented: $isSavingDocument,
            document: pendingDocumentSave,
            contentType: UTType(filenameExtension: "md") ?? .plainText,
            defaultFilename: documentSaveDefaultName
        ) { result in
            switch result {
            case .success(let url):
                session.finishSave(at: url)
                continuePendingTransitionIfNeeded()
            case .failure(let error):
                pendingTransitionAction = nil
                guard (error as NSError).code != NSUserCancelledError else {
                    return
                }
                editorAlert = .init(title: "Save failed", message: error.localizedDescription)
            }
        }
        .alert(item: $editorAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Unsaved changes",
            isPresented: $isShowingUnsavedChangesDialog,
            titleVisibility: .visible
        ) {
            Button("Save and Continue") {
                saveAndContinuePendingTransition()
            }

            Button("Discard Changes", role: .destructive) {
                discardChangesAndContinue()
            }

            Button("Keep Editing", role: .cancel) {
                pendingTransitionAction = nil
            }
        } message: {
            Text("You have unsaved changes. Save them before continuing?")
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
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                compactControlMenu
            }
            #endif
        }
        .preferredColorScheme(settings.resolvedColorScheme)
    }

    #if os(iOS)
    private var compactControlMenu: some View {
        Menu {
            Button("New Draft") {
                session.requestNewDraft()
            }

            Button("Open...") {
                session.requestOpenDocument()
            }

            Button(session.fileURL == nil ? "Save..." : "Save") {
                session.requestSave(forceSaveAs: false)
            }

            Button("Save As...") {
                session.requestSave(forceSaveAs: true)
            }

            Divider()

            Toggle(isOn: $settings.showToolbar) {
                Text(settings.showToolbar ? "Hide Toolbar" : "Show Toolbar")
            }

            Toggle(isOn: $settings.autoThemeEnabled) {
                Text("Auto Switch Dark Theme")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 17, weight: .medium))
        }
    }
    #endif

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
                    Button {
                        issueCanvasCommand(.bold)
                    } label: {
                        Label("Bold", systemImage: "bold")
                    }
                    .keyboardShortcut("b", modifiers: .command)

                    Button {
                        issueCanvasCommand(.italic)
                    } label: {
                        Label("Italic", systemImage: "italic")
                    }
                    .keyboardShortcut("i", modifiers: .command)

                    Button {
                        issueCanvasCommand(.inlineCode)
                    } label: {
                        Label("Inline Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    .keyboardShortcut("e", modifiers: .command)

                    Button {
                        issueCanvasCommand(.link)
                    } label: {
                        Label("Link", systemImage: "link")
                    }
                    .keyboardShortcut("k", modifiers: .command)
                } label: {
                    menuBarMenuLabel(title: "Format", symbol: "textformat", isActive: false)
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
                            requestImageImport()
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

                    Text(currentDocumentTitle)
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
                .fill(colorScheme == .dark ? Color.black.opacity(0.18) : Color.white.opacity(0.54))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
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
            } else if session.fileURL == nil {
                Text("Save to enable assets")
            }
        }
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.62) : Color.secondary.opacity(0.82))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? Color.black.opacity(0.16) : Color.white.opacity(0.5))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.055) : Color.black.opacity(0.035))
                        .frame(height: 1)
                }
        )
    }

    @ViewBuilder
    private func editorWorkspace(in size: CGSize) -> some View {
        let usesPinnedSidebar = size.width >= 1080
        let horizontalPadding = settings.showToolbar ? 18.0 : 10.0
        let verticalPadding = settings.showToolbar ? 10.0 : 0.0

        if usesPinnedSidebar {
            HStack(spacing: 18) {
                editorCanvas(forFloatingSidebar: false)

                if let utilityPanel {
                    utilitySidebar(for: utilityPanel)
                        .frame(width: utilitySidebarWidth(for: size.width))
                        .frame(maxHeight: .infinity)
                        .transition(utilitySidebarTransition)
                        .zIndex(2)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .animation(.spring(response: 0.34, dampingFraction: 0.9), value: utilityPanel)
        } else {
            ZStack(alignment: .topTrailing) {
                editorCanvas(forFloatingSidebar: true)

                if let utilityPanel {
                    floatingSidebarBackdrop
                        .transition(.opacity)
                        .zIndex(1)

                    utilitySidebar(for: utilityPanel)
                        .frame(width: floatingSidebarWidth(for: size.width))
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                        .padding(.bottom, 12)
                        .transition(utilitySidebarTransition)
                        .zIndex(2)
                }
            }
            .animation(.spring(response: 0.34, dampingFraction: 0.9), value: utilityPanel)
        }
    }

    @ViewBuilder
    private func utilityPanelView(_ panel: UtilityPanel) -> some View {
        switch panel {
        case .frontmatter:
            FrontmatterPanelView(frontmatter: $frontmatter) { updated in
                session.text = FrontmatterParser.merge(updated, into: session.text)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        case .tables:
            TableEditorPanelView(markdown: session.text) { updatedMarkdown in
                session.text = updatedMarkdown
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
                            colorScheme == .dark
                                ? Color(red: 0.125, green: 0.13, blue: 0.14).opacity(0.94)
                                : Color.white.opacity(0.82),
                            colorScheme == .dark
                                ? Color(red: 0.10, green: 0.105, blue: 0.115).opacity(0.98)
                                : Color(red: 0.985, green: 0.982, blue: 0.975).opacity(0.96)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color(red: 0.59, green: 0.54, blue: 0.49).opacity(0.14),
                    lineWidth: 0.9
                )
        }
        .overlay(alignment: .leading) {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.58),
                    Color.white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 18)
            .padding(.vertical, 24)
            .allowsHitTesting(false)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.026), radius: 16, x: 0, y: 6)
        .shadow(color: Color(red: 0.41, green: 0.36, blue: 0.30).opacity(colorScheme == .dark ? 0.18 : 0.09), radius: 30, x: -6, y: 18)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func syncFrontmatter() {
        frontmatter = FrontmatterParser.parse(session.text)
    }

    private func toggleUtilityPanel(_ panel: UtilityPanel) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
            utilityPanel = utilityPanel == panel ? nil : panel
        }
    }

    private func dismissUtilityPanel() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
            utilityPanel = nil
        }
    }

    private func insert(snippet: Snippet) {
        let trimmed = session.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            session.text = snippet.content + "\n"
        } else {
            session.text += "\n\n" + snippet.content
        }
    }

    private func issueCanvasCommand(_ action: EditorCanvasCommand.Action) {
        pendingCanvasCommand = EditorCanvasCommand(action: action)
    }

    private func handleCanvasCommand(_ commandID: UUID) {
        guard pendingCanvasCommand?.id == commandID else {
            return
        }

        pendingCanvasCommand = nil
    }

    private func handleSaveRequest(_ saveRequest: EditorSaveRequest) {
        if !saveRequest.forceSaveAs, session.fileURL != nil {
            do {
                try session.saveToCurrentLocation()
                continuePendingTransitionIfNeeded()
            } catch {
                pendingTransitionAction = nil
                editorAlert = .init(title: "Save failed", message: error.localizedDescription)
            }
            return
        }

        presentSaveAs()
    }

    private func openDocument(from url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            try session.openDocument(at: url)
            lastImportedAsset = nil
            utilityPanel = nil
        } catch {
            editorAlert = .init(title: "Open failed", message: error.localizedDescription)
        }
    }

    private func handleTransitionRequest(_ action: EditorTransitionAction) {
        let pendingAction: PendingTransitionAction = {
            switch action {
            case .newDraft:
                return .newDraft
            case .openDocument:
                return .openDocument
            }
        }()

        if session.isDirty {
            pendingTransitionAction = pendingAction
            isShowingUnsavedChangesDialog = true
            return
        }

        performTransition(pendingAction)
    }

    private func saveAndContinuePendingTransition() {
        guard pendingTransitionAction != nil else { return }

        if session.fileURL != nil {
            handleSaveRequest(.init(forceSaveAs: false))
        } else {
            presentSaveAs()
        }
    }

    private func discardChangesAndContinue() {
        guard let pendingTransitionAction else { return }
        self.pendingTransitionAction = nil
        performTransition(pendingTransitionAction)
    }

    private func continuePendingTransitionIfNeeded() {
        guard let pendingTransitionAction else { return }
        self.pendingTransitionAction = nil
        performTransition(pendingTransitionAction)
    }

    private func performTransition(_ action: PendingTransitionAction) {
        switch action {
        case .newDraft:
            session.startNewDraft()
            lastImportedAsset = nil
            utilityPanel = nil
        case .openDocument:
            isImportingDocument = true
        }
    }

    private func presentSaveAs() {
        pendingDocumentSave = MarkdownFileDocument(text: session.text)
        documentSaveDefaultName = session.suggestedFilename
        isSavingDocument = true
    }

    private func export(_ format: ExportFormat) {
        Task {
            do {
                let artifact = try await DocumentExportService.makeArtifact(
                    format: format,
                    markdown: session.text,
                    frontmatter: frontmatter,
                    documentURL: session.fileURL,
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
    private func importImages(from urls: [URL], replacing replacementRange: NSRange? = nil) -> Bool {
        let imageURLs = urls.filter { ImageResourceManager.canImport($0) }
        guard !imageURLs.isEmpty else {
            editorAlert = .init(title: "Image import failed", message: "No supported image files were selected.")
            return false
        }

        do {
            let importedAssets = try ImageResourceManager.importImages(from: imageURLs, into: session.fileURL)
            guard !importedAssets.isEmpty else {
                return false
            }

            let references = importedAssets.map(\.markdownReference)
            if let replacementRange {
                let replacementText = references.joined(separator: "\n\n")
                let clampedRange = clamped(replacementRange, maxLength: session.text.utf16.count)
                issueCanvasCommand(
                    .replace(
                        .init(
                            replacementRange: clampedRange,
                            replacementText: replacementText,
                            selectedRange: NSRange(location: clampedRange.location + replacementText.utf16.count, length: 0)
                        )
                    )
                )
            } else {
                session.text = appendedMarkdownReferences(references, to: session.text)
            }
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

    private func requestImageImport(at replacementRange: NSRange? = nil) {
        guard session.fileURL != nil else {
            editorAlert = .init(
                title: "Image import unavailable",
                message: ImageResourceError.unsavedDocument.localizedDescription
            )
            return
        }

        pendingImageImportInsertionRange = replacementRange
        isImportingImages = true
    }

    private func clamped(_ range: NSRange, maxLength: Int) -> NSRange {
        let location = min(max(range.location, 0), maxLength)
        let length = min(max(range.length, 0), max(maxLength - location, 0))
        return NSRange(location: location, length: length)
    }

    private var editorBackground: some View {
        LinearGradient(
            colors: [
                colorScheme == .dark
                    ? Color(red: 0.085, green: 0.09, blue: 0.10)
                    : Color(red: 0.975, green: 0.972, blue: 0.965),
                colorScheme == .dark
                    ? Color(red: 0.055, green: 0.06, blue: 0.07)
                    : Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func editorCanvas(forFloatingSidebar: Bool) -> some View {
        EditorCanvasView(
            text: $session.text,
            lineWidth: settings.lineWidthPreset.width,
            command: pendingCanvasCommand,
            onDropImageFiles: { urls in
                importImages(from: urls)
            },
            onRequestImageImport: requestImageImport,
            onCommandHandled: handleCanvasCommand
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(utilityPanel == nil ? 1 : (forFloatingSidebar ? 0.996 : 0.998), anchor: .center)
        .offset(x: utilityPanel == nil ? 0 : (forFloatingSidebar ? -8 : -4))
        .overlay(alignment: .trailing) {
            LinearGradient(
                colors: utilityPanel == nil
                    ? [Color.clear, Color.clear]
                    : [
                        Color.clear,
                        Color(red: 0.58, green: 0.54, blue: 0.48).opacity(forFloatingSidebar ? 0.08 : 0.05)
                    ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: forFloatingSidebar ? 120 : 80)
            .allowsHitTesting(false)
        }
    }

    private var floatingSidebarBackdrop: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.018),
                        Color(red: 0.35, green: 0.31, blue: 0.28).opacity(0.06)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .contentShape(Rectangle())
            .onTapGesture {
                dismissUtilityPanel()
            }
    }

    private var utilitySidebarTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.985, anchor: .trailing)),
            removal: .move(edge: .trailing)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.985, anchor: .trailing))
        )
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
        if colorScheme == .dark {
            return isActive ? Color.white.opacity(0.9) : Color.white.opacity(0.68)
        }

        return isActive ? Color(red: 0.33, green: 0.28, blue: 0.25) : Color.secondary
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
                    .fill(
                        isActive
                            ? (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            : Color.clear
                    )
            )
        .contentShape(Rectangle())
    }

    private func sanitizedTitle(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^#+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\[(.*?)\]\((.*?)\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"`([^`]*)`"#, with: "$1", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
