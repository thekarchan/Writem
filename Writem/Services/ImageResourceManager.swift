import Foundation
import UniformTypeIdentifiers

struct ImportedImageAsset: Identifiable, Hashable {
    let id = UUID()
    let sourceURL: URL
    let destinationURL: URL
    let relativePath: String
    let markdownReference: String
}

struct MarkdownImageReference: Hashable {
    let altText: String
    let path: String
}

enum ImageResourceError: LocalizedError {
    case unsavedDocument
    case unsupportedFile(URL)
    case copyFailed(URL, String)

    var errorDescription: String? {
        switch self {
        case .unsavedDocument:
            return "Save the Markdown document first so Writem knows where to create the local assets folder."
        case .unsupportedFile(let url):
            return "\(url.lastPathComponent) is not a supported image file."
        case .copyFailed(let url, let reason):
            return "Failed to import \(url.lastPathComponent): \(reason)"
        }
    }
}

enum ImageResourceManager {
    static let assetsFolderName = "assets"

    static func canImport(_ url: URL) -> Bool {
        if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let type = resourceValues.contentType {
            return type.conforms(to: .image)
        }

        guard !url.pathExtension.isEmpty,
              let type = UTType(filenameExtension: url.pathExtension) else {
            return false
        }

        return type.conforms(to: .image)
    }

    static func imageReference(in line: String) -> MarkdownImageReference? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let regex = try? NSRegularExpression(pattern: #"^!\[(.*?)\]\((.*?)\)$"#) else {
            return nil
        }

        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, range: range),
              let altRange = Range(match.range(at: 1), in: trimmed),
              let pathRange = Range(match.range(at: 2), in: trimmed) else {
            return nil
        }

        return MarkdownImageReference(
            altText: String(trimmed[altRange]),
            path: String(trimmed[pathRange])
        )
    }

    static func resolveImageURL(for path: String, relativeTo documentURL: URL?) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let remoteURL = URL(string: trimmed),
           let scheme = remoteURL.scheme?.lowercased(),
           ["http", "https", "file"].contains(scheme) {
            return remoteURL
        }

        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }

        guard let documentURL else {
            return nil
        }

        return documentURL
            .deletingLastPathComponent()
            .appendingPathComponent(trimmed)
            .standardizedFileURL
    }

    static func importImages(from sourceURLs: [URL], into documentURL: URL?) throws -> [ImportedImageAsset] {
        guard !sourceURLs.isEmpty else {
            return []
        }

        guard let documentURL else {
            throw ImageResourceError.unsavedDocument
        }

        let fileManager = FileManager.default
        let documentAccess = documentURL.startAccessingSecurityScopedResource()
        defer {
            if documentAccess {
                documentURL.stopAccessingSecurityScopedResource()
            }
        }

        let documentDirectory = documentURL.deletingLastPathComponent()
        let assetsDirectory = documentDirectory.appendingPathComponent(assetsFolderName, isDirectory: true)
        try fileManager.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)

        return try sourceURLs.map { sourceURL in
            guard canImport(sourceURL) else {
                throw ImageResourceError.unsupportedFile(sourceURL)
            }

            let sourceAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if sourceAccess {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let destinationURL = try uniqueDestinationURL(for: sourceURL, in: assetsDirectory)

            if sourceURL.standardizedFileURL != destinationURL.standardizedFileURL {
                do {
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                } catch {
                    throw ImageResourceError.copyFailed(sourceURL, error.localizedDescription)
                }
            }

            let relativePath = assetsFolderName + "/" + destinationURL.lastPathComponent
            let altText = readableAltText(from: destinationURL)

            return ImportedImageAsset(
                sourceURL: sourceURL,
                destinationURL: destinationURL,
                relativePath: relativePath,
                markdownReference: "![\(altText)](\(relativePath))"
            )
        }
    }

    private static func uniqueDestinationURL(for sourceURL: URL, in assetsDirectory: URL) throws -> URL {
        let fileManager = FileManager.default
        let ext = normalizedPathExtension(for: sourceURL)
        let baseName = sanitizedBaseName(for: sourceURL)

        var candidate = assetsDirectory.appendingPathComponent(baseName).appendingPathExtension(ext)
        var counter = 2

        while fileManager.fileExists(atPath: candidate.path),
              candidate.standardizedFileURL != sourceURL.standardizedFileURL {
            candidate = assetsDirectory
                .appendingPathComponent("\(baseName)-\(counter)")
                .appendingPathExtension(ext)
            counter += 1
        }

        return candidate
    }

    private static func sanitizedBaseName(for sourceURL: URL) -> String {
        let raw = sourceURL.deletingPathExtension().lastPathComponent
        let slug = raw
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return slug.isEmpty ? "image" : slug
    }

    private static func readableAltText(from url: URL) -> String {
        let raw = url.deletingPathExtension().lastPathComponent
        let spaced = raw
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return spaced.isEmpty ? "Imported image" : spaced
    }

    private static func normalizedPathExtension(for sourceURL: URL) -> String {
        let ext = sourceURL.pathExtension.lowercased()
        return ext.isEmpty ? "png" : ext
    }
}
