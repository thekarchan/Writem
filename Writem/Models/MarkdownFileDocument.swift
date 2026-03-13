import SwiftUI
import UniformTypeIdentifiers
import Combine

struct MarkdownFileDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [UTType(filenameExtension: "md") ?? .plainText, .plainText]
    }

    var text: String

    init(text: String = SampleDocument.content) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.text = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return .init(regularFileWithContents: data)
    }
}

struct EditorSaveRequest: Identifiable, Equatable {
    let id = UUID()
    let forceSaveAs: Bool
}

enum EditorTransitionAction: Equatable {
    case newDraft
    case openDocument
    case openRecentDocument(String)
}

struct EditorTransitionRequest: Identifiable, Equatable {
    let id = UUID()
    let action: EditorTransitionAction
}

enum EditorFindAction: Equatable {
    case openFind
    case openReplace
    case findNext
    case findPrevious
}

struct EditorFindRequest: Identifiable, Equatable {
    let id = UUID()
    let action: EditorFindAction
}

struct RecentDocumentItem: Identifiable, Equatable, Codable {
    let id: String
    let displayName: String
    let parentPath: String
    let bookmarkData: Data
    let lastOpenedAt: Date

    var menuTitle: String {
        guard !parentPath.isEmpty else {
            return displayName
        }

        return "\(displayName)  \(parentPath)"
    }
}

enum EditorAutosaveState: Equatable {
    case idle
    case saving
    case saved(Date)
    case failed
}

enum EditorSessionError: LocalizedError {
    case invalidTextEncoding
    case missingSaveLocation
    case recentDocumentUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidTextEncoding:
            return "The selected file could not be read as UTF-8 Markdown."
        case .missingSaveLocation:
            return "Choose a save location first."
        case .recentDocumentUnavailable:
            return "The recent document could not be opened anymore."
        }
    }
}

@MainActor
final class EditorSessionStore: ObservableObject {
    @Published var text: String
    @Published var fileURL: URL?
    @Published private(set) var isDirty: Bool
    @Published private(set) var autosaveState: EditorAutosaveState
    @Published private(set) var transitionRequest: EditorTransitionRequest?
    @Published private(set) var saveRequest: EditorSaveRequest?
    @Published private(set) var findRequest: EditorFindRequest?
    @Published private(set) var recentDocuments: [RecentDocumentItem]

    private let defaults: UserDefaults
    private var lastSavedText: String
    private var cancellables: Set<AnyCancellable> = []
    private var isApplyingProgrammaticChange = false

    private enum Key {
        static let scratchText = "editor.scratchText"
        static let recentDocuments = "editor.recentDocuments"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let scratchText = defaults.string(forKey: Key.scratchText) ?? SampleDocument.content
        self.text = scratchText
        self.fileURL = nil
        self.lastSavedText = ""
        self.isDirty = !scratchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        self.autosaveState = scratchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .idle : .saved(Date())
        self.recentDocuments = Self.loadRecentDocuments(from: defaults)

        bindChanges()
    }

    var suggestedFilename: String {
        let rawTitle = text
            .components(separatedBy: .newlines)
            .map(sanitizedFilenameFragment(_:))
            .first(where: { !$0.isEmpty }) ?? "Untitled"

        let limited = String(rawTitle.prefix(16)).trimmingCharacters(in: .whitespacesAndNewlines)
        return limited.isEmpty ? "Untitled" : limited
    }

    var autosaveStatusText: String? {
        switch autosaveState {
        case .idle:
            return nil
        case .saving:
            return fileURL == nil ? "Saving draft..." : "Saving..."
        case .saved:
            return nil
        case .failed:
            return fileURL == nil ? "Draft save failed" : "Autosave failed"
        }
    }

    func requestNewDraft() {
        transitionRequest = .init(action: .newDraft)
    }

    func requestOpenDocument() {
        transitionRequest = .init(action: .openDocument)
    }

    func requestOpenRecentDocument(_ item: RecentDocumentItem) {
        transitionRequest = .init(action: .openRecentDocument(item.id))
    }

    func consumeTransitionRequest() {
        transitionRequest = nil
    }

    func requestSave(forceSaveAs: Bool = false) {
        saveRequest = .init(forceSaveAs: forceSaveAs)
    }

    func consumeSaveRequest() {
        saveRequest = nil
    }

    func requestFind() {
        findRequest = .init(action: .openFind)
    }

    func requestReplace() {
        findRequest = .init(action: .openReplace)
    }

    func requestFindNext() {
        findRequest = .init(action: .findNext)
    }

    func requestFindPrevious() {
        findRequest = .init(action: .findPrevious)
    }

    func consumeFindRequest() {
        findRequest = nil
    }

