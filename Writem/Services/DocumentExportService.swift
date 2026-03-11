import Foundation
import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct GeneratedExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.data, .plainText, .pdf, .html]
    }

    let data: Data
    let contentType: UTType

    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        self.data = data
        self.contentType = configuration.contentType
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}

struct ExportArtifact: Identifiable {
    let id = UUID()
    let document: GeneratedExportDocument
    let contentType: UTType
    let defaultFilename: String
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case markdown
    case html
    case pdf

    var id: Self { self }

    var title: String {
        rawValue.uppercased()
    }

    var symbolName: String {
        switch self {
        case .markdown:
            return "doc.plaintext"
        case .html:
            return "globe"
        case .pdf:
            return "doc.richtext"
        }
    }

    var fileExtension: String {
        switch self {
        case .markdown:
            return "md"
        case .html:
            return "html"
        case .pdf:
            return "pdf"
        }
    }

    var contentType: UTType {
        switch self {
        case .markdown:
            return UTType(filenameExtension: "md") ?? .plainText
        case .html:
            return .html
        case .pdf:
            return .pdf
        }
    }
}

enum DocumentExportService {
    @MainActor
    static func makeArtifact(
        format: ExportFormat,
        markdown: String,
        frontmatter: Frontmatter,
        documentURL: URL?,
        showCodeLineNumbers: Bool
    ) async throws -> ExportArtifact {
        let filenameStem = sanitizedFilename(from: frontmatter.title.isEmpty ? "Writem Export" : frontmatter.title)

        switch format {
        case .markdown:
            let data = Data(markdown.utf8)
            return ExportArtifact(
                document: GeneratedExportDocument(data: data, contentType: format.contentType),
                contentType: format.contentType,
                defaultFilename: filenameStem + "." + format.fileExtension
            )

        case .html:
            let html = htmlDocument(from: markdown, documentURL: documentURL, showCodeLineNumbers: showCodeLineNumbers)
            let data = Data(html.utf8)
            return ExportArtifact(
                document: GeneratedExportDocument(data: data, contentType: format.contentType),
                contentType: format.contentType,
                defaultFilename: filenameStem + "." + format.fileExtension
            )

        case .pdf:
            let html = htmlDocument(from: markdown, documentURL: documentURL, showCodeLineNumbers: showCodeLineNumbers)
            let pdfData = try await HTMLPDFExporter().renderPDF(from: html, baseURL: documentURL?.deletingLastPathComponent())
            return ExportArtifact(
                document: GeneratedExportDocument(data: pdfData, contentType: format.contentType),
                contentType: format.contentType,
                defaultFilename: filenameStem + "." + format.fileExtension
            )
        }
    }

