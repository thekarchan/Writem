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

enum EditorSessionError: LocalizedError {
    case invalidTextEncoding
    case missingSaveLocation

    var errorDescription: String? {
        switch self {
        case .invalidTextEncoding:
            return "The selected file could not be read as UTF-8 Markdown."
        case .missingSaveLocation:
            return "Choose a save location first."
        }
    }
}

@MainActor
final class EditorSessionStore: ObservableObject {
    @Published var text: String
    @Published var fileURL: URL?
    @Published private(set) var isDirty: Bool
    @Published private(set) var openRequestID: UUID?
    @Published private(set) var saveRequest: EditorSaveRequest?

    private let defaults: UserDefaults
    private var lastSavedText: String
    private var cancellables: Set<AnyCancellable> = []
    private var isApplyingProgrammaticChange = false

    private enum Key {
        static let scratchText = "editor.scratchText"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let scratchText = defaults.string(forKey: Key.scratchText) ?? SampleDocument.content
        self.text = scratchText
        self.fileURL = nil
        self.lastSavedText = ""
        self.isDirty = !scratchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

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

    func requestOpenDocument() {
        openRequestID = UUID()
    }

    func consumeOpenRequest() {
        openRequestID = nil
    }

    func requestSave(forceSaveAs: Bool = false) {
        saveRequest = .init(forceSaveAs: forceSaveAs)
    }

    func consumeSaveRequest() {
        saveRequest = nil
    }

    func restoreScratchDraft() {
        applyProgrammaticChange {
            text = defaults.string(forKey: Key.scratchText) ?? SampleDocument.content
            fileURL = nil
            lastSavedText = ""
            isDirty = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        }
    }

    func saveToCurrentLocation() throws {
        guard let fileURL else {
            throw EditorSessionError.missingSaveLocation
        }

        try write(text, to: fileURL)
        lastSavedText = text
        isDirty = false
    }

    func finishSave(at url: URL) {
        applyProgrammaticChange {
            fileURL = url
            lastSavedText = text
            isDirty = false
            defaults.set("", forKey: Key.scratchText)
        }
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
                } else {
                    self.isDirty = updatedText != self.lastSavedText
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
                } catch {
                    // Leave the session dirty so the user can retry an explicit save.
                    self.isDirty = true
                }
            }
            .store(in: &cancellables)
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
