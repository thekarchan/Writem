import Foundation

struct MarkdownTable: Identifiable, Hashable {
    enum ColumnAlignment: String, CaseIterable, Identifiable, Hashable {
        case leading
        case center
        case trailing

        var id: Self { self }

        var title: String {
            switch self {
            case .leading:
                return "Left"
            case .center:
                return "Center"
            case .trailing:
                return "Right"
            }
        }

        var separator: String {
            switch self {
            case .leading:
                return ":---"
            case .center:
                return ":---:"
            case .trailing:
                return "---:"
            }
        }
    }

    let startLine: Int
    let endLine: Int
    var headers: [String]
    var alignments: [ColumnAlignment]
    var rows: [[String]]

    var id: Int { startLine }

    var markdown: String {
        let normalizedColumnCount = max(headers.count, alignments.count, rows.map(\.count).max() ?? 0, 1)
        let paddedHeaders = Self.padded(headers, to: normalizedColumnCount, fallback: "Column")
        let paddedAlignments = Array((alignments + Array(repeating: .leading, count: normalizedColumnCount)).prefix(normalizedColumnCount))
        let paddedRows = rows.map { Self.padded($0, to: normalizedColumnCount, fallback: "") }

        let headerLine = "| " + paddedHeaders.joined(separator: " | ") + " |"
        let separatorLine = "| " + paddedAlignments.map(\.separator).joined(separator: " | ") + " |"
        let rowLines = paddedRows.map { "| " + $0.joined(separator: " | ") + " |" }

        return ([headerLine, separatorLine] + rowLines).joined(separator: "\n")
    }

    mutating func ensureRectangular() {
        let columnCount = max(headers.count, alignments.count, rows.map(\.count).max() ?? 0, 1)
        headers = Self.padded(headers, to: columnCount, fallback: "Column")
        alignments = Array((alignments + Array(repeating: .leading, count: columnCount)).prefix(columnCount))
        rows = rows.map { Self.padded($0, to: columnCount, fallback: "") }
    }

    mutating func addRow() {
        ensureRectangular()
        rows.append(Array(repeating: "", count: headers.count))
    }

    mutating func removeRow(at index: Int) {
        guard rows.indices.contains(index) else {
            return
        }
        rows.remove(at: index)
    }

    mutating func addColumn() {
        ensureRectangular()
        headers.append("Column \(headers.count + 1)")
        alignments.append(.leading)
        rows = rows.map { $0 + [""] }
    }

    mutating func removeColumn(at index: Int) {
        guard headers.indices.contains(index), headers.count > 1 else {
            return
        }

        headers.remove(at: index)
        alignments.remove(at: index)
        rows = rows.map { row in
            var copy = row
            if copy.indices.contains(index) {
                copy.remove(at: index)
            }
            return copy
        }
    }

    static func empty(columns: Int = 3, rows: Int = 2, startLine: Int = 1) -> MarkdownTable {
        let safeColumns = max(columns, 1)
        let safeRows = max(rows, 0)
        let headers = (1...safeColumns).map { "Column \($0)" }
        let alignments = Array(repeating: ColumnAlignment.leading, count: safeColumns)
        let dataRows = Array(repeating: Array(repeating: "", count: safeColumns), count: safeRows)

        return MarkdownTable(
            startLine: startLine,
            endLine: startLine + safeRows + 1,
            headers: headers,
            alignments: alignments,
            rows: dataRows
        )
    }

    static func fromDelimitedText(_ string: String, startLine: Int = 1) -> MarkdownTable? {
        let normalized = string
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return nil
        }

        let delimiter: Character = normalized.contains("\t") ? "\t" : "|"
        let rawRows = normalized
            .components(separatedBy: "\n")
            .map { line in
                line
                    .split(separator: delimiter, omittingEmptySubsequences: delimiter == "\t")
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            .filter { !$0.isEmpty }

        guard let headers = rawRows.first, !headers.isEmpty else {
            return nil
        }

        let rows = Array(rawRows.dropFirst())
        return MarkdownTable(
            startLine: startLine,
            endLine: startLine + max(rows.count + 1, 1),
            headers: headers,
            alignments: Array(repeating: .leading, count: headers.count),
            rows: rows
        )
    }