    static func htmlDocument(from markdown: String, documentURL: URL?, showCodeLineNumbers: Bool) -> String {
        let blocks = MarkdownRenderService.blocks(from: markdown)
        var html = """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        :root {
            color-scheme: light;
            --text: #261f18;
            --muted: #6f6459;
            --border: #d8cfc4;
            --surface: #fffdf8;
            --surface-2: #f4ede4;
            --code-bg: #151515;
            --code-text: #f5f4f0;
            --accent: #c76c4c;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: Georgia, "Times New Roman", serif;
            color: var(--text);
            background: linear-gradient(160deg, #f6eee5, #fffdf8 60%);
        }
        main {
            width: min(860px, calc(100vw - 48px));
            margin: 40px auto;
            background: rgba(255,255,255,0.86);
            border: 1px solid rgba(216, 207, 196, 0.7);
            border-radius: 28px;
            padding: 40px;
            box-shadow: 0 24px 50px rgba(37, 28, 20, 0.08);
        }
        h1, h2, h3, h4, h5, h6 { color: #221a14; line-height: 1.15; }
        h1 { font-size: 2.4rem; }
        h2 { font-size: 2rem; margin-top: 2rem; }
        h3 { font-size: 1.6rem; margin-top: 1.6rem; }
        p, li, blockquote { font-size: 1.05rem; line-height: 1.75; }
        a { color: var(--accent); }
        hr { border: none; border-top: 1px solid var(--border); margin: 24px 0; }
        blockquote {
            margin: 0;
            padding: 10px 0 10px 18px;
            border-left: 4px solid rgba(199, 108, 76, 0.65);
            color: var(--muted);
        }
        .code-shell {
            margin: 18px 0;
            border-radius: 22px;
            overflow: hidden;
            background: var(--code-bg);
            color: var(--code-text);
        }
        .code-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 12px 16px;
            border-bottom: 1px solid rgba(255,255,255,0.08);
            font: 600 12px/1.2 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: rgba(255,255,255,0.72);
        }
        pre {
            margin: 0;
            padding: 18px;
            overflow-x: auto;
            font: 14px/1.65 Menlo, Monaco, Consolas, monospace;
        }
        .line {
            display: grid;
            grid-template-columns: \(showCodeLineNumbers ? "40px 1fr" : "1fr");
            gap: 12px;
            white-space: pre-wrap;
        }
        .line-number {
            color: rgba(255,255,255,0.35);
            text-align: right;
            user-select: none;
        }
        .token-keyword { color: #f6a93b; }
        .token-string { color: #86d6ad; }
        .token-number { color: #8dc7f5; }
        .token-comment { color: rgba(255,255,255,0.42); }
        .token-type { color: #cab4f9; }
        .token-literal { color: #f4cb85; }
        .token-directive { color: #f49595; }
        .token-key { color: #d9d494; }
        .token-operator { color: rgba(255,255,255,0.82); }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            overflow: hidden;
            border-radius: 18px;
        }
        th, td {
            border: 1px solid var(--border);
            padding: 12px 14px;
            text-align: left;
            vertical-align: top;
        }
        th { background: var(--surface-2); }
        img {
            max-width: 100%;
            border-radius: 18px;
            display: block;
        }
        .image-path {
            margin-top: 8px;
            font: 500 12px/1.4 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            color: var(--muted);
        }
        .support-note {
            font: 600 12px/1.2 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: rgba(255,255,255,0.65);
        }
        </style>
        </head>
        <body>
        <main>
        """

        var index = 0
        while index < blocks.count {
            let block = blocks[index]
            switch block.kind {
            case .heading(let level, let text):
                html += "<h\(level)>" + inlineHTML(text) + "</h\(level)>"
                index += 1

            case .quote(let text):
                html += "<blockquote>" + inlineHTML(text) + "</blockquote>"
                index += 1

            case .divider:
                html += "<hr>"
                index += 1

            case .paragraph(let text):
                html += "<p>" + inlineHTML(text) + "</p>"
                index += 1

            case .image(let altText, let path):
                html += imageHTML(altText: altText, path: path, documentURL: documentURL)
                index += 1

            case .table(let table):
                html += tableHTML(table)
                index += 1

            case .code(let language, let content):
                html += codeHTML(language: language, content: content, showLineNumbers: showCodeLineNumbers)
                index += 1

            case .list(let marker, _):
                let ordered = Int(marker.replacingOccurrences(of: ".", with: "")) != nil
                let tag = ordered ? "ol" : "ul"
                html += "<\(tag)>"

                while index < blocks.count {
                    guard case .list(_, let value) = blocks[index].kind else {
                        break
                    }
                    html += "<li>" + inlineHTML(value) + "</li>"
                    index += 1
                }

                html += "</\(tag)>"
            }
        }

        html += """
        </main>
        </body>
        </html>
        """

        return html
    }

    private static func imageHTML(altText: String, path: String, documentURL: URL?) -> String {
        let resolvedURL = ImageResourceManager.resolveImageURL(for: path, relativeTo: documentURL)
        let source = embeddedImageSource(for: resolvedURL) ?? escapeHTML(path)
        let alt = escapeHTML(altText.isEmpty ? "Image" : altText)

        return """
        <figure>
            <img src="\(source)" alt="\(alt)">
            <figcaption class="image-path">\(escapeHTML(path))</figcaption>
        </figure>
        """
    }

    private static func tableHTML(_ table: MarkdownTable) -> String {
        let header = table.headers.map { "<th>\(inlineHTML($0))</th>" }.joined()
        let rows = table.rows.map { row in
            "<tr>" + row.map { "<td>\(inlineHTML($0))</td>" }.joined() + "</tr>"
        }.joined()

        return "<table><thead><tr>\(header)</tr></thead><tbody>\(rows)</tbody></table>"
    }