    func startNewDraft() {
        applyProgrammaticChange {
            text = SampleDocument.content
            fileURL = nil
            lastSavedText = ""
            isDirty = false
            autosaveState = .idle
            defaults.set(SampleDocument.content, forKey: Key.scratchText)
        }
    }

    func openDocument(at url: URL) throws {
        let data = try Data(contentsOf: url)
        guard let loadedText = String(data: data, encoding: .utf8) else {
            throw EditorSessionError.invalidTextEncoding
        }

        applyProgrammaticChange {
            text = loadedText
            fileURL = url
            lastSavedText = loadedText
            isDirty = false
            autosaveState = .saved(Date())
        }

        rememberRecentDocument(url)
    }

    func saveToCurrentLocation() throws {
        guard let fileURL else {
            throw EditorSessionError.missingSaveLocation
        }

        try write(text, to: fileURL)
        lastSavedText = text
        isDirty = false
        autosaveState = .saved(Date())
        rememberRecentDocument(fileURL)
    }

    func finishSave(at url: URL) {
        applyProgrammaticChange {
            fileURL = url
            lastSavedText = text
            isDirty = false
            autosaveState = .saved(Date())
            defaults.set("", forKey: Key.scratchText)
        }

        rememberRecentDocument(url)
    }

    func resolveRecentDocumentURL(for id: String) throws -> URL {
        guard let item = recentDocuments.first(where: { $0.id == id }) else {
            throw EditorSessionError.recentDocumentUnavailable
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: item.bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            rememberRecentDocument(url)
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            removeRecentDocument(id: id)
            throw EditorSessionError.recentDocumentUnavailable
        }

        return url
    }

    func clearRecentDocuments() {
        recentDocuments = []
        defaults.removeObject(forKey: Key.recentDocuments)
    }

    func removeRecentDocument(id: String) {
        recentDocuments.removeAll { $0.id == id }
        persistRecentDocuments()
    }

    private func bindChanges() {
        $text
            .dropFirst()
            .sink { [weak self] updatedText in
                guard let self else { return }
                guard !self.isApplyingProgrammaticChange else { return }

                if self.fileURL == nil {
                    self.defaults.set(updatedText, forKey: Key.scratchText)
                    self.isDirty = !updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    self.autosaveState = updatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .idle : .saved(Date())
                } else {
                    self.isDirty = updatedText != self.lastSavedText
                    self.autosaveState = updatedText != self.lastSavedText ? .saving : .saved(Date())
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest($text.dropFirst(), $fileURL)
            .debounce(for: .milliseconds(800), scheduler: DispatchQueue.main)
            .sink { [weak self] updatedText, fileURL in
                guard let self,
                      let fileURL,
                      !self.isApplyingProgrammaticChange,
                      updatedText != self.lastSavedText else {
                    return
                }

                do {
                    try self.write(updatedText, to: fileURL)
                    self.lastSavedText = updatedText
                    self.isDirty = false
                    self.autosaveState = .saved(Date())
                } catch {
                    // Leave the session dirty so the user can retry an explicit save.
                    self.isDirty = true
                    self.autosaveState = .failed
                }
            }
            .store(in: &cancellables)
    }

    private func rememberRecentDocument(_ url: URL) {
        guard url.isFileURL else { return }

        do {
            let bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            let item = RecentDocumentItem(
                id: url.standardizedFileURL.path,
                displayName: url.deletingPathExtension().lastPathComponent,
                parentPath: url.deletingLastPathComponent().lastPathComponent,
                bookmarkData: bookmarkData,
                lastOpenedAt: Date()
            )

            recentDocuments.removeAll { $0.id == item.id }
            recentDocuments.insert(item, at: 0)
            recentDocuments = Array(recentDocuments.prefix(8))
            persistRecentDocuments()
        } catch {
            // Ignore bookmark failures so opening and saving never fail because of recents.
        }
    }

    private func persistRecentDocuments() {
        do {
            let data = try JSONEncoder().encode(recentDocuments)
            defaults.set(data, forKey: Key.recentDocuments)
        } catch {
            defaults.removeObject(forKey: Key.recentDocuments)
        }
    }

    private static func loadRecentDocuments(from defaults: UserDefaults) -> [RecentDocumentItem] {
        guard let data = defaults.data(forKey: Key.recentDocuments) else {
            return []
        }

        return (try? JSONDecoder().decode([RecentDocumentItem].self, from: data)) ?? []
    }

    private func write(_ text: String, to url: URL) throws {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        try Data(text.utf8).write(to: url, options: .atomic)
    }

    private func applyProgrammaticChange(_ updates: () -> Void) {
        isApplyingProgrammaticChange = true
        updates()
        isApplyingProgrammaticChange = false
    }

    private func sanitizedFilenameFragment(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^#+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\[(.*?)\]\((.*?)\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"`([^`]*)`"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"[\\/:*?\"<>|]"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
