import SwiftUI

struct MarkdownPreviewView: View {
    @EnvironmentObject private var settings: EditorSettingsStore

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

        case .table(let table):
            tableBlock(table)

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
        let visibleContent = visibleLines.joined(separator: "\n")

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(language.isEmpty ? "plain text" : language.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                if let supportLabel = codeSupportLabel(for: language) {
                    Text(supportLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.56))
                }
                Button("Copy") {
                    ClipboardService.copy(content)
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.2))
            }

            HighlightedCodeView(
                code: visibleContent,
                language: language,
                showLineNumbers: settings.showCodeLineNumbers
            )

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

    private func tableBlock(_ table: MarkdownTable) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(table.headers.enumerated()), id: \.offset) { index, title in
                        tableCell(title, weight: .semibold, background: Color(red: 0.95, green: 0.91, blue: 0.84), alignment: table.alignments[index])
                    }
                }

                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { index, value in
                            tableCell(value, background: .white.opacity(0.9), alignment: table.alignments[index])
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(red: 0.84, green: 0.78, blue: 0.70), lineWidth: 1)
            )
        }
    }

    private func tableCell(_ value: String, weight: Font.Weight = .regular, background: Color, alignment: MarkdownTable.ColumnAlignment) -> some View {
        Text(value.isEmpty ? " " : value)
            .font(.system(size: 15, weight: weight, design: .serif))
            .frame(width: 180, alignment: frameAlignment(for: alignment))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(background)
            .overlay(
                Rectangle()
                    .fill(Color(red: 0.84, green: 0.78, blue: 0.70))
                    .frame(width: 1),
                alignment: .trailing
            )
    }

    private func frameAlignment(for alignment: MarkdownTable.ColumnAlignment) -> Alignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
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

    private func codeSupportLabel(for language: String) -> String? {
        switch language.lowercased() {
        case "mermaid":
            return "DIAGRAM SOURCE"
        case "json":
            return "JSON"
        case "yaml", "yml":
            return "YAML"
        case "latex", "tex":
            return "LATEX"
        default:
            return nil
        }
    }

    private var blocks: [PreviewBlock] {
        MarkdownRenderService.blocks(from: text).map { PreviewBlock(id: $0.id, kind: $0.kind) }
    }
}

private struct PreviewBlock: Identifiable {
    let id: Int
    let kind: MarkdownRenderBlock.Kind
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

private struct HighlightedCodeView: View {
    let code: String
    let language: String
    let showLineNumbers: Bool

    private var lines: [[CodeToken]] {
        CodeHighlightingService.highlightedLines(for: code, language: language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, tokens in
                HStack(alignment: .top, spacing: 12) {
                    if showLineNumbers {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.38))
                            .frame(width: 28, alignment: .trailing)
                    }

                    tokenText(tokens)
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tokenText(_ tokens: [CodeToken]) -> Text {
        tokens.reduce(Text("")) { partialResult, token in
            partialResult + Text(token.text).foregroundColor(CodeHighlightingService.color(for: token.kind))
        }
    }
}

#if canImport(UIKit)
private typealias PlatformImageValue = UIImage
#elseif canImport(AppKit)
private typealias PlatformImageValue = NSImage
#endif