    private static func codeHTML(language: String, content: String, showLineNumbers: Bool) -> String {
        let normalizedLanguage = language.isEmpty ? "plain text" : language.uppercased()
        let supportNote: String

        switch language.lowercased() {
        case "mermaid":
            supportNote = "<span class=\"support-note\">Mermaid source</span>"
        case "latex", "tex":
            supportNote = "<span class=\"support-note\">LaTeX source</span>"
        case "yaml", "yml":
            supportNote = "<span class=\"support-note\">YAML</span>"
        case "json":
            supportNote = "<span class=\"support-note\">JSON</span>"
        default:
            supportNote = ""
        }

        let highlighted = CodeHighlightingService.highlightedLines(for: content, language: language)
        let linesHTML = highlighted.enumerated().map { index, line in
            let tokenHTML = line.map { token in
                let cssClass: String
                switch token.kind {
                case .plain:
                    cssClass = ""
                case .keyword:
                    cssClass = "token-keyword"
                case .string:
                    cssClass = "token-string"
                case .number:
                    cssClass = "token-number"
                case .comment:
                    cssClass = "token-comment"
                case .type:
                    cssClass = "token-type"
                case .literal:
                    cssClass = "token-literal"
                case .directive:
                    cssClass = "token-directive"
                case .key:
                    cssClass = "token-key"
                case .operator:
                    cssClass = "token-operator"
                }

                let escaped = escapeHTML(token.text)
                if cssClass.isEmpty {
                    return escaped
                }
                return "<span class=\"\(cssClass)\">\(escaped)</span>"
            }.joined()

            if showLineNumbers {
                return "<div class=\"line\"><span class=\"line-number\">\(index + 1)</span><span>\(tokenHTML)</span></div>"
            }

            return "<div class=\"line\"><span>\(tokenHTML)</span></div>"
        }.joined()

        return """
        <section class="code-shell">
            <div class="code-header"><span>\(escapeHTML(normalizedLanguage))</span>\(supportNote)</div>
            <pre><code>\(linesHTML)</code></pre>
        </section>
        """
    }

    private static func inlineHTML(_ string: String) -> String {
        var html = escapeHTML(string)

        html = replace(pattern: #"`([^`]+)`"#, in: html, template: "<code>$1</code>")
        html = replace(pattern: #"\*\*([^*]+)\*\*"#, in: html, template: "<strong>$1</strong>")
        html = replace(pattern: #"(?<!\*)\*([^*]+)\*(?!\*)"#, in: html, template: "<em>$1</em>")
        html = replace(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#, in: html, template: "<a href=\"$2\">$1</a>")

        return html
    }

    private static func replace(pattern: String, in string: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return string
        }

        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        return regex.stringByReplacingMatches(in: string, range: range, withTemplate: template)
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func embeddedImageSource(for url: URL?) -> String? {
        guard let url else {
            return nil
        }

        if !url.isFileURL {
            return url.absoluteString
        }

        guard let data = try? Data(contentsOf: url) else {
            return url.absoluteString
        }

        let mimeType = mimeType(for: url.pathExtension)
        return "data:\(mimeType);base64,\(data.base64EncodedString())"
    }

    private static func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "heic":
            return "image/heic"
        default:
            return "image/png"
        }
    }

    private static func sanitizedFilename(from title: String) -> String {
        let components = title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return components.isEmpty ? "writem-export" : components.joined(separator: "-").lowercased()
    }
}

@MainActor
private final class HTMLPDFExporter: NSObject, WKNavigationDelegate {
    private let webView = WKWebView(frame: .init(x: 0, y: 0, width: 900, height: 1200))
    private var continuation: CheckedContinuation<Data, Error>?

    func renderPDF(from html: String, baseURL: URL?) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            webView.navigationDelegate = self
            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let configuration = WKPDFConfiguration()
        webView.createPDF(configuration: configuration) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let data):
                self.continuation?.resume(returning: data)
            case .failure(let error):
                self.continuation?.resume(throwing: error)
            }
            self.continuation = nil
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
