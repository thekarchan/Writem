import SwiftUI

struct MarkdownPreviewView: View {
    let text: String
    let jumpToLine: Int?
    let documentURL: URL?

    @State private var expandedCodeBlocks: Set<Int> = []

    private let collapsedCodeLineCount = 12

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(blocks) { block in
                        blockView(block)
                            .id(block.id)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(28)
            }
            .onChange(of: jumpToLine) { _, line in
                guard let line else {
                    return
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(line, anchor: .top)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.84))
                .shadow(color: Color.black.opacity(0.07), radius: 16, x: 0, y: 8)
        )
    }

    @ViewBuilder
    private func blockView(_ block: PreviewBlock) -> some View {
        switch block.kind {
        case .heading(let level, let value):
            Text(value)
                .font(font(for: level))
                .foregroundStyle(Color(red: 0.18, green: 0.15, blue: 0.12))
                .padding(.top, level == 1 ? 4 : 10)

        case .quote(let value):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.accentColor.opacity(0.55))
                    .frame(width: 4)
                inlineMarkdown(value)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)

        case .list(let marker, let value):
            HStack(alignment: .top, spacing: 10) {
                Text(marker)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                inlineMarkdown(value)
            }

        case .code(let language, let content):
            codeBlock(id: block.id, language: language, content: content)

        case .image(let altText, let path):
            imageBlock(altText: altText, path: path)

        case .divider:
            Divider()
                .padding(.vertical, 4)

        case .paragraph(let value):
            inlineMarkdown(value)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(Color(red: 0.18, green: 0.15, blue: 0.12))
                .textSelection(.enabled)
        }
    }

    private func codeBlock(id: Int, language: String, content: String) -> some View {
        let lines = content.components(separatedBy: "\n")
        let isExpanded = expandedCodeBlocks.contains(id)
        let visibleLines = isExpanded ? lines : Array(lines.prefix(collapsedCodeLineCount))

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(language.isEmpty ? "plain text" : language.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Button("Copy") {
                    ClipboardService.copy(content)
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.2))
            }

            Text(visibleLines.joined(separator: "\n"))
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.94))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            if lines.count > collapsedCodeLineCount {
                Button(isExpanded ? "Collapse" : "Show \(lines.count - collapsedCodeLineCount) more lines") {
                    if isExpanded {
                        expandedCodeBlocks.remove(id)
                    } else {
                        expandedCodeBlocks.insert(id)
                    }
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.88))
        )
    }

    private func imageBlock(altText: String, path: String) -> some View {
        let resolvedURL = ImageResourceManager.resolveImageURL(for: path, relativeTo: documentURL)

        return VStack(alignment: .leading, spacing: 10) {
            ResolvedMarkdownImageView(url: resolvedURL, altText: altText)
            Text(path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.97, green: 0.95, blue: 0.91))
        )
    }

    private func inlineMarkdown(_ string: String) -> Text {
        if let attributed = try? AttributedString(markdown: string) {
            return Text(attributed)
        }
        return Text(string)
    }

    private func font(for level: Int) -> Font {
        switch level {
        case 1:
            return .system(size: 34, weight: .bold, design: .serif)
        case 2:
            return .system(size: 28, weight: .bold, design: .serif)
        case 3:
            return .system(size: 24, weight: .semibold, design: .serif)
        case 4:
            return .system(size: 21, weight: .semibold, design: .serif)
        case 5:
            return .system(size: 19, weight: .semibold, design: .serif)
        default:
            return .system(size: 17, weight: .semibold, design: .serif)
        }
    }

    private var blocks: [PreviewBlock] {
        let lines = FrontmatterParser.bodyText(from: text)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")

        var blocks: [PreviewBlock] = []
        var paragraphLines: [String] = []
        var paragraphStartLine = 1
        var inCodeBlock = false
        var codeStartLine = 1
        var codeLanguage = ""
        var codeLines: [String] = []

        func flushParagraph() {
            let value = paragraphLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else {
                paragraphLines.removeAll()
                return
            }

            blocks.append(.init(id: paragraphStartLine, kind: .paragraph(value)))
            paragraphLines.removeAll()
        }

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                flushParagraph()
                if inCodeBlock {
                    blocks.append(.init(id: codeStartLine, kind: .code(language: codeLanguage, content: codeLines.joined(separator: "\n"))))
                    codeLanguage = ""
                    codeLines.removeAll()
                } else {
                    codeStartLine = lineNumber
                    codeLanguage = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                inCodeBlock.toggle()
                continue
            }

            if inCodeBlock {
                codeLines.append(line)
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
                continue
            }

            let headingLevel = trimmed.prefix { $0 == "#" }.count
            if (1...6).contains(headingLevel), trimmed.dropFirst(headingLevel).first == " " {
                flushParagraph()
                let title = trimmed.dropFirst(headingLevel + 1).trimmingCharacters(in: .whitespacesAndNewlines)
                blocks.append(.init(id: lineNumber, kind: .heading(level: headingLevel, text: title)))
                continue
            }

            if trimmed == "---" || trimmed == "***" {
                flushParagraph()
                blocks.append(.init(id: lineNumber, kind: .divider))
                continue
            }

            if let imageReference = ImageResourceManager.imageReference(in: trimmed) {
                flushParagraph()
                blocks.append(.init(id: lineNumber, kind: .image(altText: imageReference.altText, path: imageReference.path)))
                continue
            }

            if trimmed.hasPrefix("> ") {
                flushParagraph()
                blocks.append(.init(id: lineNumber, kind: .quote(String(trimmed.dropFirst(2)))))
                continue
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushParagraph()
                let marker = String(trimmed.prefix(1))
                let value = String(trimmed.dropFirst(2))
                blocks.append(.init(id: lineNumber, kind: .list(marker: marker, value: value)))
                continue
            }

            if let marker = orderedListMarker(in: trimmed) {
                flushParagraph()
                let value = trimmed.replacingOccurrences(of: marker + " ", with: "")
                blocks.append(.init(id: lineNumber, kind: .list(marker: marker, value: value)))
                continue
            }

            if paragraphLines.isEmpty {
                paragraphStartLine = lineNumber
            }
            paragraphLines.append(trimmed)
        }

        flushParagraph()
        return blocks
    }

    private func orderedListMarker(in line: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"^\d+\."#) else {
            return nil
        }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let markerRange = Range(match.range, in: line) else {
            return nil
        }
        return String(line[markerRange])
    }
}

