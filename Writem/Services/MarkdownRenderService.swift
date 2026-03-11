import Foundation

struct MarkdownRenderBlock: Identifiable, Hashable {
    enum Kind: Hashable {
        case heading(level: Int, text: String)
        case quote(String)
        case list(marker: String, value: String)
        case code(language: String, content: String)
        case image(altText: String, path: String)
        case table(MarkdownTable)
        case divider
        case paragraph(String)
    }

    let id: Int
    let kind: Kind
}

enum MarkdownRenderService {
    static func blocks(from markdown: String) -> [MarkdownRenderBlock] {
        let lines = FrontmatterParser.bodyText(from: markdown)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")

        var blocks: [MarkdownRenderBlock] = []
        var paragraphLines: [String] = []
        var paragraphStartLine = 1
        var inCodeBlock = false
        var codeStartLine = 1
        var codeLanguage = ""
        var codeLines: [String] = []
        var index = 0

        func flushParagraph() {
            let value = paragraphLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else {
                paragraphLines.removeAll()
                return
            }

            blocks.append(.init(id: paragraphStartLine, kind: .paragraph(value)))
            paragraphLines.removeAll()
        }

        while index < lines.count {
            let line = lines[index]
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
                index += 1
                continue
            }

            if inCodeBlock {
                codeLines.append(line)
                index += 1
                continue
            }

            if let parsedTable = MarkdownTableService.parseTable(in: lines, startingAt: index) {
                flushParagraph()
                blocks.append(.init(id: parsedTable.table.startLine, kind: .table(parsedTable.table)))
                index += parsedTable.consumedLineCount
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
                index += 1
                continue
            }

            let headingLevel = trimmed.prefix { $0 == "#" }.count
            if (1...6).contains(headingLevel), trimmed.dropFirst(headingLevel).first == " " {
                flushParagraph()
                let title = trimmed.dropFirst(headingLevel + 1).trimmingCharacters(in: .whitespacesAndNewlines)
                blocks.append(.init(id: lineNumber, kind: .heading(level: headingLevel, text: title)))
                index += 1
                continue
            }

            if trimmed == "---" || trimmed == "***" {
                flushParagraph()
                blocks.append(.init(id: lineNumber, kind: .divider))
                index += 1
                continue
            }

            if let imageReference = ImageResourceManager.imageReference(in: trimmed) {
                flushParagraph()
                blocks.append(.init(id: lineNumber, kind: .image(altText: imageReference.altText, path: imageReference.path)))
                index += 1
                continue
            }

            if trimmed.hasPrefix("> ") {
                flushParagraph()
                blocks.append(.init(id: lineNumber, kind: .quote(String(trimmed.dropFirst(2)))))
                index += 1
                continue
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flushParagraph()
                let marker = String(trimmed.prefix(1))
                let value = String(trimmed.dropFirst(2))
                blocks.append(.init(id: lineNumber, kind: .list(marker: marker, value: value)))
                index += 1
                continue
            }

            if let marker = orderedListMarker(in: trimmed) {
                flushParagraph()
                let value = trimmed.replacingOccurrences(of: marker + " ", with: "")
                blocks.append(.init(id: lineNumber, kind: .list(marker: marker, value: value)))
                index += 1
                continue
            }

            if paragraphLines.isEmpty {
                paragraphStartLine = lineNumber
            }
            paragraphLines.append(trimmed)
            index += 1
        }

        flushParagraph()
        return blocks
    }

    private static func orderedListMarker(in line: String) -> String? {
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