    private static func padded(_ values: [String], to count: Int, fallback: String) -> [String] {
        if values.count >= count {
            return Array(values.prefix(count))
        }
        return values + Array(repeating: fallback, count: count - values.count)
    }
}

struct ParsedMarkdownTable {
    let table: MarkdownTable
    let consumedLineCount: Int
}

enum MarkdownTableService {
    static func tables(in markdown: String) -> [MarkdownTable] {
        let lines = FrontmatterParser.bodyText(from: markdown)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")

        var index = 0
        var items: [MarkdownTable] = []

        while index < lines.count {
            if let parsed = parseTable(in: lines, startingAt: index) {
                items.append(parsed.table)
                index += parsed.consumedLineCount
            } else {
                index += 1
            }
        }

        return items
    }

    static func parseTable(in lines: [String], startingAt startIndex: Int) -> ParsedMarkdownTable? {
        guard startIndex + 1 < lines.count else {
            return nil
        }

        let headerCells = cells(in: lines[startIndex])
        let separatorCells = cells(in: lines[startIndex + 1])

        guard headerCells.count >= 2,
              headerCells.count == separatorCells.count,
              separatorCells.allSatisfy(isSeparatorCell(_:)) else {
            return nil
        }

        var rows: [[String]] = []
        var currentIndex = startIndex + 2

        while currentIndex < lines.count {
            let line = lines[currentIndex]
            let cells = cells(in: line)
            if cells.count != headerCells.count || line.trimmingCharacters(in: .whitespaces).isEmpty {
                break
            }
            rows.append(cells)
            currentIndex += 1
        }

        let alignments = separatorCells.map(alignment(for:))
        let table = MarkdownTable(
            startLine: startIndex + 1,
            endLine: max(currentIndex, startIndex + 2),
            headers: headerCells,
            alignments: alignments,
            rows: rows
        )

        return ParsedMarkdownTable(table: table, consumedLineCount: max(currentIndex - startIndex, 2))
    }

    static func replacing(_ table: MarkdownTable, in markdown: String) -> String? {
        let body = FrontmatterParser.bodyText(from: markdown)
        let lines = body.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        let startIndex = max(table.startLine - 1, 0)
        let endIndex = min(table.endLine, lines.count)

        guard startIndex < endIndex else {
            return nil
        }

        var updatedLines = lines
        updatedLines.replaceSubrange(startIndex..<endIndex, with: table.markdown.components(separatedBy: "\n"))
        let updatedBody = updatedLines.joined(separator: "\n")
        return FrontmatterParser.replacingBody(in: markdown, with: updatedBody)
    }

    static func appending(_ table: MarkdownTable, to markdown: String) -> String {
        let body = FrontmatterParser.bodyText(from: markdown).trimmingCharacters(in: .whitespacesAndNewlines)
        let appendedBody: String

        if body.isEmpty {
            appendedBody = table.markdown + "\n"
        } else {
            appendedBody = body + "\n\n" + table.markdown + "\n"
        }

        return FrontmatterParser.replacingBody(in: markdown, with: appendedBody)
    }

    private static func cells(in line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("|") else {
            return []
        }

        let stripped = trimmed
            .trimmingCharacters(in: CharacterSet(charactersIn: "|"))

        return stripped
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private static func isSeparatorCell(_ cell: String) -> Bool {
        let trimmed = cell.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            return false
        }

        let withoutColons = trimmed.replacingOccurrences(of: ":", with: "")
        return !withoutColons.isEmpty && withoutColons.allSatisfy { $0 == "-" }
    }

    private static func alignment(for separatorCell: String) -> MarkdownTable.ColumnAlignment {
        let trimmed = separatorCell.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasLeadingColon = trimmed.hasPrefix(":")
        let hasTrailingColon = trimmed.hasSuffix(":")

        switch (hasLeadingColon, hasTrailingColon) {
        case (true, true):
            return .center
        case (false, true):
            return .trailing
        default:
            return .leading
        }
    }
}