private struct PreviewBlock: Identifiable {
    enum Kind {
        case heading(level: Int, text: String)
        case quote(String)
        case list(marker: String, value: String)
        case code(language: String, content: String)
        case image(altText: String, path: String)
        case divider
        case paragraph(String)
    }

    let id: Int
    let kind: Kind
}

private struct ResolvedMarkdownImageView: View {
    let url: URL?
    let altText: String

    var body: some View {
        Group {
            if let url {
                if url.isFileURL {
                    if let image = platformImage(from: url) {
                        platformImageView(image)
                    } else {
                        placeholder(message: "Unable to load local image")
                    }
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            placeholder(message: "Unable to load remote image")
                        default:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 180)
                        }
                    }
                }
            } else {
                placeholder(message: "Image preview unavailable")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 360)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func platformImageView(_ image: PlatformImageValue) -> some View {
        #if canImport(UIKit)
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
        #elseif canImport(AppKit)
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
        #endif
    }

    private func placeholder(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "photo")
                .font(.title2)
            Text(altText.isEmpty ? message : altText)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color.white.opacity(0.58))
    }

    private func platformImage(from url: URL) -> PlatformImageValue? {
        #if canImport(UIKit)
        return UIImage(contentsOfFile: url.path)
        #elseif canImport(AppKit)
        return NSImage(contentsOf: url)
        #endif
    }
}

#if canImport(UIKit)
private typealias PlatformImageValue = UIImage
#elseif canImport(AppKit)
private typealias PlatformImageValue = NSImage
#endif
