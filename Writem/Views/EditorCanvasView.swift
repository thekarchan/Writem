import SwiftUI

#if canImport(AppKit)
import AppKit
private typealias PlatformFont = NSFont
private typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
private typealias PlatformFont = UIFont
private typealias PlatformColor = UIColor
#endif

struct SlashCommandContext: Equatable {
    let query: String
    let replacementRange: NSRange
    let leadingWhitespace: Int
}

enum SlashTemplateAction: Equatable {
    case insert(String)
    case requestImageImport
}

struct EditorSlashTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    let symbolName: String
    let detail: String
    let action: SlashTemplateAction

    var searchTerms: [String] {
        [title, detail]
    }
}

struct EditorSlashCommand: Identifiable, Equatable {
    let id: String
    let title: String
    let symbolName: String
    let detail: String
    let aliases: [String]
    let primaryTemplate: EditorSlashTemplate
    let secondaryTemplates: [EditorSlashTemplate]

    var canExpand: Bool {
        !secondaryTemplates.isEmpty
    }

    var searchTerms: [String] {
        [id, title, detail] + aliases + secondaryTemplates.flatMap(\.searchTerms)
    }

    static let all: [EditorSlashCommand] = [
        .init(
            id: "heading",
            title: "Heading",
            symbolName: "textformat.size",
            detail: "/heading",
            aliases: ["h1", "title", "section"],
            primaryTemplate: .insert(
                id: "heading-h1",
                title: "Heading 1",
                symbolName: "textformat.size.larger",
                detail: "# New section",
                content: "# New section"
            ),
            secondaryTemplates: [
                .insert(id: "heading-h1", title: "Heading 1", symbolName: "textformat.size.larger", detail: "# New section", content: "# New section"),
                .insert(id: "heading-h2", title: "Heading 2", symbolName: "textformat.size", detail: "## New subsection", content: "## New subsection"),
                .insert(id: "heading-h3", title: "Heading 3", symbolName: "textformat", detail: "### Supporting point", content: "### Supporting point")
            ]
        ),
        .init(
            id: "list",
            title: "List",
            symbolName: "list.bullet",
            detail: "/list",
            aliases: ["bullet", "ul", "points"],
            primaryTemplate: .insert(
                id: "list-bullets",
                title: "Bullet List",
                symbolName: "list.bullet",
                detail: "- First point",
                content: "- First point\n- Second point\n- Third point"
            ),
            secondaryTemplates: [
                .insert(id: "list-bullets", title: "Bullet List", symbolName: "list.bullet", detail: "- First point", content: "- First point\n- Second point\n- Third point"),
                .insert(id: "list-numbered", title: "Numbered List", symbolName: "list.number", detail: "1. First step", content: "1. First step\n2. Second step\n3. Third step"),
                .insert(id: "list-checklist", title: "Checklist", symbolName: "checklist", detail: "- [ ] First task", content: "- [ ] First task\n- [ ] Second task\n- [ ] Third task")
            ]
        ),
        .init(
            id: "quote",
            title: "Quote",
            symbolName: "text.quote",
            detail: "/quote",
            aliases: ["blockquote", "callout"],
            primaryTemplate: .insert(
                id: "quote-standard",
                title: "Quote",
                symbolName: "text.quote",
                detail: "> A highlighted quote block",
                content: "> A highlighted quote block"
            ),
            secondaryTemplates: [
                .insert(id: "quote-standard", title: "Quote", symbolName: "text.quote", detail: "> A highlighted quote block", content: "> A highlighted quote block"),
                .insert(id: "quote-note", title: "Note", symbolName: "note.text", detail: "> **Note:** Add supporting context", content: "> **Note:** Add supporting context"),
                .insert(id: "quote-pull", title: "Pull Quote", symbolName: "quote.bubble", detail: "> Memorable line\n>\n> Author", content: "> Memorable line\n>\n> Author")
            ]
        ),
        .init(
            id: "code",
            title: "Code Block",
            symbolName: "curlybraces",
            detail: "/code",
            aliases: ["fence", "snippet"],
            primaryTemplate: .insert(
                id: "code-swift",
                title: "Swift",
                symbolName: "swift",
                detail: "```swift",
                content: "```swift\nprint(\"Hello, Writem\")\n```"
            ),
            secondaryTemplates: [
                .insert(id: "code-swift", title: "Swift", symbolName: "swift", detail: "```swift", content: "```swift\nprint(\"Hello, Writem\")\n```"),
                .insert(id: "code-js", title: "JavaScript", symbolName: "curlybraces.square", detail: "```js", content: "```js\nconsole.log(\"Hello, Writem\")\n```"),
                .insert(id: "code-bash", title: "Shell", symbolName: "terminal", detail: "```bash", content: "```bash\nwritem build\n```"),
                .insert(id: "code-json", title: "JSON", symbolName: "number.square", detail: "```json", content: "```json\n{\n  \"title\": \"Writem\"\n}\n```"),
                .insert(id: "code-mermaid", title: "Mermaid", symbolName: "point.3.filled.connected.trianglepath.dotted", detail: "```mermaid", content: "```mermaid\ngraph TD\n    A[Start] --> B[Write]\n```")
            ]
        ),
        .init(
            id: "table",
            title: "Table",
            symbolName: "tablecells",
            detail: "/table",
            aliases: ["grid", "spreadsheet"],
            primaryTemplate: .insert(
                id: "table-basic",
                title: "Two Columns",
                symbolName: "tablecells",
                detail: "| Column A | Column B |",
                content: "| Column A | Column B |\n| --- | --- |\n| Value | Value |"
            ),
            secondaryTemplates: [
                .insert(id: "table-basic", title: "Two Columns", symbolName: "tablecells", detail: "| Column A | Column B |", content: "| Column A | Column B |\n| --- | --- |\n| Value | Value |"),
                .insert(id: "table-three", title: "Three Columns", symbolName: "square.split.3x1", detail: "| Column A | Column B | Column C |", content: "| Column A | Column B | Column C |\n| --- | --- | --- |\n| Value | Value | Value |"),
                .insert(id: "table-compare", title: "Comparison", symbolName: "arrow.left.arrow.right.square", detail: "| Option | Pros | Cons |", content: "| Option | Pros | Cons |\n| --- | --- | --- |\n| A | Fast | Limited |\n| B | Flexible | More setup |")
            ]
        ),
        .init(
            id: "divider",
            title: "Divider",
            symbolName: "minus",
            detail: "/divider",
            aliases: ["hr", "rule", "separator"],
            primaryTemplate: .insert(
                id: "divider-standard",
                title: "Divider",
                symbolName: "minus",
                detail: "---",
                content: "---"
            ),
            secondaryTemplates: []
        ),
        .init(
            id: "image",
            title: "Image",
            symbolName: "photo",
            detail: "/image",
            aliases: ["photo", "media", "figure"],
            primaryTemplate: .imageImport(
                id: "image-import",
                title: "Import Image",
                symbolName: "photo.badge.plus",
                detail: "Open the image picker"
            ),
            secondaryTemplates: []
        )
    ]

    static func matching(query: String) -> [EditorSlashCommand] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return all
        }

        return all.filter { command in
            command.id.localizedCaseInsensitiveContains(normalized)
                || command.title.localizedCaseInsensitiveContains(normalized)
                || command.aliases.contains(where: { $0.localizedCaseInsensitiveContains(normalized) })
        }
    }

    static func == (lhs: EditorSlashCommand, rhs: EditorSlashCommand) -> Bool {
        lhs.id == rhs.id
    }
}

private extension EditorSlashTemplate {
    static func insert(id: String, title: String, symbolName: String, detail: String, content: String) -> Self {
        .init(id: id, title: title, symbolName: symbolName, detail: detail, action: .insert(content))
    }

    static func imageImport(id: String, title: String, symbolName: String, detail: String) -> Self {
        .init(id: id, title: title, symbolName: symbolName, detail: detail, action: .requestImageImport)
    }
}

struct EditorCanvasReplacement: Equatable {
    let replacementRange: NSRange
    let replacementText: String
    let selectedRange: NSRange
}

private enum SlashCommandKeyboardAction {
    case moveSelection(Int)
    case submit
    case expand
    case collapse
    case dismiss
}

private enum SlashPaletteShortcut {
    static func index(for replacementText: String?) -> Int? {
        guard let replacementText,
              replacementText.count == 1,
              let value = Int(replacementText),
              (1...9).contains(value) else {
            return nil
        }

        return value - 1
    }
}

private final class SlashUsageStore: ObservableObject {
    @Published private(set) var revision = UUID()

    private let defaults: UserDefaults

    private enum Key {
        static let sequence = "editor.slashUsageSequence"
        static let usages = "editor.slashUsages"
    }

    private var sequence: Int
    private var usages: [String: Int]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.sequence = defaults.integer(forKey: Key.sequence)
        self.usages = defaults.dictionary(forKey: Key.usages) as? [String: Int] ?? [:]
    }

    func record(commandID: String?, templateID: String?) {
        sequence += 1

        if let commandID {
            usages["command:\(commandID)"] = sequence
        }

        if let templateID {
            usages["template:\(templateID)"] = sequence
        }

        defaults.set(sequence, forKey: Key.sequence)
        defaults.set(usages, forKey: Key.usages)
        revision = UUID()
    }

    func recency(for command: EditorSlashCommand) -> Int {
        let commandRecency = usages["command:\(command.id)"] ?? 0
        let templateRecency = ([command.primaryTemplate] + command.secondaryTemplates)
            .compactMap { usages["template:\($0.id)"] }
            .max() ?? 0
        return max(commandRecency, templateRecency)
    }

    func recency(for template: EditorSlashTemplate) -> Int {
        usages["template:\(template.id)"] ?? 0
    }
}

private enum SlashPaletteSearch {
    private struct RankedCommand {
        let command: EditorSlashCommand
        let matchScore: Int
        let recency: Int
        let index: Int
    }

    private struct RankedTemplate {
        let template: EditorSlashTemplate
        let matchScore: Int
        let recency: Int
        let index: Int
    }

    static func rankCommands(
        _ commands: [EditorSlashCommand],
        query: String,
        usageStore: SlashUsageStore
    ) -> [EditorSlashCommand] {
        let normalizedQuery = normalize(query)

        return Array(commands.enumerated())
            .compactMap { item in
                let index = item.offset
                let command = item.element

                guard let matchScore = commandScore(for: command, query: normalizedQuery) else {
                    return nil
                }

                return RankedCommand(
                    command: command,
                    matchScore: matchScore,
                    recency: usageStore.recency(for: command),
                    index: index
                )
            }
            .sorted { (lhs: RankedCommand, rhs: RankedCommand) in
                if lhs.matchScore != rhs.matchScore {
                    return lhs.matchScore > rhs.matchScore
                }
                if lhs.recency != rhs.recency {
                    return lhs.recency > rhs.recency
                }
                return lhs.index < rhs.index
            }
            .map(\.command)
    }

    static func rankTemplates(
        _ templates: [EditorSlashTemplate],
        query: String,
        usageStore: SlashUsageStore
    ) -> [EditorSlashTemplate] {
        let normalizedQuery = normalize(query)

        return Array(templates.enumerated())
            .compactMap { item in
                let index = item.offset
                let template = item.element

                return RankedTemplate(
                    template: template,
                    matchScore: templateScore(for: template, query: normalizedQuery) ?? 0,
                    recency: usageStore.recency(for: template),
                    index: index
                )
            }
            .sorted { (lhs: RankedTemplate, rhs: RankedTemplate) in
                if lhs.matchScore != rhs.matchScore {
                    return lhs.matchScore > rhs.matchScore
                }
                if lhs.recency != rhs.recency {
                    return lhs.recency > rhs.recency
                }
                return lhs.index < rhs.index
            }
            .map(\.template)
    }

    static func highlightRanges(in value: String, query: String) -> [Range<String.Index>] {
        let tokens = query
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !tokens.isEmpty, !value.isEmpty else {
            return []
        }

        let collectedRanges = tokens.flatMap { highlightRanges(for: $0, in: value) }
        return mergeRanges(collectedRanges)
    }

    private static func commandScore(for command: EditorSlashCommand, query: String) -> Int? {
        compositeScore(for: command.searchTerms, query: query)
    }

    private static func templateScore(for template: EditorSlashTemplate, query: String) -> Int? {
        compositeScore(for: template.searchTerms, query: query)
    }

    private static func compositeScore(for terms: [String], query: String) -> Int? {
        guard !query.isEmpty else {
            return 0
        }

        let tokens = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else {
            return 0
        }

        var totalScore = 0

        for token in tokens {
            let bestTokenScore = terms.compactMap { score(token: token, against: $0) }.max()
            guard let bestTokenScore else {
                return nil
            }
            totalScore += bestTokenScore
        }

        return totalScore
    }

    private static func score(token: String, against rawTerm: String) -> Int? {
        let term = normalize(rawTerm)
        guard !term.isEmpty, !token.isEmpty else {
            return nil
        }

        if term == token {
            return 1800
        }

        if term.hasPrefix(token) {
            return 1500 - min(term.count, 180)
        }

        if let wordScore = wordPrefixScore(token: token, term: term) {
            return wordScore
        }

        let initials = wordInitials(for: term)
        if !initials.isEmpty, initials.hasPrefix(token) {
            return 1080 + (token.count * 16)
        }

        if let range = term.range(of: token) {
            let distance = term.distance(from: term.startIndex, to: range.lowerBound)
            return 920 - min(distance * 6, 240)
        }

        if let fuzzyScore = fuzzySubsequenceScore(token: token, term: term) {
            return 620 + fuzzyScore
        }

        return nil
    }

    private static func wordPrefixScore(token: String, term: String) -> Int? {
        let words = term.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        guard let index = words.firstIndex(where: { $0.hasPrefix(token) }) else {
            return nil
        }

        return 1240 - (index * 18) - min(words[index].count, 80)
    }

    private static func wordInitials(for term: String) -> String {
        term.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .compactMap(\.first)
            .map { String($0) }
            .joined()
    }

    private static func fuzzySubsequenceScore(token: String, term: String) -> Int? {
        var searchStart = term.startIndex
        var previousMatchOffset: Int?
        var score = 0
        let tokenCharacters = Array(token)

        for character in tokenCharacters {
            guard let matchIndex = term[searchStart...].firstIndex(of: character) else {
                return nil
            }

            let offset = term.distance(from: term.startIndex, to: matchIndex)
            score += 18

            if let previousMatchOffset {
                let gap = offset - previousMatchOffset
                if gap == 1 {
                    score += 20
                } else {
                    score += max(0, 10 - gap)
                }
            }

            if offset == 0 {
                score += 12
            } else {
                let previousIndex = term.index(before: matchIndex)
                if !term[previousIndex].isLetter && !term[previousIndex].isNumber {
                    score += 12
                }
            }

            searchStart = term.index(after: matchIndex)
            previousMatchOffset = offset
        }

        score -= max(term.count - tokenCharacters.count, 0)
        return max(score, 1)
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func highlightRanges(for token: String, in value: String) -> [Range<String.Index>] {
        if let range = value.range(of: token, options: [.caseInsensitive, .diacriticInsensitive]) {
            return [range]
        }

        if let range = wordPrefixRange(for: token, in: value) {
            return [range]
        }

        if let ranges = fuzzyHighlightRanges(for: token, in: value) {
            return ranges
        }

        return []
    }

    private static func wordPrefixRange(for token: String, in value: String) -> Range<String.Index>? {
        let normalizedToken = normalize(token)
        guard !normalizedToken.isEmpty else {
            return nil
        }

        var match: Range<String.Index>?

        value.enumerateSubstrings(in: value.startIndex..<value.endIndex, options: .byWords) { substring, range, _, stop in
            guard let substring else {
                return
            }

            let normalizedSubstring = normalize(substring)
            guard normalizedSubstring.hasPrefix(normalizedToken) else {
                return
            }

            let tokenLength = min(normalizedToken.count, substring.count)
            let upperBound = value.index(range.lowerBound, offsetBy: tokenLength)
            match = range.lowerBound..<upperBound
            stop = true
        }

        return match
    }

    private static func fuzzyHighlightRanges(for token: String, in value: String) -> [Range<String.Index>]? {
        let normalizedToken = Array(normalize(token))
        let normalizedValue = Array(normalize(value))
        let rawIndices = Array(value.indices)

        guard !normalizedToken.isEmpty, normalizedValue.count == rawIndices.count else {
            return nil
        }

        var matchedOffsets: [Int] = []
        var searchOffset = 0

        for character in normalizedToken {
            var foundOffset: Int?
            while searchOffset < normalizedValue.count {
                if normalizedValue[searchOffset] == character {
                    foundOffset = searchOffset
                    searchOffset += 1
                    break
                }
                searchOffset += 1
            }

            guard let foundOffset else {
                return nil
            }

            matchedOffsets.append(foundOffset)
        }

        return groupedRanges(from: matchedOffsets, in: value, rawIndices: rawIndices)
    }

    private static func groupedRanges(
        from offsets: [Int],
        in value: String,
        rawIndices: [String.Index]
    ) -> [Range<String.Index>] {
        guard let firstOffset = offsets.first else {
            return []
        }

        var ranges: [Range<String.Index>] = []
        var groupStart = firstOffset
        var previousOffset = firstOffset

        for offset in offsets.dropFirst() {
            if offset == previousOffset + 1 {
                previousOffset = offset
                continue
            }

            ranges.append(range(for: groupStart...previousOffset, in: value, rawIndices: rawIndices))
            groupStart = offset
            previousOffset = offset
        }

        ranges.append(range(for: groupStart...previousOffset, in: value, rawIndices: rawIndices))
        return ranges
    }

    private static func range(
        for offsets: ClosedRange<Int>,
        in value: String,
        rawIndices: [String.Index]
    ) -> Range<String.Index> {
        let lowerBound = rawIndices[offsets.lowerBound]
        let upperBase = rawIndices[offsets.upperBound]
        let upperBound = value.index(after: upperBase)
        return lowerBound..<upperBound
    }

    private static func mergeRanges(_ ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        let sortedRanges = ranges.sorted { $0.lowerBound < $1.lowerBound }
        guard let firstRange = sortedRanges.first else {
            return []
        }

        var merged: [Range<String.Index>] = [firstRange]

        for range in sortedRanges.dropFirst() {
            if let last = merged.last, range.lowerBound <= last.upperBound {
                let combinedUpperBound = max(last.upperBound, range.upperBound)
                merged[merged.count - 1] = last.lowerBound..<combinedUpperBound
            } else {
                merged.append(range)
            }
        }

        return merged
    }
}

struct EditorCanvasCommand: Identifiable, Equatable {
    enum Action: Equatable {
        case bold
        case italic
        case inlineCode
        case link
        case replace(EditorCanvasReplacement)
    }

    let id = UUID()
    let action: Action
}

struct EditorCanvasView: View {
    @Binding var text: String

    let lineWidth: CGFloat
    let command: EditorCanvasCommand?
    let onDropImageFiles: ([URL]) -> Bool
    let onRequestImageImport: (NSRange) -> Void
    let onCommandHandled: (UUID) -> Void

    @StateObject private var slashUsageStore = SlashUsageStore()
    @State private var isImageDropTarget = false
    @State private var shouldFocusEditor = false
    @State private var slashContext: SlashCommandContext?
    @State private var selectedSlashCommandID: String?
    @State private var expandedSlashCommandID: String?
    @State private var selectedSlashTemplateID: String?
    @State private var pendingLocalCommand: EditorCanvasCommand?

    private var activeCommand: EditorCanvasCommand? {
        pendingLocalCommand ?? command
    }

    private var visibleSlashCommandIDs: [String] {
        visibleSlashCommands.map(\.id)
    }

    private var visibleSlashTemplateIDs: [String] {
        visibleSlashTemplates.map(\.id)
    }

    var body: some View {
        centeredEditor
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dropDestination(for: URL.self) { items, _ in
                onDropImageFiles(items)
            } isTargeted: { isTargeted in
                isImageDropTarget = isTargeted
            }
            .onAppear {
                DispatchQueue.main.async {
                    shouldFocusEditor = true
                }
            }
            .overlay(alignment: .topTrailing) {
                if isImageDropTarget {
                    Label("Drop image to import", systemImage: "photo")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.black.opacity(0.78))
                        )
                        .foregroundStyle(.white)
                        .padding(.top, 18)
                        .padding(.trailing, 24)
                }
            }
            .onChange(of: slashContext) { _, _ in
                syncSlashSelection()
            }
            .onChange(of: visibleSlashCommandIDs) { _, _ in
                syncSlashSelection()
            }
            .onChange(of: visibleSlashTemplateIDs) { _, _ in
                syncSlashSelection()
            }
    }

    private var centeredEditor: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 0)
            MarkdownWritingTextView(
                text: $text,
                isFocused: $shouldFocusEditor,
                command: activeCommand,
                onCommandHandled: handleCommandHandled,
                slashContext: $slashContext,
                visibleSlashCommands: visibleSlashCommands,
                visibleSlashTemplates: visibleSlashTemplates,
                selectedSlashCommandID: selectedSlashCommandID,
                selectedSlashTemplateID: selectedSlashTemplateID,
                expandedSlashCommand: expandedSlashCommand,
                onSelectSlashCommand: issueSlashCommand,
                onSelectSlashTemplate: issueSlashTemplate,
                onSelectSlashQuickIndex: selectSlashQuickIndex,
                onSubmitSlashSelection: submitSlashSelection,
                onExpandActiveSlashCommand: { expandSlashTemplates(for: activeSlashCommand) },
                onExpandSpecificSlashCommand: { expandSlashTemplates(for: $0) },
                onMoveSlashSelection: moveSlashSelection,
                onCollapseSlashTemplates: collapseSlashTemplates,
                onDismissSlashPalette: cancelSlashPalette
            )
                .frame(maxWidth: lineWidth, maxHeight: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 22)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
    }

    private var visibleSlashCommands: [EditorSlashCommand] {
        guard let slashContext else {
            return []
        }

        return Array(
            SlashPaletteSearch.rankCommands(
                EditorSlashCommand.all,
                query: slashContext.query,
                usageStore: slashUsageStore
            )
            .prefix(6)
        )
    }

    private var activeSlashCommand: EditorSlashCommand? {
        if let selectedSlashCommandID,
           let selectedCommand = visibleSlashCommands.first(where: { $0.id == selectedSlashCommandID }) {
            return selectedCommand
        }

        return visibleSlashCommands.first
    }

    private var expandedSlashCommand: EditorSlashCommand? {
        guard let expandedSlashCommandID else {
            return nil
        }

        return visibleSlashCommands.first(where: { $0.id == expandedSlashCommandID })
    }

    private var visibleSlashTemplates: [EditorSlashTemplate] {
        guard let expandedSlashCommand else {
            return []
        }

        return SlashPaletteSearch.rankTemplates(
            expandedSlashCommand.secondaryTemplates,
            query: slashContext?.query ?? "",
            usageStore: slashUsageStore
        )
    }

    private var activeSlashTemplate: EditorSlashTemplate? {
        if let selectedSlashTemplateID,
           let selectedTemplate = visibleSlashTemplates.first(where: { $0.id == selectedSlashTemplateID }) {
            return selectedTemplate
        }

        return visibleSlashTemplates.first
    }

    private func issueSlashCommand(_ slashCommand: EditorSlashCommand, context: SlashCommandContext) {
        slashUsageStore.record(commandID: slashCommand.id, templateID: slashCommand.primaryTemplate.id)
        applySlashTemplate(slashCommand.primaryTemplate, context: context)
    }

    private func issueSlashTemplate(_ template: EditorSlashTemplate, context: SlashCommandContext) {
        let parentCommandID = expandedSlashCommand?.id
            ?? visibleSlashCommands.first(where: {
                $0.primaryTemplate.id == template.id || $0.secondaryTemplates.contains(template)
            })?.id

        slashUsageStore.record(commandID: parentCommandID, templateID: template.id)
        applySlashTemplate(template, context: context)
    }

    private func applySlashTemplate(_ template: EditorSlashTemplate, context: SlashCommandContext) {
        switch template.action {
        case let .insert(content):
            let replacement = MarkdownEditorStyler.replacement(for: content, context: context)
            pendingLocalCommand = EditorCanvasCommand(action: .replace(replacement))
        case .requestImageImport:
            dismissSlashPalette()
            onRequestImageImport(context.replacementRange)
        }
    }

    private func selectSlashQuickIndex(_ index: Int) {
        guard let slashContext, index >= 0 else {
            return
        }

        if expandedSlashCommand != nil {
            guard index < visibleSlashTemplates.count else {
                return
            }

            issueSlashTemplate(visibleSlashTemplates[index], context: slashContext)
            return
        }

        guard index < visibleSlashCommands.count else {
            return
        }

        issueSlashCommand(visibleSlashCommands[index], context: slashContext)
    }

    private func moveSlashSelection(by delta: Int) {
        if expandedSlashCommand != nil {
            guard !visibleSlashTemplates.isEmpty else {
                selectedSlashTemplateID = nil
                return
            }

            let currentIndex = activeSlashTemplate.flatMap { template in
                visibleSlashTemplates.firstIndex(where: { $0.id == template.id })
            } ?? 0
            let targetIndex = min(max(currentIndex + delta, 0), visibleSlashTemplates.count - 1)
            selectedSlashTemplateID = visibleSlashTemplates[targetIndex].id
        } else {
            guard !visibleSlashCommands.isEmpty else {
                selectedSlashCommandID = nil
                return
            }

            let currentIndex = activeSlashCommand.flatMap { command in
                visibleSlashCommands.firstIndex(where: { $0.id == command.id })
            } ?? 0
            let targetIndex = min(max(currentIndex + delta, 0), visibleSlashCommands.count - 1)
            selectedSlashCommandID = visibleSlashCommands[targetIndex].id
        }
    }

    private func submitSlashSelection() {
        guard let slashContext else {
            return
        }

        if let activeSlashTemplate {
            issueSlashTemplate(activeSlashTemplate, context: slashContext)
            return
        }

        guard let activeSlashCommand else {
            return
        }

        issueSlashCommand(activeSlashCommand, context: slashContext)
    }

    private func expandSlashTemplates(for command: EditorSlashCommand?) {
        guard let command, command.canExpand else {
            return
        }

        selectedSlashCommandID = command.id
        expandedSlashCommandID = command.id
        selectedSlashTemplateID = command.secondaryTemplates.first?.id
    }

    private func collapseSlashTemplates() {
        expandedSlashCommandID = nil
        selectedSlashTemplateID = nil
    }

    private func cancelSlashPalette() {
        if expandedSlashCommand != nil {
            collapseSlashTemplates()
        } else {
            dismissSlashPalette()
        }
    }

    private func dismissSlashPalette() {
        slashContext = nil
        selectedSlashCommandID = nil
        expandedSlashCommandID = nil
        selectedSlashTemplateID = nil
    }

    private func syncSlashSelection() {
        guard slashContext != nil else {
            selectedSlashCommandID = nil
            expandedSlashCommandID = nil
            selectedSlashTemplateID = nil
            return
        }

        guard !visibleSlashCommands.isEmpty else {
            selectedSlashCommandID = nil
            expandedSlashCommandID = nil
            selectedSlashTemplateID = nil
            return
        }

        if let selectedSlashCommandID,
           visibleSlashCommands.contains(where: { $0.id == selectedSlashCommandID }) {
        } else {
            selectedSlashCommandID = visibleSlashCommands.first?.id
        }

        guard let expandedSlashCommand else {
            selectedSlashTemplateID = nil
            return
        }

        guard expandedSlashCommand.canExpand, !visibleSlashTemplates.isEmpty else {
            collapseSlashTemplates()
            return
        }

        if let selectedSlashTemplateID,
           visibleSlashTemplates.contains(where: { $0.id == selectedSlashTemplateID }) {
            return
        }

        selectedSlashTemplateID = visibleSlashTemplates.first?.id
    }

    private func handleCommandHandled(_ commandID: UUID) {
        if pendingLocalCommand?.id == commandID {
            pendingLocalCommand = nil
            return
        }

        onCommandHandled(commandID)
    }
}

private struct MarkdownWritingTextView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    let command: EditorCanvasCommand?
    let onCommandHandled: (UUID) -> Void
    @Binding var slashContext: SlashCommandContext?
    let visibleSlashCommands: [EditorSlashCommand]
    let visibleSlashTemplates: [EditorSlashTemplate]
    let selectedSlashCommandID: String?
    let selectedSlashTemplateID: String?
    let expandedSlashCommand: EditorSlashCommand?
    let onSelectSlashCommand: (EditorSlashCommand, SlashCommandContext) -> Void
    let onSelectSlashTemplate: (EditorSlashTemplate, SlashCommandContext) -> Void
    let onSelectSlashQuickIndex: (Int) -> Void
    let onSubmitSlashSelection: () -> Void
    let onExpandActiveSlashCommand: () -> Void
    let onExpandSpecificSlashCommand: (EditorSlashCommand) -> Void
    let onMoveSlashSelection: (Int) -> Void
    let onCollapseSlashTemplates: () -> Void
    let onDismissSlashPalette: () -> Void

    private var layoutProfile: WritingLayoutProfile {
        WritingLayoutProfile.current(for: text)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.58, green: 0.54, blue: 0.48).opacity(0.08),
                            Color.black.opacity(0.015)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .blur(radius: 24)
                .scaleEffect(x: 0.96, y: 1.02)
                .offset(y: 18)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.999, blue: 0.996),
                            Color(red: 0.993, green: 0.991, blue: 0.985),
                            layoutProfile.isBlank
                                ? Color(red: 0.986, green: 0.983, blue: 0.976)
                                : Color(red: 0.989, green: 0.986, blue: 0.978)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.75))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
                .shadow(color: Color.black.opacity(0.025), radius: 10, x: 0, y: 2)
                .shadow(color: Color(red: 0.3, green: 0.28, blue: 0.23).opacity(0.08), radius: 22, x: 0, y: 14)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color(red: 0.58, green: 0.54, blue: 0.48).opacity(0.16), lineWidth: 0.8)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 0.6)
                .padding(1.4)

            PlatformMarkdownTextView(
                text: $text,
                isFocused: $isFocused,
                layoutProfile: layoutProfile,
                command: command,
                onCommandHandled: onCommandHandled,
                slashContext: $slashContext,
                onMoveSlashSelection: onMoveSlashSelection,
                onSelectSlashQuickIndex: onSelectSlashQuickIndex,
                onSubmitSlashSelection: onSubmitSlashSelection,
                onExpandSlashTemplates: onExpandActiveSlashCommand,
                onCollapseSlashTemplates: onCollapseSlashTemplates,
                isShowingSlashTemplates: expandedSlashCommand != nil,
                onDismissSlashPalette: onDismissSlashPalette
            )
                .padding(.horizontal, 42)
                .padding(.vertical, layoutProfile.pageVerticalPadding)
        }
        .overlay(alignment: .topLeading) {
            if let slashContext {
                SlashCommandPaletteView(
                    commands: visibleSlashCommands,
                    templates: visibleSlashTemplates,
                    selectedCommandID: selectedSlashCommandID,
                    selectedTemplateID: selectedSlashTemplateID,
                    expandedCommand: expandedSlashCommand,
                    query: slashContext.query,
                    onSelectCommand: { command in
                        onSelectSlashCommand(command, slashContext)
                    },
                    onSelectTemplate: { template in
                        onSelectSlashTemplate(template, slashContext)
                    },
                    onExpandCommand: { command in
                        onExpandSpecificSlashCommand(command)
                    },
                    onCollapse: onCollapseSlashTemplates
                )
                .padding(.top, 26)
                .padding(.leading, 30)
            }
        }
        .overlay(alignment: .top) {
            pageEdgeFade(alignment: .top)
                .padding(.horizontal, 18)
                .padding(.top, 10)
        }
        .overlay(alignment: .bottom) {
            pageEdgeFade(alignment: .bottom)
                .padding(.horizontal, 18)
                .padding(.bottom, 10)
        }
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private func pageEdgeFade(alignment: VerticalAlignment) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: alignment == .top
                        ? [
                            Color(red: 0.995, green: 0.993, blue: 0.988),
                            Color(red: 0.995, green: 0.993, blue: 0.988).opacity(0)
                        ]
                        : [
                            Color(red: 0.995, green: 0.993, blue: 0.988).opacity(0),
                            Color(red: 0.991, green: 0.988, blue: 0.982)
                        ],
                    startPoint: alignment == .top ? .top : .top,
                    endPoint: alignment == .top ? .bottom : .bottom
                )
            )
            .frame(height: alignment == .top ? layoutProfile.topFadeHeight : layoutProfile.bottomFadeHeight)
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

private struct WritingLayoutProfile {
    let isBlank: Bool
    let topInset: CGFloat
    let bottomInset: CGFloat
    let scrollIndicatorTopInset: CGFloat
    let scrollIndicatorBottomInset: CGFloat
    let scrollViewTopInset: CGFloat
    let scrollViewBottomInset: CGFloat
    let comfortInset: CGFloat
    let focusHeightRatio: CGFloat
    let pageVerticalPadding: CGFloat
    let topFadeHeight: CGFloat
    let bottomFadeHeight: CGFloat

    static func current(for text: String) -> Self {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lineCount = max(text.components(separatedBy: "\n").count, 1)

        if trimmed.isEmpty {
            return .init(
                isBlank: true,
                topInset: 148,
                bottomInset: 224,
                scrollIndicatorTopInset: 44,
                scrollIndicatorBottomInset: 54,
                scrollViewTopInset: 18,
                scrollViewBottomInset: 92,
                comfortInset: 172,
                focusHeightRatio: 0.34,
                pageVerticalPadding: 28,
                topFadeHeight: 64,
                bottomFadeHeight: 88
            )
        }

        if trimmed.count < 220 && lineCount <= 5 {
            return .init(
                isBlank: false,
                topInset: 118,
                bottomInset: 194,
                scrollIndicatorTopInset: 36,
                scrollIndicatorBottomInset: 40,
                scrollViewTopInset: 12,
                scrollViewBottomInset: 82,
                comfortInset: 148,
                focusHeightRatio: 0.36,
                pageVerticalPadding: 22,
                topFadeHeight: 58,
                bottomFadeHeight: 80
            )
        }

        return .init(
            isBlank: false,
            topInset: 96,
            bottomInset: 164,
            scrollIndicatorTopInset: 30,
            scrollIndicatorBottomInset: 30,
            scrollViewTopInset: 8,
            scrollViewBottomInset: 72,
            comfortInset: 136,
            focusHeightRatio: 0.38,
            pageVerticalPadding: 18,
            topFadeHeight: 52,
            bottomFadeHeight: 72
        )
    }
}

private struct SlashCommandPaletteView: View {
    let commands: [EditorSlashCommand]
    let templates: [EditorSlashTemplate]
    let selectedCommandID: String?
    let selectedTemplateID: String?
    let expandedCommand: EditorSlashCommand?
    let query: String
    let onSelectCommand: (EditorSlashCommand) -> Void
    let onSelectTemplate: (EditorSlashTemplate) -> Void
    let onExpandCommand: (EditorSlashCommand) -> Void
    let onCollapse: () -> Void

    private let highlightColor = Color(red: 0.47, green: 0.33, blue: 0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: expandedCommand == nil ? "command" : "arrow.turn.down.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.53, green: 0.47, blue: 0.42))

                if let expandedCommand {
                    Button {
                        onCollapse()
                    } label: {
                        highlightedText(
                            expandedCommand.title,
                            query: query,
                            fontSize: 11.5,
                            baseWeight: .semibold,
                            emphasisWeight: .bold,
                            baseColor: Color(red: 0.34, green: 0.29, blue: 0.25),
                            emphasisColor: highlightColor
                        )
                    }
                    .buttonStyle(.plain)

                    Text("Templates")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text(query.isEmpty ? "Commands" : "/\(query)")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Color(red: 0.34, green: 0.29, blue: 0.25))
                }
            }

            if expandedCommand == nil {
                commandRows
            } else {
                templateRows
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 252, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            Color(red: 0.992, green: 0.989, blue: 0.982)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.58, green: 0.53, blue: 0.47).opacity(0.14), lineWidth: 0.8)
        }
        .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
        .shadow(color: Color(red: 0.36, green: 0.31, blue: 0.27).opacity(0.08), radius: 28, x: 0, y: 14)
    }

    @ViewBuilder
    private var commandRows: some View {
        if commands.isEmpty {
            Text("No matching commands")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(commands.enumerated()), id: \.element.id) { index, command in
                    HStack(spacing: 6) {
                        Button {
                            onSelectCommand(command)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: command.symbolName)
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .frame(width: 18)
                                    .foregroundStyle(Color(red: 0.52, green: 0.45, blue: 0.39))

                                VStack(alignment: .leading, spacing: 2) {
                                    highlightedText(
                                        command.title,
                                        query: query,
                                        fontSize: 12.5,
                                        baseWeight: .medium,
                                        emphasisWeight: .semibold,
                                        baseColor: Color(red: 0.16, green: 0.15, blue: 0.14),
                                        emphasisColor: highlightColor
                                    )
                                    highlightedText(
                                        command.detail,
                                        query: query,
                                        fontSize: 11,
                                        baseWeight: .medium,
                                        emphasisWeight: .semibold,
                                        baseColor: .secondary,
                                        emphasisColor: Color(red: 0.5, green: 0.38, blue: 0.25)
                                    )
                                }

                                Spacer(minLength: 0)

                                shortcutBadge(index: index)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(
                                        command.id == selectedCommandID
                                            ? Color(red: 0.94, green: 0.91, blue: 0.86)
                                            : Color.clear
                                    )
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if command.canExpand {
                            Button {
                                onExpandCommand(command)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.secondary.opacity(0.85))
                                    .frame(width: 22, height: 28)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var templateRows: some View {
        if templates.isEmpty {
            Text("No templates available")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                    Button {
                        onSelectTemplate(template)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: template.symbolName)
                                .font(.system(size: 12.5, weight: .semibold))
                                .frame(width: 18)
                                .foregroundStyle(Color(red: 0.52, green: 0.45, blue: 0.39))

                            VStack(alignment: .leading, spacing: 2) {
                                highlightedText(
                                    template.title,
                                    query: query,
                                    fontSize: 12.5,
                                    baseWeight: .medium,
                                    emphasisWeight: .semibold,
                                    baseColor: Color(red: 0.16, green: 0.15, blue: 0.14),
                                    emphasisColor: highlightColor
                                )
                                highlightedText(
                                    template.detail,
                                    query: query,
                                    fontSize: 11,
                                    baseWeight: .medium,
                                    emphasisWeight: .semibold,
                                    baseColor: .secondary,
                                    emphasisColor: Color(red: 0.5, green: 0.38, blue: 0.25)
                                )
                            }

                            Spacer(minLength: 0)

                            shortcutBadge(index: index)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    template.id == selectedTemplateID
                                        ? Color(red: 0.94, green: 0.91, blue: 0.86)
                                        : Color.clear
                                )
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func shortcutBadge(index: Int) -> some View {
        if index < 9 {
            Text("\(index + 1)")
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.44, green: 0.39, blue: 0.35))
                .frame(minWidth: 18, minHeight: 18)
                .padding(.horizontal, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.95, green: 0.93, blue: 0.89))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color(red: 0.6, green: 0.55, blue: 0.49).opacity(0.18), lineWidth: 0.7)
                }
        }
    }

    private func highlightedText(
        _ value: String,
        query: String,
        fontSize: CGFloat,
        baseWeight: Font.Weight,
        emphasisWeight: Font.Weight,
        baseColor: Color,
        emphasisColor: Color
    ) -> Text {
        let ranges = SlashPaletteSearch.highlightRanges(in: value, query: query)
        guard !ranges.isEmpty else {
            return Text(value)
                .font(.system(size: fontSize, weight: baseWeight))
                .foregroundStyle(baseColor)
        }

        var attributed = AttributedString(value)
        attributed.font = .system(size: fontSize, weight: baseWeight)
        attributed.foregroundColor = baseColor

        for range in ranges {
            guard let attributedRange = Range(range, in: attributed) else {
                continue
            }

            attributed[attributedRange].foregroundColor = emphasisColor
            attributed[attributedRange].font = .system(size: fontSize, weight: emphasisWeight)
        }

        return Text(attributed)
    }
}

#if canImport(UIKit)
private final class SlashAwareTextView: UITextView {
    var slashPaletteEnabled = false
    var isSlashTemplateExpanded = false
    var onSlashAction: ((SlashCommandKeyboardAction) -> Void)?

    override var keyCommands: [UIKeyCommand]? {
        guard slashPaletteEnabled else {
            return super.keyCommands
        }

        return [
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(handleSlashMoveUp)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(handleSlashMoveDown)),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleSlashExpand)),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleSlashCollapse)),
            UIKeyCommand(input: "\r", modifierFlags: .command, action: #selector(handleSlashExpand)),
            UIKeyCommand(input: "\t", modifierFlags: [], action: #selector(handleSlashSubmit)),
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(handleSlashDismiss))
        ] + (super.keyCommands ?? [])
    }

    @objc private func handleSlashMoveUp() {
        onSlashAction?(.moveSelection(-1))
    }

    @objc private func handleSlashMoveDown() {
        onSlashAction?(.moveSelection(1))
    }

    @objc private func handleSlashSubmit() {
        onSlashAction?(.submit)
    }

    @objc private func handleSlashExpand() {
        onSlashAction?(.expand)
    }

    @objc private func handleSlashCollapse() {
        onSlashAction?(.collapse)
    }

    @objc private func handleSlashDismiss() {
        onSlashAction?(.dismiss)
    }
}

private struct PlatformMarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let layoutProfile: WritingLayoutProfile
    let command: EditorCanvasCommand?
    let onCommandHandled: (UUID) -> Void
    @Binding var slashContext: SlashCommandContext?
    let onMoveSlashSelection: (Int) -> Void
    let onSelectSlashQuickIndex: (Int) -> Void
    let onSubmitSlashSelection: () -> Void
    let onExpandSlashTemplates: () -> Void
    let onCollapseSlashTemplates: () -> Void
    let isShowingSlashTemplates: Bool
    let onDismissSlashPalette: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            isFocused: $isFocused,
            slashContext: $slashContext,
            onMoveSlashSelection: onMoveSlashSelection,
            onSelectSlashQuickIndex: onSelectSlashQuickIndex,
            onSubmitSlashSelection: onSubmitSlashSelection,
            onExpandSlashTemplates: onExpandSlashTemplates,
            onCollapseSlashTemplates: onCollapseSlashTemplates,
            onDismissSlashPalette: onDismissSlashPalette
        )
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = SlashAwareTextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .sentences
        textView.spellCheckingType = .yes
        textView.smartQuotesType = .yes
        textView.smartDashesType = .yes
        textView.adjustsFontForContentSizeCategory = true
        textView.keyboardDismissMode = .interactive
        applyLayoutMetrics(to: textView, for: layoutProfile)
        textView.textContainer.lineFragmentPadding = 0
        textView.tintColor = MarkdownEditorStyler.accentColor
        textView.typingAttributes = MarkdownEditorStyler.baseTypingAttributes
        context.coordinator.applyStyledText(on: textView, value: text, force: true)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        applyLayoutMetrics(to: textView, for: layoutProfile)
        context.coordinator.applyStyledText(on: textView, value: text, force: textView.text != text)
        context.coordinator.applyCommandIfNeeded(command, on: textView, onCommandHandled: onCommandHandled)
        if let textView = textView as? SlashAwareTextView {
            textView.slashPaletteEnabled = slashContext != nil
            textView.isSlashTemplateExpanded = isShowingSlashTemplates
            textView.onSlashAction = { [weak textView, weak coordinator = context.coordinator] action in
                guard let textView, let coordinator else {
                    return
                }

                coordinator.handleSlashKeyboardAction(action, on: textView)
            }
        }

        if isFocused, !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
    }

    private func applyLayoutMetrics(to textView: UITextView, for layoutProfile: WritingLayoutProfile) {
        textView.textContainerInset = UIEdgeInsets(top: layoutProfile.topInset, left: 0, bottom: layoutProfile.bottomInset, right: 0)
        textView.scrollIndicatorInsets = UIEdgeInsets(
            top: layoutProfile.scrollIndicatorTopInset,
            left: 0,
            bottom: layoutProfile.scrollIndicatorBottomInset,
            right: 0
        )
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding private var text: String
        @Binding private var isFocused: Bool
        @Binding private var slashContext: SlashCommandContext?
        private let onMoveSlashSelection: (Int) -> Void
        private let onSelectSlashQuickIndex: (Int) -> Void
        private let onSubmitSlashSelection: () -> Void
        private let onExpandSlashTemplates: () -> Void
        private let onCollapseSlashTemplates: () -> Void
        private let onDismissSlashPalette: () -> Void
        private var isApplyingUpdate = false
        private var lastFocusedParagraphRange: NSRange?
        private var lastHandledCommandID: UUID?

        init(
            text: Binding<String>,
            isFocused: Binding<Bool>,
            slashContext: Binding<SlashCommandContext?>,
            onMoveSlashSelection: @escaping (Int) -> Void,
            onSelectSlashQuickIndex: @escaping (Int) -> Void,
            onSubmitSlashSelection: @escaping () -> Void,
            onExpandSlashTemplates: @escaping () -> Void,
            onCollapseSlashTemplates: @escaping () -> Void,
            onDismissSlashPalette: @escaping () -> Void
        ) {
            _text = text
            _isFocused = isFocused
            _slashContext = slashContext
            self.onMoveSlashSelection = onMoveSlashSelection
            self.onSelectSlashQuickIndex = onSelectSlashQuickIndex
            self.onSubmitSlashSelection = onSubmitSlashSelection
            self.onExpandSlashTemplates = onExpandSlashTemplates
            self.onCollapseSlashTemplates = onCollapseSlashTemplates
            self.onDismissSlashPalette = onDismissSlashPalette
        }

        func applyStyledText(on textView: UITextView, value: String, selectedRange overrideSelectedRange: NSRange? = nil, force: Bool) {
            guard force || textView.attributedText?.string != value else {
                return
            }

            let selectedRange = overrideSelectedRange ?? textView.selectedRange
            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: value, selectedRange: selectedRange)
            isApplyingUpdate = true
            textView.attributedText = MarkdownEditorStyler.attributedText(for: value, focusedRange: focusedParagraphRange)
            let clampedSelectedRange = NSRange(
                location: min(selectedRange.location, value.utf16.count),
                length: min(selectedRange.length, max(value.utf16.count - min(selectedRange.location, value.utf16.count), 0))
            )
            textView.selectedRange = clampedSelectedRange
            textView.typingAttributes = MarkdownEditorStyler.typingAttributes(for: value, selectedRange: clampedSelectedRange)
            keepSelectionComfortablyVisible(in: textView)
            isApplyingUpdate = false
            lastFocusedParagraphRange = focusedParagraphRange
            updateSlashContext(for: value, selectedRange: clampedSelectedRange)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText: String) -> Bool {
            guard !isApplyingUpdate else {
                return true
            }

            if replacementText == "\n", slashContext != nil {
                onSubmitSlashSelection()
                return false
            }

            if let shortcutIndex = SlashPaletteShortcut.index(for: replacementText), slashContext != nil {
                onSelectSlashQuickIndex(shortcutIndex)
                return false
            }

            if let mutation = MarkdownEditorStyler.typingMutation(for: replacementText, in: textView.text, selectedRange: range) {
                applyMutation(
                    on: textView,
                    replacementRange: mutation.replacementRange,
                    replacementText: mutation.replacementText,
                    selectedRange: mutation.selectedRange
                )
                return false
            }

            if replacementText == "\n",
               let continuation = MarkdownEditorStyler.enterContinuation(in: textView.text, selectedRange: range) {
                applyCustomEdit(on: textView, continuation: continuation)
                return false
            }

            if replacementText.isEmpty,
               let continuation = MarkdownEditorStyler.backspaceContinuation(in: textView.text, replacementRange: range) {
                applyCustomEdit(on: textView, continuation: continuation)
                return false
            }

            return true
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isApplyingUpdate else {
                return
            }

            text = textView.text
            applyStyledText(on: textView, value: textView.text, force: true)
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isFocused = true
            keepSelectionComfortablyVisible(in: textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isFocused = false
            slashContext = nil
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isApplyingUpdate else {
                return
            }

            textView.typingAttributes = MarkdownEditorStyler.typingAttributes(for: textView.text, selectedRange: textView.selectedRange)
            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: textView.text, selectedRange: textView.selectedRange)
            updateSlashContext(for: textView.text, selectedRange: textView.selectedRange)
            guard focusedParagraphRange != lastFocusedParagraphRange else {
                return
            }

            applyStyledText(on: textView, value: textView.text, force: true)
        }

        private func keepSelectionComfortablyVisible(in textView: UITextView) {
            guard let selectedTextRange = textView.selectedTextRange else {
                return
            }

            textView.layoutIfNeeded()
            let caretRect = textView.caretRect(for: selectedTextRange.end)
            guard caretRect.isNull == false else {
                return
            }

            let layoutProfile = WritingLayoutProfile.current(for: textView.text)
            let comfortInset = layoutProfile.comfortInset
            let visibleRect = textView.bounds.inset(by: UIEdgeInsets(top: comfortInset, left: 0, bottom: comfortInset, right: 0))
            let caretPoint = CGPoint(x: max(caretRect.midX, 1), y: caretRect.midY)
            guard visibleRect.contains(caretPoint) == false else {
                return
            }

            let minOffsetY = -textView.adjustedContentInset.top
            let maxOffsetY = max(textView.contentSize.height - textView.bounds.height + textView.adjustedContentInset.bottom, minOffsetY)
            let targetOffsetY = min(max(caretRect.midY - (textView.bounds.height * layoutProfile.focusHeightRatio), minOffsetY), maxOffsetY)
            textView.setContentOffset(CGPoint(x: textView.contentOffset.x, y: targetOffsetY), animated: false)
        }

        private func applyCustomEdit(on textView: UITextView, continuation: MarkdownEditorStyler.EnterContinuation) {
            let targetRange = NSRange(location: min(continuation.caretLocation, textView.text.utf16.count + continuation.replacementText.utf16.count), length: 0)
            applyMutation(
                on: textView,
                replacementRange: continuation.replacementRange,
                replacementText: continuation.replacementText,
                selectedRange: targetRange
            )
        }

        func applyCommandIfNeeded(_ command: EditorCanvasCommand?, on textView: UITextView, onCommandHandled: @escaping (UUID) -> Void) {
            guard let command, command.id != lastHandledCommandID else {
                return
            }

            lastHandledCommandID = command.id

            if let mutation = MarkdownEditorStyler.commandMutation(for: command.action, in: textView.text, selectedRange: textView.selectedRange) {
                applyMutation(
                    on: textView,
                    replacementRange: mutation.replacementRange,
                    replacementText: mutation.replacementText,
                    selectedRange: mutation.selectedRange
                )
            }

            DispatchQueue.main.async {
                onCommandHandled(command.id)
            }
        }

        private func applyMutation(on textView: UITextView, replacementRange: NSRange, replacementText: String, selectedRange: NSRange) {
            let updatedText = (textView.text as NSString).replacingCharacters(
                in: replacementRange,
                with: replacementText
            )
            let targetRange = NSRange(
                location: min(selectedRange.location, updatedText.utf16.count),
                length: min(selectedRange.length, max(updatedText.utf16.count - min(selectedRange.location, updatedText.utf16.count), 0))
            )
            text = updatedText
            applyStyledText(on: textView, value: updatedText, selectedRange: targetRange, force: true)
        }

        private func updateSlashContext(for text: String, selectedRange: NSRange) {
            slashContext = MarkdownEditorStyler.slashContext(in: text, selectedRange: selectedRange)
        }

        func handleSlashKeyboardAction(_ action: SlashCommandKeyboardAction, on textView: UITextView) {
            guard slashContext != nil else {
                return
            }

            switch action {
            case let .moveSelection(delta):
                onMoveSlashSelection(delta)
            case .expand:
                if let textView = textView as? SlashAwareTextView, textView.isSlashTemplateExpanded {
                    onSubmitSlashSelection()
                } else {
                    onExpandSlashTemplates()
                }
            case .collapse:
                onCollapseSlashTemplates()
            case .dismiss:
                if let textView = textView as? SlashAwareTextView, textView.isSlashTemplateExpanded {
                    onCollapseSlashTemplates()
                } else {
                    onDismissSlashPalette()
                }
            case .submit:
                onSubmitSlashSelection()
            }
        }
    }
}
#elseif canImport(AppKit)
private final class SlashAwareNSTextView: NSTextView {
    var slashPaletteEnabled = false
    var isSlashTemplateExpanded = false
    var onSlashAction: ((SlashCommandKeyboardAction) -> Void)?

    override func keyDown(with event: NSEvent) {
        guard slashPaletteEnabled else {
            super.keyDown(with: event)
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers.contains(.command), (event.keyCode == 36 || event.keyCode == 76) {
            onSlashAction?(.expand)
            return
        }

        super.keyDown(with: event)
    }

    override func doCommand(by selector: Selector) {
        guard slashPaletteEnabled else {
            super.doCommand(by: selector)
            return
        }

        switch selector {
        case #selector(moveUp(_:)):
            onSlashAction?(.moveSelection(-1))
        case #selector(moveDown(_:)):
            onSlashAction?(.moveSelection(1))
        case #selector(moveRight(_:)):
            onSlashAction?(.expand)
        case #selector(moveLeft(_:)):
            onSlashAction?(.collapse)
        case #selector(insertTab(_:)):
            onSlashAction?(.submit)
        case #selector(cancelOperation(_:)):
            onSlashAction?(.dismiss)
        default:
            super.doCommand(by: selector)
        }
    }
}

private struct PlatformMarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let layoutProfile: WritingLayoutProfile
    let command: EditorCanvasCommand?
    let onCommandHandled: (UUID) -> Void
    @Binding var slashContext: SlashCommandContext?
    let onMoveSlashSelection: (Int) -> Void
    let onSelectSlashQuickIndex: (Int) -> Void
    let onSubmitSlashSelection: () -> Void
    let onExpandSlashTemplates: () -> Void
    let onCollapseSlashTemplates: () -> Void
    let isShowingSlashTemplates: Bool
    let onDismissSlashPalette: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            isFocused: $isFocused,
            slashContext: $slashContext,
            onMoveSlashSelection: onMoveSlashSelection,
            onSelectSlashQuickIndex: onSelectSlashQuickIndex,
            onSubmitSlashSelection: onSubmitSlashSelection,
            onExpandSlashTemplates: onExpandSlashTemplates,
            onCollapseSlashTemplates: onCollapseSlashTemplates,
            onDismissSlashPalette: onDismissSlashPalette
        )
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay

        let textView = SlashAwareNSTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.textContainerInset = NSSize(width: 0, height: layoutProfile.topInset)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.insertionPointColor = MarkdownEditorStyler.cursorColor
        textView.usesFindPanel = true

        scrollView.documentView = textView
        applyLayoutMetrics(to: scrollView, textView: textView, for: layoutProfile)
        context.coordinator.applyStyledText(on: textView, value: text, force: true)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        applyLayoutMetrics(to: scrollView, textView: textView, for: layoutProfile)
        context.coordinator.applyStyledText(on: textView, value: text, force: textView.string != text)
        context.coordinator.applyCommandIfNeeded(command, on: textView, onCommandHandled: onCommandHandled)
        if let textView = textView as? SlashAwareNSTextView {
            textView.slashPaletteEnabled = slashContext != nil
            textView.isSlashTemplateExpanded = isShowingSlashTemplates
            textView.onSlashAction = { [weak textView, weak coordinator = context.coordinator] action in
                guard let textView, let coordinator else {
                    return
                }

                coordinator.handleSlashKeyboardAction(action, on: textView)
            }
        }

        if isFocused, textView.window?.firstResponder !== textView {
            textView.window?.makeFirstResponder(textView)
        }
    }

    private func applyLayoutMetrics(to scrollView: NSScrollView, textView: NSTextView, for layoutProfile: WritingLayoutProfile) {
        textView.textContainerInset = NSSize(width: 0, height: layoutProfile.topInset)
        scrollView.contentInsets = NSEdgeInsets(
            top: layoutProfile.scrollViewTopInset,
            left: 0,
            bottom: layoutProfile.scrollViewBottomInset,
            right: 0
        )
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String
        @Binding private var isFocused: Bool
        @Binding private var slashContext: SlashCommandContext?
        private let onMoveSlashSelection: (Int) -> Void
        private let onSelectSlashQuickIndex: (Int) -> Void
        private let onSubmitSlashSelection: () -> Void
        private let onExpandSlashTemplates: () -> Void
        private let onCollapseSlashTemplates: () -> Void
        private let onDismissSlashPalette: () -> Void
        private var isApplyingUpdate = false
        private var lastFocusedParagraphRange: NSRange?
        private var lastHandledCommandID: UUID?

        init(
            text: Binding<String>,
            isFocused: Binding<Bool>,
            slashContext: Binding<SlashCommandContext?>,
            onMoveSlashSelection: @escaping (Int) -> Void,
            onSelectSlashQuickIndex: @escaping (Int) -> Void,
            onSubmitSlashSelection: @escaping () -> Void,
            onExpandSlashTemplates: @escaping () -> Void,
            onCollapseSlashTemplates: @escaping () -> Void,
            onDismissSlashPalette: @escaping () -> Void
        ) {
            _text = text
            _isFocused = isFocused
            _slashContext = slashContext
            self.onMoveSlashSelection = onMoveSlashSelection
            self.onSelectSlashQuickIndex = onSelectSlashQuickIndex
            self.onSubmitSlashSelection = onSubmitSlashSelection
            self.onExpandSlashTemplates = onExpandSlashTemplates
            self.onCollapseSlashTemplates = onCollapseSlashTemplates
            self.onDismissSlashPalette = onDismissSlashPalette
        }

        func applyStyledText(on textView: NSTextView, value: String, selectedRange overrideSelectedRange: NSRange? = nil, force: Bool) {
            guard force || textView.string != value else {
                return
            }

            let targetRange = overrideSelectedRange ?? textView.selectedRange()
            let selectedRanges = overrideSelectedRange.map { [NSValue(range: $0)] } ?? textView.selectedRanges
            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: value, selectedRange: targetRange)
            isApplyingUpdate = true
            textView.textStorage?.setAttributedString(MarkdownEditorStyler.attributedText(for: value, focusedRange: focusedParagraphRange))
            textView.setSelectedRanges(selectedRanges, affinity: .downstream, stillSelecting: false)
            textView.typingAttributes = MarkdownEditorStyler.typingAttributes(for: value, selectedRange: textView.selectedRange())
            keepSelectionComfortablyVisible(in: textView)
            isApplyingUpdate = false
            lastFocusedParagraphRange = focusedParagraphRange
            updateSlashContext(for: value, selectedRange: textView.selectedRange())
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard !isApplyingUpdate else {
                return true
            }

            if replacementString == "\n", slashContext != nil {
                onSubmitSlashSelection()
                return false
            }

            if let shortcutIndex = SlashPaletteShortcut.index(for: replacementString), slashContext != nil {
                onSelectSlashQuickIndex(shortcutIndex)
                return false
            }

            if let replacementString,
               let mutation = MarkdownEditorStyler.typingMutation(for: replacementString, in: textView.string, selectedRange: affectedCharRange) {
                applyMutation(
                    on: textView,
                    replacementRange: mutation.replacementRange,
                    replacementText: mutation.replacementText,
                    selectedRange: mutation.selectedRange
                )
                return false
            }

            if replacementString == "\n",
               let continuation = MarkdownEditorStyler.enterContinuation(in: textView.string, selectedRange: affectedCharRange) {
                applyCustomEdit(on: textView, continuation: continuation)
                return false
            }

            if replacementString?.isEmpty != false,
               let continuation = MarkdownEditorStyler.backspaceContinuation(in: textView.string, replacementRange: affectedCharRange) {
                applyCustomEdit(on: textView, continuation: continuation)
                return false
            }

            return true
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingUpdate,
                  let textView = notification.object as? NSTextView else {
                return
            }

            text = textView.string
            applyStyledText(on: textView, value: textView.string, force: true)
        }

        func textDidBeginEditing(_ notification: Notification) {
            isFocused = true

            guard let textView = notification.object as? NSTextView else {
                return
            }

            keepSelectionComfortablyVisible(in: textView)
        }

        func textDidEndEditing(_ notification: Notification) {
            isFocused = false
            slashContext = nil
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isApplyingUpdate,
                  let textView = notification.object as? NSTextView else {
                return
            }

            textView.typingAttributes = MarkdownEditorStyler.typingAttributes(for: textView.string, selectedRange: textView.selectedRange())
            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: textView.string, selectedRange: textView.selectedRange())
            updateSlashContext(for: textView.string, selectedRange: textView.selectedRange())
            guard focusedParagraphRange != lastFocusedParagraphRange else {
                return
            }

            applyStyledText(on: textView, value: textView.string, force: true)
        }

        private func keepSelectionComfortablyVisible(in textView: NSTextView) {
            guard let scrollView = textView.enclosingScrollView,
                  let textContainer = textView.textContainer,
                  let layoutManager = textView.layoutManager else {
                return
            }

            layoutManager.ensureLayout(for: textContainer)

            let selectedRange = textView.selectedRange()
            let stringLength = (textView.string as NSString).length
            let anchorLocation = min(max(selectedRange.location, 0), max(stringLength - 1, 0))
            let anchorLength = min(max(selectedRange.length, 1), max(stringLength - anchorLocation, 1))
            let anchorRange = stringLength == 0
                ? NSRange(location: 0, length: 0)
                : NSRange(location: anchorLocation, length: anchorLength)

            var glyphRange = layoutManager.glyphRange(forCharacterRange: anchorRange, actualCharacterRange: nil)
            if glyphRange.length == 0, layoutManager.numberOfGlyphs > 0 {
                glyphRange = NSRange(location: min(glyphRange.location, layoutManager.numberOfGlyphs - 1), length: 1)
            }

            let caretRect: NSRect
            if glyphRange.length > 0 {
                var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                rect.origin.y += textView.textContainerInset.height
                caretRect = rect
            } else {
                caretRect = NSRect(x: 0, y: textView.textContainerInset.height, width: 1, height: MarkdownEditorStyler.bodyLineHeight)
            }

            let layoutProfile = WritingLayoutProfile.current(for: textView.string)
            let comfortInset = layoutProfile.comfortInset
            let visibleRect = scrollView.contentView.bounds.insetBy(dx: 0, dy: comfortInset)
            let caretPoint = NSPoint(x: max(caretRect.midX, 1), y: caretRect.midY)
            guard visibleRect.contains(caretPoint) == false else {
                return
            }

            let minOffsetY = -scrollView.contentInsets.top
            let maxOffsetY = max(textView.bounds.height - scrollView.contentView.bounds.height + scrollView.contentInsets.bottom, minOffsetY)
            let targetOffsetY = min(max(caretRect.midY - (scrollView.contentView.bounds.height * layoutProfile.focusHeightRatio), minOffsetY), maxOffsetY)
            scrollView.contentView.setBoundsOrigin(NSPoint(x: 0, y: targetOffsetY))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }

        private func applyCustomEdit(on textView: NSTextView, continuation: MarkdownEditorStyler.EnterContinuation) {
            let targetRange = NSRange(location: min(continuation.caretLocation, textView.string.utf16.count + continuation.replacementText.utf16.count), length: 0)
            applyMutation(
                on: textView,
                replacementRange: continuation.replacementRange,
                replacementText: continuation.replacementText,
                selectedRange: targetRange
            )
        }

        func applyCommandIfNeeded(_ command: EditorCanvasCommand?, on textView: NSTextView, onCommandHandled: @escaping (UUID) -> Void) {
            guard let command, command.id != lastHandledCommandID else {
                return
            }

            lastHandledCommandID = command.id

            if let mutation = MarkdownEditorStyler.commandMutation(for: command.action, in: textView.string, selectedRange: textView.selectedRange()) {
                applyMutation(
                    on: textView,
                    replacementRange: mutation.replacementRange,
                    replacementText: mutation.replacementText,
                    selectedRange: mutation.selectedRange
                )
            }

            DispatchQueue.main.async {
                onCommandHandled(command.id)
            }
        }

        private func applyMutation(on textView: NSTextView, replacementRange: NSRange, replacementText: String, selectedRange: NSRange) {
            let updatedText = (textView.string as NSString).replacingCharacters(
                in: replacementRange,
                with: replacementText
            )
            let targetRange = MarkdownEditorStyler.clamped(selectedRange, maxLength: updatedText.utf16.count)
            text = updatedText
            applyStyledText(on: textView, value: updatedText, selectedRange: targetRange, force: true)
        }

        private func updateSlashContext(for text: String, selectedRange: NSRange) {
            slashContext = MarkdownEditorStyler.slashContext(in: text, selectedRange: selectedRange)
        }

        func handleSlashKeyboardAction(_ action: SlashCommandKeyboardAction, on textView: NSTextView) {
            guard slashContext != nil else {
                return
            }

            switch action {
            case let .moveSelection(delta):
                onMoveSlashSelection(delta)
            case .expand:
                if let textView = textView as? SlashAwareNSTextView, textView.isSlashTemplateExpanded {
                    onSubmitSlashSelection()
                } else {
                    onExpandSlashTemplates()
                }
            case .collapse:
                onCollapseSlashTemplates()
            case .dismiss:
                if let textView = textView as? SlashAwareNSTextView, textView.isSlashTemplateExpanded {
                    onCollapseSlashTemplates()
                } else {
                    onDismissSlashPalette()
                }
            case .submit:
                onSubmitSlashSelection()
            }
        }
    }
}
#endif

private enum MarkdownEditorStyler {
    struct EnterContinuation {
        let replacementRange: NSRange
        let replacementText: String
        let caretLocation: Int
    }

    struct CommandMutation {
        let replacementRange: NSRange
        let replacementText: String
        let selectedRange: NSRange
    }

    private struct ActiveLineContext {
        enum Kind {
            case body
            case frontmatterFence(isOpening: Bool)
            case frontmatterField(separatorOffset: Int?)
            case codeFence(leadingWhitespace: Int, markerLength: Int, isOpening: Bool)
            case codeBlock
            case heading(level: Int, markerCount: Int, leadingWhitespace: Int)
            case quote(leadingWhitespace: Int)
            case unorderedList(markerLength: Int, leadingWhitespace: Int)
            case orderedList(markerLength: Int, leadingWhitespace: Int)
        }

        let kind: Kind
        let lineRange: NSRange
        let isLeadingBlock: Bool
    }

    static var baseTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle(lineSpacing: 11, paragraphSpacing: 18)
        ]
    }

    static var cursorColor: PlatformColor {
        textColor
    }

    static var bodyLineHeight: CGFloat {
        bodyFont.pointSize + 11
    }

    static func typingAttributes(for text: String, selectedRange: NSRange) -> [NSAttributedString.Key: Any] {
        let lineContext = activeLineContext(in: text, selectedRange: selectedRange)

        switch lineContext.kind {
        case .frontmatterFence:
            return frontmatterFenceTypingAttributes
        case let .frontmatterField(separatorOffset):
            let cursorOffset = max(selectedRange.location - lineContext.lineRange.location, 0)
            if let separatorOffset, cursorOffset <= separatorOffset {
                return frontmatterKeyTypingAttributes
            }
            return frontmatterValueTypingAttributes
        case let .codeFence(leadingWhitespace, markerLength, _):
            let cursorOffset = max(selectedRange.location - lineContext.lineRange.location, 0)
            if cursorOffset <= leadingWhitespace + markerLength {
                return codeFenceMarkerTypingAttributes
            }
            return codeFenceLanguageTypingAttributes
        case .codeBlock:
            return codeLineTypingAttributes
        case let .heading(level, markerCount, leadingWhitespace):
            let cursorOffset = max(selectedRange.location - lineContext.lineRange.location, 0)
            if cursorOffset <= leadingWhitespace + markerCount {
                return [
                    .font: monoFont(size: headingMarkerSize(level: level, isDisplayHeading: shouldUseDisplayHeading(level: level, isLeadingBlock: lineContext.isLeadingBlock))),
                    .foregroundColor: headingMarkerColor(isFocused: true, isDisplayHeading: shouldUseDisplayHeading(level: level, isLeadingBlock: lineContext.isLeadingBlock)),
                    .paragraphStyle: headingParagraphStyle(level: level, isLeadingBlock: lineContext.isLeadingBlock)
                ]
            }
            return headingTypingAttributes(level: level, isLeadingBlock: lineContext.isLeadingBlock)
        case let .quote(leadingWhitespace):
            let cursorOffset = max(selectedRange.location - lineContext.lineRange.location, 0)
            if cursorOffset <= leadingWhitespace + 1 {
                return quoteMarkerTypingAttributes
            }
            return quoteTypingAttributes
        case let .unorderedList(markerLength, leadingWhitespace),
             let .orderedList(markerLength, leadingWhitespace):
            let cursorOffset = max(selectedRange.location - lineContext.lineRange.location, 0)
            if cursorOffset <= leadingWhitespace + markerLength {
                return listMarkerTypingAttributes(markerLength: markerLength, leadingWhitespace: leadingWhitespace)
            }
            return listTypingAttributes(markerLength: markerLength, leadingWhitespace: leadingWhitespace)
        case .body:
            return baseTypingAttributes
        }
    }

    static func enterContinuation(in text: String, selectedRange: NSRange) -> EnterContinuation? {
        guard selectedRange.length == 0 else {
            return nil
        }

        let lineContext = activeLineContext(in: text, selectedRange: selectedRange)
        let cursorLocation = selectedRange.location
        let lineText = lineSubstring(in: text, range: lineContext.lineRange)
        let lineEnd = lineContext.lineRange.location + lineContext.lineRange.length

        switch lineContext.kind {
        case let .quote(leadingWhitespace):
            guard let info = quoteContinuationInfo(in: lineText, leadingWhitespace: leadingWhitespace) else {
                return nil
            }
            if info.isEmpty {
                return .init(replacementRange: lineContext.lineRange, replacementText: "", caretLocation: lineContext.lineRange.location)
            }
            return .init(
                replacementRange: selectedRange,
                replacementText: "\n\(info.prefix)",
                caretLocation: cursorLocation + 1 + info.prefix.utf16.count
            )
        case .unorderedList:
            guard let info = unorderedListContinuationInfo(in: lineText) else {
                return nil
            }
            if info.isEmpty {
                return .init(replacementRange: lineContext.lineRange, replacementText: "", caretLocation: lineContext.lineRange.location)
            }
            return .init(
                replacementRange: selectedRange,
                replacementText: "\n\(info.prefix)",
                caretLocation: cursorLocation + 1 + info.prefix.utf16.count
            )
        case .orderedList:
            guard let info = orderedListContinuationInfo(in: lineText) else {
                return nil
            }
            if info.isEmpty {
                return .init(replacementRange: lineContext.lineRange, replacementText: "", caretLocation: lineContext.lineRange.location)
            }
            return .init(
                replacementRange: selectedRange,
                replacementText: "\n\(info.prefix)",
                caretLocation: cursorLocation + 1 + info.prefix.utf16.count
            )
        case let .codeFence(_, _, isOpening):
            guard isOpening,
                  cursorLocation == lineEnd,
                  hasClosingCodeFence(after: lineEnd, in: text) == false,
                  let closingFence = closingCodeFenceLine(for: lineText) else {
                return nil
            }
            return .init(
                replacementRange: selectedRange,
                replacementText: "\n\n\(closingFence)",
                caretLocation: cursorLocation + 1
            )
        case let .frontmatterFence(isOpening):
            guard isOpening,
                  cursorLocation == lineEnd,
                  hasClosingFrontmatterFence(after: lineEnd, in: text) == false else {
                return nil
            }
            return .init(
                replacementRange: selectedRange,
                replacementText: "\n\n---",
                caretLocation: cursorLocation + 1
            )
        default:
            return nil
        }
    }

    static func backspaceContinuation(in text: String, replacementRange: NSRange) -> EnterContinuation? {
        guard replacementRange.length == 1 else {
            return nil
        }

        if let inlineContinuation = inlineBackspaceContinuation(in: text, replacementRange: replacementRange) {
            return inlineContinuation
        }

        let caretLocation = replacementRange.location + replacementRange.length
        let lineContext = activeLineContext(in: text, selectedRange: NSRange(location: caretLocation, length: 0))
        let lineText = lineSubstring(in: text, range: lineContext.lineRange)
        let lineEnd = lineContext.lineRange.location + lineContext.lineRange.length

        switch lineContext.kind {
        case let .heading(_, markerCount, leadingWhitespace):
            guard caretLocation == lineEnd,
                  headingContentIsEmpty(in: lineText, markerCount: markerCount) else {
                return nil
            }
            return exitBlockContinuation(lineRange: lineContext.lineRange, leadingWhitespace: leadingWhitespace)
        case let .quote(leadingWhitespace):
            guard caretLocation == lineEnd,
                  let info = quoteContinuationInfo(in: lineText, leadingWhitespace: leadingWhitespace),
                  info.isEmpty else {
                return nil
            }
            return exitBlockContinuation(lineRange: lineContext.lineRange, leadingWhitespace: leadingWhitespace)
        case let .unorderedList(_, leadingWhitespace):
            guard caretLocation == lineEnd,
                  let info = unorderedListContinuationInfo(in: lineText),
                  info.isEmpty else {
                return nil
            }
            return exitBlockContinuation(lineRange: lineContext.lineRange, leadingWhitespace: leadingWhitespace)
        case let .orderedList(_, leadingWhitespace):
            guard caretLocation == lineEnd,
                  let info = orderedListContinuationInfo(in: lineText),
                  info.isEmpty else {
                return nil
            }
            return exitBlockContinuation(lineRange: lineContext.lineRange, leadingWhitespace: leadingWhitespace)
        case .codeBlock:
            guard lineText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  caretLocation == lineContext.lineRange.location,
                  let continuation = emptyCodeBlockContinuation(in: text, currentLineRange: lineContext.lineRange) else {
                return nil
            }
            return continuation
        default:
            return nil
        }
    }

    static func commandMutation(for action: EditorCanvasCommand.Action, in text: String, selectedRange: NSRange) -> CommandMutation? {
        let nsText = text as NSString
        let clampedRange = clamped(selectedRange, maxLength: nsText.length)

        switch action {
        case let .replace(replacement):
            return .init(
                replacementRange: clamped(replacement.replacementRange, maxLength: nsText.length),
                replacementText: replacement.replacementText,
                selectedRange: replacement.selectedRange
            )
        case .bold:
            return inlineWrapMutation(in: nsText, selectedRange: clampedRange, wrapper: "**")
        case .italic:
            return inlineWrapMutation(in: nsText, selectedRange: clampedRange, wrapper: "*")
        case .inlineCode:
            return inlineWrapMutation(in: nsText, selectedRange: clampedRange, wrapper: "`")
        case .link:
            return linkMutation(in: nsText, selectedRange: clampedRange)
        }
    }

    static func typingMutation(for replacementText: String, in text: String, selectedRange: NSRange) -> CommandMutation? {
        let nsText = text as NSString
        let clampedRange = clamped(selectedRange, maxLength: nsText.length)

        if let mutation = selectionWrapMutation(for: replacementText, in: nsText, selectedRange: clampedRange) {
            return mutation
        }

        if let mutation = autoPairMutation(for: replacementText, in: nsText, selectedRange: clampedRange) {
            return mutation
        }

        if let mutation = pasteMutation(for: replacementText, selectedRange: clampedRange) {
            return mutation
        }

        return nil
    }

    static func slashContext(in text: String, selectedRange: NSRange) -> SlashCommandContext? {
        guard selectedRange.length == 0 else {
            return nil
        }

        let lineContext = activeLineContext(in: text, selectedRange: selectedRange)
        let line = lineSubstring(in: text, range: lineContext.lineRange)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let leadingWhitespace = leadingWhitespaceCount(in: line)
        let cursorLocation = selectedRange.location
        let lineEnd = lineContext.lineRange.location + lineContext.lineRange.length

        guard trimmed.hasPrefix("/"),
              cursorLocation == lineEnd else {
            return nil
        }

        let query = String(trimmed.dropFirst())
        guard query.contains(where: \.isWhitespace) == false else {
            return nil
        }

        return .init(
            query: query,
            replacementRange: lineContext.lineRange,
            leadingWhitespace: leadingWhitespace
        )
    }

    static func replacement(for content: String, context: SlashCommandContext) -> EditorCanvasReplacement {
        let indentation = String(repeating: " ", count: context.leadingWhitespace)
        let indentedLines = content
            .components(separatedBy: "\n")
            .map { indentation + $0 }
        let replacementText = indentedLines.joined(separator: "\n")
        let replacementLength = (replacementText as NSString).length

        return .init(
            replacementRange: context.replacementRange,
            replacementText: replacementText,
            selectedRange: NSRange(location: context.replacementRange.location + replacementLength, length: 0)
        )
    }

    static func attributedText(for text: String, focusedRange: NSRange? = nil) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attributed.length)
        attributed.addAttributes(
            [
                .font: bodyFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle(lineSpacing: 11, paragraphSpacing: 18)
            ],
            range: fullRange
        )

        let lines = text.components(separatedBy: "\n")
        var location = 0
        var inFrontmatter = false
        var inCodeBlock = false
        var hasEncounteredMeaningfulBlock = false

        for (index, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: location, length: lineLength)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isLeadingBlock = trimmed.isEmpty == false && !hasEncounteredMeaningfulBlock
            let isFocusedLine = focusedRange.map { NSIntersectionRange($0, lineRange).length > 0 } ?? false

            if index == 0, trimmed == "---" {
                inFrontmatter = true
                styleFrontmatterFence(in: attributed, lineRange: lineRange)
                location += lineLength + 1
                continue
            }

            if inFrontmatter {
                styleFrontmatterLine(in: attributed, line: line, lineRange: lineRange)
                if trimmed == "---" {
                    styleFrontmatterFence(in: attributed, lineRange: lineRange)
                    inFrontmatter = false
                }
                location += lineLength + 1
                continue
            }

            if trimmed.hasPrefix("```") {
                styleCodeFence(in: attributed, line: line, lineRange: lineRange)
                inCodeBlock.toggle()
                if trimmed.isEmpty == false {
                    hasEncounteredMeaningfulBlock = true
                }
                location += lineLength + 1
                continue
            }

            if inCodeBlock {
                styleCodeLine(in: attributed, lineRange: lineRange)
                if trimmed.isEmpty == false {
                    hasEncounteredMeaningfulBlock = true
                }
                location += lineLength + 1
                continue
            }

            if styleHeadingIfNeeded(
                in: attributed,
                line: line,
                lineRange: lineRange,
                isLeadingBlock: isLeadingBlock,
                isFocusedLine: isFocusedLine
            ) {
                applyInlineStyles(in: attributed, line: line, lineRange: lineRange)
                hasEncounteredMeaningfulBlock = true
                location += lineLength + 1
                continue
            }

            if styleQuoteIfNeeded(in: attributed, line: line, lineRange: lineRange) {
                applyInlineStyles(in: attributed, line: line, lineRange: lineRange)
                if trimmed.isEmpty == false {
                    hasEncounteredMeaningfulBlock = true
                }
                location += lineLength + 1
                continue
            }

            if styleListIfNeeded(in: attributed, line: line, lineRange: lineRange) {
                applyInlineStyles(in: attributed, line: line, lineRange: lineRange)
                if trimmed.isEmpty == false {
                    hasEncounteredMeaningfulBlock = true
                }
                location += lineLength + 1
                continue
            }

            if styleDividerIfNeeded(in: attributed, trimmedLine: trimmed, lineRange: lineRange) {
                hasEncounteredMeaningfulBlock = true
                location += lineLength + 1
                continue
            }

            if styleTableIfNeeded(in: attributed, line: line, lineRange: lineRange) {
                hasEncounteredMeaningfulBlock = true
                location += lineLength + 1
                continue
            }

            if styleImageIfNeeded(in: attributed, line: line, lineRange: lineRange) {
                hasEncounteredMeaningfulBlock = true
                location += lineLength + 1
                continue
            }

            attributed.addAttributes(
                [
                    .font: bodyFont,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraphStyle(lineSpacing: 11, paragraphSpacing: 18)
                ],
                range: lineRange
            )
            applyInlineStyles(in: attributed, line: line, lineRange: lineRange)
            if trimmed.isEmpty == false {
                hasEncounteredMeaningfulBlock = true
            }
            location += lineLength + 1
        }

        applyParagraphFocus(in: attributed, text: text, focusedRange: focusedRange)
        return attributed
    }

    static func focusedParagraphRange(in text: String, selectedRange: NSRange) -> NSRange? {
        let nsText = text as NSString
        guard nsText.length > 0 else {
            return nil
        }

        let clampedLocation = min(max(selectedRange.location, 0), max(nsText.length - 1, 0))
        let clampedLength = min(max(selectedRange.length, 0), nsText.length - clampedLocation)
        return nsText.paragraphRange(for: NSRange(location: clampedLocation, length: clampedLength))
    }

    private static func styleFrontmatterFence(in attributed: NSMutableAttributedString, lineRange: NSRange) {
        attributed.addAttributes(
            frontmatterFenceTypingAttributes,
            range: lineRange
        )
    }

    private static func styleFrontmatterLine(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) {
        attributed.addAttributes(
            frontmatterValueTypingAttributes,
            range: lineRange
        )

        guard let separatorOffset = frontmatterSeparatorOffset(in: line) else {
            return
        }

        attributed.addAttributes(
            frontmatterKeyTypingAttributes,
            range: NSRange(location: lineRange.location, length: separatorOffset)
        )
    }

    private static func styleCodeFence(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) {
        attributed.addAttributes(
            codeFenceLanguageTypingAttributes,
            range: lineRange
        )

        if let fenceRange = codeFenceRange(in: line, lineRange: lineRange) {
            attributed.addAttributes(
                codeFenceMarkerTypingAttributes,
                range: fenceRange
            )
        }
    }

    private static func styleCodeLine(in attributed: NSMutableAttributedString, lineRange: NSRange) {
        attributed.addAttributes(
            codeLineTypingAttributes,
            range: lineRange
        )
    }

    private static func styleHeadingIfNeeded(
        in attributed: NSMutableAttributedString,
        line: String,
        lineRange: NSRange,
        isLeadingBlock: Bool,
        isFocusedLine: Bool
    ) -> Bool {
        guard let markerCount = headingLevel(in: line) else {
            return false
        }

        let leadingWhitespace = leadingWhitespaceCount(in: line)
        let markerRange = NSRange(location: lineRange.location + leadingWhitespace, length: markerCount)
        let spacerRange = NSRange(location: markerRange.location + markerCount, length: 1)
        let titleLength = max(lineRange.length - leadingWhitespace - markerCount - 1, 0)
        let titleRange = NSRange(location: spacerRange.location + 1, length: titleLength)
        let headingAttributes = headingTypingAttributes(level: markerCount, isLeadingBlock: isLeadingBlock)
        let isDisplayHeading = shouldUseDisplayHeading(level: markerCount, isLeadingBlock: isLeadingBlock)

        attributed.addAttributes(
            headingAttributes,
            range: lineRange
        )
        attributed.addAttributes(
            [
                .font: monoFont(size: headingMarkerSize(level: markerCount, isDisplayHeading: isDisplayHeading)),
                .foregroundColor: headingMarkerColor(isFocused: isFocusedLine, isDisplayHeading: isDisplayHeading)
            ],
            range: markerRange
        )
        attributed.addAttributes(
            [
                .foregroundColor: headingMarkerColor(isFocused: isFocusedLine, isDisplayHeading: isDisplayHeading)
            ],
            range: spacerRange
        )
        if titleRange.length > 0 {
            attributed.addAttributes(headingAttributes, range: titleRange)
        }
        return true
    }

    private static func styleQuoteIfNeeded(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) -> Bool {
        guard let markerLength = quoteMarkerLength(in: line) else {
            return false
        }

        let leadingWhitespace = leadingWhitespaceCount(in: line)
        let markerRange = NSRange(location: lineRange.location + leadingWhitespace, length: markerLength)

        attributed.addAttributes(
            quoteTypingAttributes,
            range: lineRange
        )
        attributed.addAttributes(
            quoteMarkerTypingAttributes,
            range: markerRange
        )
        return true
    }

    private static func styleListIfNeeded(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) -> Bool {
        if let info = unorderedListMarker(in: line) {
            attributed.addAttributes(
                listTypingAttributes(markerLength: info.markerLength, leadingWhitespace: info.leadingWhitespace),
                range: lineRange
            )
            attributed.addAttributes(
                listMarkerTypingAttributes(markerLength: info.markerLength, leadingWhitespace: info.leadingWhitespace),
                range: NSRange(location: lineRange.location + info.leadingWhitespace, length: info.markerLength)
            )
            return true
        }

        guard let info = orderedListMarker(in: line) else {
            return false
        }

        attributed.addAttributes(
            listTypingAttributes(markerLength: info.markerLength, leadingWhitespace: info.leadingWhitespace),
            range: lineRange
        )
        attributed.addAttributes(
            listMarkerTypingAttributes(markerLength: info.markerLength, leadingWhitespace: info.leadingWhitespace),
            range: NSRange(location: lineRange.location + info.leadingWhitespace, length: info.markerLength)
        )
        return true
    }

    private static func styleDividerIfNeeded(in attributed: NSMutableAttributedString, trimmedLine: String, lineRange: NSRange) -> Bool {
        guard trimmedLine == "---" || trimmedLine == "***" else {
            return false
        }

        attributed.addAttributes(
            [
                .font: monoFont(size: 11),
                .foregroundColor: ghostSyntaxColor,
                .paragraphStyle: paragraphStyle(lineSpacing: 0, paragraphSpacing: 12, paragraphSpacingBefore: 10)
            ],
            range: lineRange
        )
        return true
    }

    private static func styleTableIfNeeded(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) -> Bool {
        guard line.contains("|") else {
            return false
        }

        attributed.addAttributes(
            [
                .font: monoFont(size: 13.5),
                .foregroundColor: textColor,
                .backgroundColor: tableBackground,
                .paragraphStyle: paragraphStyle(lineSpacing: 4, paragraphSpacing: 4, paragraphSpacingBefore: 8, firstLineHeadIndent: 16, headIndent: 16, tailIndent: -14)
            ],
            range: lineRange
        )

        highlightMatches(of: #"\|"#, in: line, lineRange: lineRange, attributed: attributed, color: ghostSyntaxColor)
        return true
    }

    private static func styleImageIfNeeded(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) -> Bool {
        guard line.trimmingCharacters(in: .whitespaces).hasPrefix("![") else {
            return false
        }

        attributed.addAttributes(
            [
                .font: bodyFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle(lineSpacing: 11, paragraphSpacing: 14, paragraphSpacingBefore: 6)
            ],
            range: lineRange
        )

        highlightMatches(of: #"!?\[|\]|\(|\)"#, in: line, lineRange: lineRange, attributed: attributed, color: ghostSyntaxColor)
        highlightMatches(of: #"!\["#, in: line, lineRange: lineRange, attributed: attributed, color: faintSyntaxColor)
        if let match = try? NSRegularExpression(pattern: #"\(([^)]+)\)"#).firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)),
           match.numberOfRanges == 2 {
            let urlRange = NSRange(location: lineRange.location + match.range(at: 1).location, length: match.range(at: 1).length)
            attributed.addAttributes(
                [
                    .font: monoFont(size: 13),
                    .foregroundColor: mutedColor
                ],
                range: urlRange
            )
        }
        return true
    }

    private static func applyInlineStyles(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) {
        styleInlineCode(in: attributed, line: line, lineRange: lineRange)
        styleInlineLinks(in: attributed, line: line, lineRange: lineRange)
        styleInlineStrong(in: attributed, line: line, lineRange: lineRange, marker: "**")
        styleInlineStrong(in: attributed, line: line, lineRange: lineRange, marker: "__")
        styleInlineEmphasis(in: attributed, line: line, lineRange: lineRange, marker: "*")
        styleInlineEmphasis(in: attributed, line: line, lineRange: lineRange, marker: "_")
    }

    private static func styleInlineCode(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) {
        applyRegex(#"`([^`]+)`"#, to: line, lineRange: lineRange) { ranges in
            guard ranges.count == 2 else {
                return
            }
            let full = ranges[0]
            let inner = ranges[1]
            let left = NSRange(location: full.location, length: 1)
            let right = NSRange(location: full.location + full.length - 1, length: 1)
            let innerRange = inner

            attributed.addAttributes(
                [
                    .foregroundColor: ghostSyntaxColor,
                    .font: monoFont(size: max(inlineFontSize(attributed, range: innerRange) - 3, 10))
                ],
                range: left
            )
            attributed.addAttributes(
                [
                    .foregroundColor: ghostSyntaxColor,
                    .font: monoFont(size: max(inlineFontSize(attributed, range: innerRange) - 3, 10))
                ],
                range: right
            )
            attributed.addAttributes(
                [
                    .font: monoFont(size: max(inlineFontSize(attributed, range: innerRange) - 1.5, 13)),
                    .foregroundColor: codeInlineColor,
                    .backgroundColor: inlineCodeBackground,
                    .baselineOffset: 0.4,
                    .kern: 0.08
                ],
                range: innerRange
            )
        }
    }

    private static func styleInlineLinks(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) {
        applyRegex(#"\[([^\]]+)\]\(([^)]+)\)"#, to: line, lineRange: lineRange) { ranges in
            guard ranges.count == 3 else {
                return
            }
            let full = ranges[0]
            let label = ranges[1]
            let url = ranges[2]

            attributed.addAttributes(
                [
                    .foregroundColor: linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: linkUnderlineColor
                ],
                range: label
            )
            attributed.addAttributes(
                [
                    .foregroundColor: mutedColor,
                    .font: monoFont(size: max(inlineFontSize(attributed, range: url) - 1, 12))
                ],
                range: url
            )

            let fullRange = NSRange(location: full.location, length: full.length)
            highlightBracketCharacters(in: attributed, range: fullRange)
        }
    }

    private static func styleInlineStrong(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange, marker: String) {
        let escapedMarker = NSRegularExpression.escapedPattern(for: marker)
        let pattern = escapedMarker + "([^" + String(marker.prefix(1)) + "]+)" + escapedMarker

        applyRegex(pattern, to: line, lineRange: lineRange) { ranges in
            guard ranges.count == 2 else {
                return
            }

            let inner = ranges[1]
            let full = ranges[0]
            let leading = NSRange(location: full.location, length: marker.count)
            let trailing = NSRange(location: full.location + full.length - marker.count, length: marker.count)

            attributed.addAttributes([.foregroundColor: ghostSyntaxColor], range: leading)
            attributed.addAttributes([.foregroundColor: ghostSyntaxColor], range: trailing)
            attributed.addAttributes(
                [
                    .font: boldFont(size: inlineFontSize(attributed, range: inner)),
                    .foregroundColor: strongTextColor,
                    .kern: 0.05
                ],
                range: inner
            )
        }
    }

    private static func styleInlineEmphasis(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange, marker: String) {
        let escapedMarker = NSRegularExpression.escapedPattern(for: marker)
        let pattern = "(?<!\(escapedMarker))" + escapedMarker + "([^" + marker + "]+)" + escapedMarker + "(?!\(escapedMarker))"

        applyRegex(pattern, to: line, lineRange: lineRange) { ranges in
            guard ranges.count == 2 else {
                return
            }

            let inner = ranges[1]
            let full = ranges[0]
            let leading = NSRange(location: full.location, length: 1)
            let trailing = NSRange(location: full.location + full.length - 1, length: 1)

            attributed.addAttributes([.foregroundColor: ghostSyntaxColor], range: leading)
            attributed.addAttributes([.foregroundColor: ghostSyntaxColor], range: trailing)
            attributed.addAttributes(
                [
                    .font: italicFont(size: inlineFontSize(attributed, range: inner)),
                    .foregroundColor: emphasisTextColor
                ],
                range: inner
            )
        }
    }

    private static func applyRegex(
        _ pattern: String,
        to line: String,
        lineRange: NSRange,
        apply: ([NSRange]) -> Void
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return
        }

        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        for match in matches.reversed() {
            let ranges = (0..<match.numberOfRanges).map { index -> NSRange in
                let range = match.range(at: index)
                guard range.location != NSNotFound else {
                    return range
                }
                return NSRange(location: lineRange.location + range.location, length: range.length)
            }
            apply(ranges)
        }
    }

    private static func highlightMatches(
        of pattern: String,
        in line: String,
        lineRange: NSRange,
        attributed: NSMutableAttributedString,
        color: PlatformColor
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return
        }

        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        for match in matches {
            let range = NSRange(location: lineRange.location + match.range.location, length: match.range.length)
            attributed.addAttributes([.foregroundColor: color], range: range)
        }
    }

    private static func highlightBracketCharacters(in attributed: NSMutableAttributedString, range: NSRange) {
        let snippet = (attributed.string as NSString).substring(with: range)
        for (index, character) in snippet.enumerated() where "[]()".contains(character) {
            attributed.addAttributes(
                [.foregroundColor: ghostSyntaxColor],
                range: NSRange(location: range.location + index, length: 1)
            )
        }
    }

    private static func applyParagraphFocus(in attributed: NSMutableAttributedString, text: String, focusedRange: NSRange?) {
        guard let focusedRange,
              attributed.length > 0 else {
            return
        }

        let nsText = text as NSString
        let paragraphRanges = rangesByParagraph(in: nsText)
        let focusedIndices = paragraphRanges.indices.filter { NSIntersectionRange(paragraphRanges[$0], focusedRange).length > 0 }

        guard !focusedIndices.isEmpty else {
            return
        }

        for (index, paragraphRange) in paragraphRanges.enumerated() {
            let distance = focusedIndices.map { abs($0 - index) }.min() ?? 0
            let alpha: CGFloat

            switch distance {
            case 0:
                alpha = 1
            case 1:
                alpha = 0.84
            default:
                alpha = 0.68
            }

            guard alpha < 0.999 else {
                continue
            }

            fadeForegroundColors(in: attributed, range: paragraphRange, alpha: alpha)
        }
    }

    private static func rangesByParagraph(in text: NSString) -> [NSRange] {
        guard text.length > 0 else {
            return []
        }

        var ranges: [NSRange] = []
        var location = 0

        while location < text.length {
            let paragraphRange = text.paragraphRange(for: NSRange(location: location, length: 0))
            ranges.append(paragraphRange)
            location = NSMaxRange(paragraphRange)
        }

        return ranges
    }

    private static func fadeForegroundColors(in attributed: NSMutableAttributedString, range: NSRange, alpha: CGFloat) {
        attributed.enumerateAttribute(.foregroundColor, in: range) { value, effectiveRange, _ in
            guard let color = value as? PlatformColor else {
                return
            }

            attributed.addAttribute(
                .foregroundColor,
                value: colorByApplyingAlpha(alpha, to: color),
                range: effectiveRange
            )
        }
    }

    private static func colorByApplyingAlpha(_ alpha: CGFloat, to color: PlatformColor) -> PlatformColor {
        #if canImport(AppKit)
        let resolved = color.usingColorSpace(.deviceRGB) ?? color
        return resolved.withAlphaComponent(resolved.alphaComponent * alpha)
        #else
        return color.withAlphaComponent(color.cgColor.alpha * alpha)
        #endif
    }

    private static func inlineFontSize(_ attributed: NSMutableAttributedString, range: NSRange) -> CGFloat {
        guard range.location != NSNotFound,
              range.location < attributed.length,
              let font = attributed.attribute(.font, at: range.location, effectiveRange: nil) as? PlatformFont else {
            return bodyFont.pointSize
        }
        return font.pointSize
    }

    private static func activeLineContext(in text: String, selectedRange: NSRange) -> ActiveLineContext {
        let lines = text.components(separatedBy: "\n")
        let textLength = (text as NSString).length
        let targetLocation = min(max(selectedRange.location, 0), textLength)

        var location = 0
        var inFrontmatter = false
        var inCodeBlock = false
        var hasEncounteredMeaningfulBlock = false

        for (index, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: location, length: lineLength)
            let lineBoundaryEnd = location + lineLength + (index < lines.count - 1 ? 1 : 0)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isLeadingBlock = trimmed.isEmpty == false && !hasEncounteredMeaningfulBlock
            let isTargetLine = targetLocation >= location && (
                index == lines.count - 1
                    ? targetLocation <= lineBoundaryEnd
                    : targetLocation < lineBoundaryEnd
            )

            if index == 0, trimmed == "---" {
                if isTargetLine {
                    return .init(kind: .frontmatterFence(isOpening: true), lineRange: lineRange, isLeadingBlock: false)
                }
                inFrontmatter = true
                location = lineBoundaryEnd
                continue
            }

            if inFrontmatter {
                if isTargetLine {
                    return .init(
                        kind: trimmed == "---"
                            ? .frontmatterFence(isOpening: false)
                            : .frontmatterField(separatorOffset: frontmatterSeparatorOffset(in: line)),
                        lineRange: lineRange,
                        isLeadingBlock: false
                    )
                }
                if trimmed == "---" {
                    inFrontmatter = false
                }
                location = lineBoundaryEnd
                continue
            }

            if trimmed.hasPrefix("```") {
                if isTargetLine {
                    return .init(
                        kind: .codeFence(leadingWhitespace: leadingWhitespaceCount(in: line), markerLength: 3, isOpening: inCodeBlock == false),
                        lineRange: lineRange,
                        isLeadingBlock: isLeadingBlock
                    )
                }
                inCodeBlock.toggle()
                if trimmed.isEmpty == false {
                    hasEncounteredMeaningfulBlock = true
                }
                location = lineBoundaryEnd
                continue
            }

            if inCodeBlock {
                if isTargetLine {
                    return .init(kind: .codeBlock, lineRange: lineRange, isLeadingBlock: isLeadingBlock)
                }
                if trimmed.isEmpty == false {
                    hasEncounteredMeaningfulBlock = true
                }
                location = lineBoundaryEnd
                continue
            }

            if let markerCount = headingLevel(in: line) {
                if isTargetLine {
                    return .init(
                        kind: .heading(level: markerCount, markerCount: markerCount, leadingWhitespace: leadingWhitespaceCount(in: line)),
                        lineRange: lineRange,
                        isLeadingBlock: isLeadingBlock
                    )
                }
                hasEncounteredMeaningfulBlock = true
                location = lineBoundaryEnd
                continue
            }

            if quoteMarkerLength(in: line) != nil {
                if isTargetLine {
                    return .init(
                        kind: .quote(leadingWhitespace: leadingWhitespaceCount(in: line)),
                        lineRange: lineRange,
                        isLeadingBlock: isLeadingBlock
                    )
                }
                hasEncounteredMeaningfulBlock = true
                location = lineBoundaryEnd
                continue
            }

            if let info = unorderedListMarker(in: line) {
                if isTargetLine {
                    return .init(
                        kind: .unorderedList(markerLength: info.markerLength, leadingWhitespace: info.leadingWhitespace),
                        lineRange: lineRange,
                        isLeadingBlock: isLeadingBlock
                    )
                }
                hasEncounteredMeaningfulBlock = true
                location = lineBoundaryEnd
                continue
            }

            if let info = orderedListMarker(in: line) {
                if isTargetLine {
                    return .init(
                        kind: .orderedList(markerLength: info.markerLength, leadingWhitespace: info.leadingWhitespace),
                        lineRange: lineRange,
                        isLeadingBlock: isLeadingBlock
                    )
                }
                hasEncounteredMeaningfulBlock = true
                location = lineBoundaryEnd
                continue
            }

            if isTargetLine {
                return .init(kind: .body, lineRange: lineRange, isLeadingBlock: isLeadingBlock)
            }

            if trimmed.isEmpty == false {
                hasEncounteredMeaningfulBlock = true
            }
            location = lineBoundaryEnd
        }

        return .init(kind: .body, lineRange: NSRange(location: targetLocation, length: 0), isLeadingBlock: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private static var bodyFont: PlatformFont {
        readingFont(size: 18, weight: .regular)
    }

    private static func headingTypingAttributes(level: Int, isLeadingBlock: Bool) -> [NSAttributedString.Key: Any] {
        let isDisplayHeading = shouldUseDisplayHeading(level: level, isLeadingBlock: isLeadingBlock)
        var attributes: [NSAttributedString.Key: Any] = [
            .font: headingFont(level: level, isDisplayHeading: isDisplayHeading),
            .foregroundColor: headingTextColor(isDisplayHeading: isDisplayHeading),
            .paragraphStyle: headingParagraphStyle(level: level, isLeadingBlock: isLeadingBlock)
        ]
        let kern = headingKern(level: level, isDisplayHeading: isDisplayHeading)
        if abs(kern) > 0.001 {
            attributes[.kern] = kern
        }
        return attributes
    }

    private static var frontmatterFenceTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: monoFont(size: 12),
            .foregroundColor: ghostSyntaxColor,
            .backgroundColor: frontmatterBackground,
            .paragraphStyle: paragraphStyle(lineSpacing: 4, paragraphSpacing: 3, paragraphSpacingBefore: 4, firstLineHeadIndent: 14, headIndent: 14, tailIndent: -12)
        ]
    }

    private static var frontmatterKeyTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: monoFont(size: 13),
            .foregroundColor: structuralSyntaxColor,
            .backgroundColor: frontmatterBackground,
            .paragraphStyle: paragraphStyle(lineSpacing: 7, paragraphSpacing: 4, firstLineHeadIndent: 14, headIndent: 14, tailIndent: -12)
        ]
    }

    private static var frontmatterValueTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: monoFont(size: 13),
            .foregroundColor: textColor,
            .backgroundColor: frontmatterBackground,
            .paragraphStyle: paragraphStyle(lineSpacing: 7, paragraphSpacing: 4, firstLineHeadIndent: 14, headIndent: 14, tailIndent: -12)
        ]
    }

    private static var codeFenceMarkerTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: monoFont(size: 12),
            .foregroundColor: structuralSyntaxColor,
            .backgroundColor: codeBackground,
            .paragraphStyle: paragraphStyle(lineSpacing: 4, paragraphSpacing: 4, paragraphSpacingBefore: 8, firstLineHeadIndent: 24, headIndent: 24, tailIndent: -18)
        ]
    }

    private static var codeFenceLanguageTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: monoFont(size: 12.5),
            .foregroundColor: mutedColor,
            .backgroundColor: codeBackground,
            .paragraphStyle: paragraphStyle(lineSpacing: 4, paragraphSpacing: 4, paragraphSpacingBefore: 8, firstLineHeadIndent: 24, headIndent: 24, tailIndent: -18)
        ]
    }

    private static var codeLineTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: monoFont(size: 13.5),
            .foregroundColor: codeTextColor,
            .backgroundColor: codeBackground,
            .paragraphStyle: paragraphStyle(lineSpacing: 4, paragraphSpacing: 1, firstLineHeadIndent: 24, headIndent: 24, tailIndent: -18)
        ]
    }

    private static var quoteTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .foregroundColor: quoteColor,
            .backgroundColor: quoteBackground,
            .paragraphStyle: paragraphStyle(lineSpacing: 10, paragraphSpacing: 10, paragraphSpacingBefore: 8, firstLineHeadIndent: 30, headIndent: 30, tailIndent: -12)
        ]
    }

    private static var quoteMarkerTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: monoFont(size: 13),
            .foregroundColor: structuralSyntaxColor,
            .backgroundColor: quoteBackground,
            .paragraphStyle: paragraphStyle(lineSpacing: 10, paragraphSpacing: 10, paragraphSpacingBefore: 8, firstLineHeadIndent: 30, headIndent: 30, tailIndent: -12)
        ]
    }

    private static func listMarkerTypingAttributes(markerLength: Int, leadingWhitespace: Int) -> [NSAttributedString.Key: Any] {
        [
            .font: monoFont(size: 12),
            .foregroundColor: faintSyntaxColor,
            .paragraphStyle: paragraphStyle(
                lineSpacing: 10,
                paragraphSpacing: 8,
                paragraphSpacingBefore: 2,
                firstLineHeadIndent: listIndent(markerLength: markerLength, leadingWhitespace: leadingWhitespace),
                headIndent: listIndent(markerLength: markerLength, leadingWhitespace: leadingWhitespace)
            )
        ]
    }

    private static func listTypingAttributes(markerLength: Int, leadingWhitespace: Int) -> [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle(
                lineSpacing: 10,
                paragraphSpacing: 8,
                paragraphSpacingBefore: 2,
                firstLineHeadIndent: listIndent(markerLength: markerLength, leadingWhitespace: leadingWhitespace),
                headIndent: listIndent(markerLength: markerLength, leadingWhitespace: leadingWhitespace)
            )
        ]
    }

    private static func headingFont(level: Int, isDisplayHeading: Bool) -> PlatformFont {
        if isDisplayHeading {
            switch level {
            case 1:
                return readingFont(size: 38, weight: .bold)
            default:
                return readingFont(size: 31, weight: .semibold)
            }
        }

        switch level {
        case 1:
            return readingFont(size: 33, weight: .bold)
        case 2:
            return readingFont(size: 28, weight: .semibold)
        case 3:
            return readingFont(size: 24, weight: .semibold)
        case 4:
            return readingFont(size: 21, weight: .medium)
        case 5:
            return readingFont(size: 19, weight: .medium)
        default:
            return readingFont(size: 18, weight: .medium)
        }
    }

    private static func headingMarkerSize(level: Int, isDisplayHeading: Bool) -> CGFloat {
        if isDisplayHeading {
            switch level {
            case 1:
                return 10.5
            default:
                return 10
            }
        }

        switch level {
        case 1:
            return 11
        case 2:
            return 10.5
        default:
            return 10
        }
    }

    private static func headingParagraphStyle(level: Int, isLeadingBlock: Bool) -> NSParagraphStyle {
        let isDisplayHeading = shouldUseDisplayHeading(level: level, isLeadingBlock: isLeadingBlock)
        return paragraphStyle(
            lineSpacing: isDisplayHeading ? 6 : 8,
            paragraphSpacing: headingSpacingAfter(level: level, isDisplayHeading: isDisplayHeading),
            paragraphSpacingBefore: headingSpacingBefore(level: level, isLeadingBlock: isLeadingBlock, isDisplayHeading: isDisplayHeading),
            firstLineHeadIndent: 0,
            headIndent: 0
        )
    }

    private static func headingSpacingBefore(level: Int, isLeadingBlock: Bool, isDisplayHeading: Bool) -> CGFloat {
        if isDisplayHeading {
            return level == 1 ? 8 : 6
        }

        if isLeadingBlock {
            return level <= 2 ? 10 : 8
        }

        switch level {
        case 1:
            return 20
        case 2:
            return 16
        case 3:
            return 14
        default:
            return 10
        }
    }

    private static func headingSpacingAfter(level: Int, isDisplayHeading: Bool) -> CGFloat {
        if isDisplayHeading {
            return level == 1 ? 24 : 18
        }

        switch level {
        case 1:
            return 20
        case 2:
            return 16
        case 3:
            return 14
        default:
            return 10
        }
    }

    private static func headingTextColor(isDisplayHeading: Bool) -> PlatformColor {
        isDisplayHeading ? strongTextColor : textColor
    }

    private static func headingKern(level: Int, isDisplayHeading: Bool) -> CGFloat {
        guard isDisplayHeading else {
            return 0
        }
        return level == 1 ? 0.14 : 0.08
    }

    private static func headingMarkerColor(isFocused: Bool, isDisplayHeading: Bool) -> PlatformColor {
        if isFocused {
            return isDisplayHeading
                ? colorByApplyingAlpha(0.82, to: accentColor)
                : structuralSyntaxColor
        }

        return isDisplayHeading ? faintSyntaxColor : ghostSyntaxColor
    }

    private static func shouldUseDisplayHeading(level: Int, isLeadingBlock: Bool) -> Bool {
        isLeadingBlock && level <= 2
    }

    private static func headingLevel(in line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let markerCount = trimmed.prefix { $0 == "#" }.count

        guard (1...6).contains(markerCount),
              trimmed.dropFirst(markerCount).first == " " else {
            return nil
        }

        return markerCount
    }

    private static func frontmatterSeparatorOffset(in line: String) -> Int? {
        guard let separator = line.firstIndex(of: ":") else {
            return nil
        }
        return line.distance(from: line.startIndex, to: separator)
    }

    private static func exitBlockContinuation(lineRange: NSRange, leadingWhitespace: Int) -> EnterContinuation {
        let replacementText = String(repeating: " ", count: leadingWhitespace)
        return .init(
            replacementRange: lineRange,
            replacementText: replacementText,
            caretLocation: lineRange.location + replacementText.utf16.count
        )
    }

    private static func headingContentIsEmpty(in line: String, markerCount: Int) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= markerCount else {
            return false
        }
        let content = trimmed.dropFirst(markerCount).drop { $0 == " " }
        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    fileprivate static func clamped(_ range: NSRange, maxLength: Int) -> NSRange {
        let location = min(max(range.location, 0), maxLength)
        let length = min(max(range.length, 0), max(maxLength - location, 0))
        return NSRange(location: location, length: length)
    }

    private static func mutation(from replacement: EditorCanvasReplacement, textLength: Int) -> CommandMutation {
        .init(
            replacementRange: clamped(replacement.replacementRange, maxLength: textLength),
            replacementText: replacement.replacementText,
            selectedRange: replacement.selectedRange
        )
    }

    private static func inlineWrapMutation(in text: NSString, selectedRange: NSRange, wrapper: String) -> CommandMutation {
        let wrapperLength = (wrapper as NSString).length
        let selected = text.substring(with: selectedRange)

        if selectedRange.length == 0 {
            return .init(
                replacementRange: selectedRange,
                replacementText: wrapper + wrapper,
                selectedRange: NSRange(location: selectedRange.location + wrapperLength, length: 0)
            )
        }

        return .init(
            replacementRange: selectedRange,
            replacementText: wrapper + selected + wrapper,
            selectedRange: NSRange(location: selectedRange.location + wrapperLength, length: selectedRange.length)
        )
    }

    private static func linkMutation(in text: NSString, selectedRange: NSRange) -> CommandMutation {
        let placeholderURL = "https://"

        if selectedRange.length == 0 {
            let placeholderTitle = "link"
            return .init(
                replacementRange: selectedRange,
                replacementText: "[\(placeholderTitle)](\(placeholderURL))",
                selectedRange: NSRange(location: selectedRange.location + 1, length: (placeholderTitle as NSString).length)
            )
        }

        let selected = text.substring(with: selectedRange)
        let replacementText = "[\(selected)](\(placeholderURL))"
        let urlLocation = selectedRange.location + 1 + selectedRange.length + 2
        return .init(
            replacementRange: selectedRange,
            replacementText: replacementText,
            selectedRange: NSRange(location: urlLocation, length: (placeholderURL as NSString).length)
        )
    }

    private static func selectionWrapMutation(for replacementText: String, in text: NSString, selectedRange: NSRange) -> CommandMutation? {
        guard selectedRange.length > 0 else {
            return nil
        }

        switch replacementText {
        case "*":
            return inlineWrapMutation(in: text, selectedRange: selectedRange, wrapper: "*")
        case "[":
            return linkMutation(in: text, selectedRange: selectedRange)
        case "`":
            let selected = text.substring(with: selectedRange)
            if selected.contains("\n") {
                let fenced = "```\n\(selected)\n```"
                return .init(
                    replacementRange: selectedRange,
                    replacementText: fenced,
                    selectedRange: NSRange(location: selectedRange.location + 4, length: selectedRange.length)
                )
            }
            return inlineWrapMutation(in: text, selectedRange: selectedRange, wrapper: "`")
        default:
            return nil
        }
    }

    private static func autoPairMutation(for replacementText: String, in text: NSString, selectedRange: NSRange) -> CommandMutation? {
        guard selectedRange.length == 0 else {
            return nil
        }

        switch replacementText {
        case "[":
            return .init(
                replacementRange: selectedRange,
                replacementText: "[]()",
                selectedRange: NSRange(location: selectedRange.location + 1, length: 0)
            )
        case "*":
            guard shouldAutoPairStrongMarkers(in: text, selectedRange: selectedRange) else {
                return nil
            }

            return .init(
                replacementRange: NSRange(location: selectedRange.location - 1, length: 1),
                replacementText: "****",
                selectedRange: NSRange(location: selectedRange.location + 1, length: 0)
            )
        default:
            return nil
        }
    }

    private static func pasteMutation(for replacementText: String, selectedRange: NSRange) -> CommandMutation? {
        let normalized = replacementText.replacingOccurrences(of: "\r\n", with: "\n")
        guard normalized.contains("\n") || normalized.contains("\t") else {
            return nil
        }

        if normalized.contains("\t"),
           normalized.contains("\n"),
           let table = MarkdownTable.fromDelimitedText(normalized) {
            let markdown = table.markdown
            let endLocation = selectedRange.location + (markdown as NSString).length
            return .init(
                replacementRange: selectedRange,
                replacementText: markdown,
                selectedRange: NSRange(location: endLocation, length: 0)
            )
        }

        if let listMarkdown = normalizedListPaste(from: normalized) {
            let endLocation = selectedRange.location + (listMarkdown as NSString).length
            return .init(
                replacementRange: selectedRange,
                replacementText: listMarkdown,
                selectedRange: NSRange(location: endLocation, length: 0)
            )
        }

        return nil
    }

    private static func normalizedListPaste(from text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        var normalizedLines: [String] = []
        var convertedLineCount = 0

        for line in lines {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                normalizedLines.append("")
                continue
            }

            if let bulletLine = normalizedBulletLine(from: line) {
                normalizedLines.append(bulletLine.line)
                if bulletLine.changed {
                    convertedLineCount += 1
                }
                continue
            }

            if let orderedLine = normalizedOrderedLine(from: line) {
                normalizedLines.append(orderedLine.line)
                if orderedLine.changed {
                    convertedLineCount += 1
                }
                continue
            }

            return nil
        }

        guard convertedLineCount > 0 else {
            return nil
        }

        return normalizedLines.joined(separator: "\n")
    }

    private static func normalizedBulletLine(from line: String) -> (line: String, changed: Bool)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let supportedMarkers: Set<Character> = ["-", "*", "+", "•", "·", "▪", "◦"]
        guard let marker = trimmed.first,
              supportedMarkers.contains(marker),
              trimmed.dropFirst().first?.isWhitespace == true else {
            return nil
        }

        let leadingWhitespace = String(repeating: " ", count: leadingWhitespaceCount(in: line))
        let content = trimmed.dropFirst().drop { $0.isWhitespace }
        let normalized = leadingWhitespace + "- " + String(content)
        return (normalized, normalized != line)
    }

    private static func normalizedOrderedLine(from line: String) -> (line: String, changed: Bool)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let regex = try? NSRegularExpression(pattern: #"^(\d+)([.)])\s+(.+)$"#) else {
            return nil
        }

        let searchRange = NSRange(location: 0, length: (trimmed as NSString).length)
        guard let match = regex.firstMatch(in: trimmed, range: searchRange),
              let numberRange = Range(match.range(at: 1), in: trimmed),
              let delimiterRange = Range(match.range(at: 2), in: trimmed),
              let contentRange = Range(match.range(at: 3), in: trimmed) else {
            return nil
        }

        let number = String(trimmed[numberRange])
        let delimiter = String(trimmed[delimiterRange])
        let content = String(trimmed[contentRange])
        let leadingWhitespace = String(repeating: " ", count: leadingWhitespaceCount(in: line))
        let normalized = leadingWhitespace + "\(number). \(content)"
        return (normalized, delimiter != "." || normalized != line)
    }

    private static func shouldAutoPairStrongMarkers(in text: NSString, selectedRange: NSRange) -> Bool {
        guard selectedRange.location > 0 else {
            return false
        }

        let previousRange = NSRange(location: selectedRange.location - 1, length: 1)
        guard text.substring(with: previousRange) == "*" else {
            return false
        }

        if selectedRange.location > 1 {
            let secondPreviousRange = NSRange(location: selectedRange.location - 2, length: 1)
            if text.substring(with: secondPreviousRange) == "*" {
                return false
            }
        }

        if selectedRange.location < text.length {
            let nextRange = NSRange(location: selectedRange.location, length: 1)
            if text.substring(with: nextRange) == "*" {
                return false
            }
        }

        return true
    }

    private static func inlineBackspaceContinuation(in text: String, replacementRange: NSRange) -> EnterContinuation? {
        let nsText = text as NSString
        let caretLocation = replacementRange.location + replacementRange.length

        if let continuation = inlineBackspaceContinuation(in: nsText, caretLocation: caretLocation, pattern: "****", openingLength: 2) {
            return continuation
        }

        if let continuation = inlineBackspaceContinuation(in: nsText, caretLocation: caretLocation, pattern: "``", openingLength: 1) {
            return continuation
        }

        if let continuation = inlineBackspaceContinuation(in: nsText, caretLocation: caretLocation, pattern: "[]()", openingLength: 1) {
            return continuation
        }

        return nil
    }

    private static func inlineBackspaceContinuation(
        in text: NSString,
        caretLocation: Int,
        pattern: String,
        openingLength: Int
    ) -> EnterContinuation? {
        let patternLength = (pattern as NSString).length
        let start = caretLocation - openingLength

        guard start >= 0,
              start + patternLength <= text.length,
              text.substring(with: NSRange(location: start, length: patternLength)) == pattern else {
            return nil
        }

        return .init(
            replacementRange: NSRange(location: start, length: patternLength),
            replacementText: "",
            caretLocation: start
        )
    }

    private static func lineSubstring(in text: String, range: NSRange) -> String {
        guard range.location != NSNotFound,
              let textRange = Range(range, in: text) else {
            return ""
        }
        return String(text[textRange])
    }

    private static func quoteContinuationInfo(in line: String, leadingWhitespace: Int) -> (prefix: String, isEmpty: Bool)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix(">") else {
            return nil
        }
        let content = trimmed.dropFirst().drop { $0 == " " }
        let prefix = String(repeating: " ", count: leadingWhitespace) + "> "
        return (prefix: prefix, isEmpty: content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private static func unorderedListContinuationInfo(in line: String) -> (prefix: String, isEmpty: Bool)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") else {
            return nil
        }
        let leadingWhitespace = leadingWhitespaceCount(in: line)
        let marker = trimmed.prefix(1)
        let content = trimmed.dropFirst(2)
        let prefix = String(repeating: " ", count: leadingWhitespace) + marker + " "
        return (prefix: prefix, isEmpty: content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private static func orderedListContinuationInfo(in line: String) -> (prefix: String, isEmpty: Bool)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let regex = try? NSRegularExpression(pattern: #"^(\d+)\.\s"#) else {
            return nil
        }

        let searchRange = NSRange(location: 0, length: (trimmed as NSString).length)
        guard let match = regex.firstMatch(in: trimmed, range: searchRange),
              match.numberOfRanges == 2,
              let numberRange = Range(match.range(at: 1), in: trimmed),
              let number = Int(trimmed[numberRange]) else {
            return nil
        }

        let markerLength = match.range.length
        let leadingWhitespace = leadingWhitespaceCount(in: line)
        let contentStart = trimmed.index(trimmed.startIndex, offsetBy: markerLength)
        let content = trimmed[contentStart...]
        let prefix = String(repeating: " ", count: leadingWhitespace) + "\(number + 1). "
        return (prefix: prefix, isEmpty: content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private static func closingCodeFenceLine(for line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("```") else {
            return nil
        }
        return String(repeating: " ", count: leadingWhitespaceCount(in: line)) + "```"
    }

    private static func emptyCodeBlockContinuation(in text: String, currentLineRange: NSRange) -> EnterContinuation? {
        let records = lineRecords(in: text)
        guard let index = records.firstIndex(where: { $0.range == currentLineRange }),
              index > 0,
              index + 1 < records.count else {
            return nil
        }

        let current = records[index]
        let previous = records[index - 1]
        let next = records[index + 1]

        guard current.line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              previous.line.trimmingCharacters(in: .whitespaces).hasPrefix("```"),
              next.line.trimmingCharacters(in: .whitespaces).hasPrefix("```") else {
            return nil
        }

        let replacementStart = previous.range.location
        let replacementEnd = next.fullRange.location + next.fullRange.length
        return .init(
            replacementRange: NSRange(location: replacementStart, length: replacementEnd - replacementStart),
            replacementText: "",
            caretLocation: replacementStart
        )
    }

    private static func lineRecords(in text: String) -> [(range: NSRange, fullRange: NSRange, line: String)] {
        let lines = text.components(separatedBy: "\n")
        var records: [(range: NSRange, fullRange: NSRange, line: String)] = []
        var location = 0

        for (index, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let terminatorLength = index < lines.count - 1 ? 1 : 0
            let range = NSRange(location: location, length: lineLength)
            let fullRange = NSRange(location: location, length: lineLength + terminatorLength)
            records.append((range: range, fullRange: fullRange, line: line))
            location += lineLength + terminatorLength
        }

        return records
    }

    private static func hasClosingCodeFence(after location: Int, in text: String) -> Bool {
        let lines = text.components(separatedBy: "\n")
        var currentLocation = 0

        for (index, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: currentLocation, length: lineLength)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if lineRange.location > location, trimmed.hasPrefix("```") {
                return true
            }
            currentLocation += lineLength + (index < lines.count - 1 ? 1 : 0)
        }

        return false
    }

    private static func hasClosingFrontmatterFence(after location: Int, in text: String) -> Bool {
        let lines = text.components(separatedBy: "\n")
        var currentLocation = 0

        for (index, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: currentLocation, length: lineLength)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if lineRange.location > location, trimmed == "---" {
                return true
            }
            currentLocation += lineLength + (index < lines.count - 1 ? 1 : 0)
        }

        return false
    }

    private static func codeFenceRange(in line: String, lineRange: NSRange) -> NSRange? {
        let leadingWhitespace = leadingWhitespaceCount(in: line)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("```") else {
            return nil
        }
        return NSRange(location: lineRange.location + leadingWhitespace, length: 3)
    }

    private static func quoteMarkerLength(in line: String) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("> ") else {
            return nil
        }
        return 1
    }

    private static func unorderedListMarker(in line: String) -> (markerLength: Int, leadingWhitespace: Int)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") else {
            return nil
        }
        return (markerLength: 1, leadingWhitespace: leadingWhitespaceCount(in: line))
    }

    private static func orderedListMarker(in line: String) -> (markerLength: Int, leadingWhitespace: Int)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let regex = try? NSRegularExpression(pattern: #"^\d+\.\s"#) else {
            return nil
        }

        let searchRange = NSRange(location: 0, length: (trimmed as NSString).length)
        guard let match = regex.firstMatch(in: trimmed, range: searchRange) else {
            return nil
        }

        return (markerLength: match.range.length, leadingWhitespace: leadingWhitespaceCount(in: line))
    }

    private static func listIndent(markerLength: Int, leadingWhitespace: Int) -> CGFloat {
        let baseIndent = CGFloat(leadingWhitespace) * 10
        return max(baseIndent + CGFloat(markerLength) * 7 + 8, markerLength > 1 ? 28 : 22)
    }

    private static func paragraphStyle(
        lineSpacing: CGFloat,
        paragraphSpacing: CGFloat,
        paragraphSpacingBefore: CGFloat = 0,
        firstLineHeadIndent: CGFloat = 0,
        headIndent: CGFloat = 0,
        tailIndent: CGFloat = 0
    ) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        style.paragraphSpacingBefore = paragraphSpacingBefore
        style.firstLineHeadIndent = firstLineHeadIndent
        style.headIndent = headIndent
        style.tailIndent = tailIndent
        return style
    }

    private static var textColor: PlatformColor {
        platformColor(red: 0.15, green: 0.15, blue: 0.14, alpha: 1)
    }

    private static var mutedColor: PlatformColor {
        platformColor(red: 0.48, green: 0.48, blue: 0.46, alpha: 1)
    }

    static var faintSyntaxColor: PlatformColor {
        platformColor(red: 0.79, green: 0.78, blue: 0.75, alpha: 1)
    }

    private static var ghostSyntaxColor: PlatformColor {
        platformColor(red: 0.84, green: 0.83, blue: 0.80, alpha: 1)
    }

    private static var structuralSyntaxColor: PlatformColor {
        platformColor(red: 0.54, green: 0.49, blue: 0.45, alpha: 1)
    }

    fileprivate static var accentColor: PlatformColor {
        platformColor(red: 0.63, green: 0.38, blue: 0.30, alpha: 1)
    }

    private static var quoteColor: PlatformColor {
        platformColor(red: 0.39, green: 0.41, blue: 0.42, alpha: 1)
    }

    private static var subtleBackground: PlatformColor {
        platformColor(red: 0.95, green: 0.95, blue: 0.93, alpha: 1)
    }

    private static var frontmatterBackground: PlatformColor {
        platformColor(red: 0.972, green: 0.969, blue: 0.961, alpha: 1)
    }

    private static var quoteBackground: PlatformColor {
        platformColor(red: 0.978, green: 0.976, blue: 0.968, alpha: 1)
    }

    private static var tableBackground: PlatformColor {
        platformColor(red: 0.979, green: 0.977, blue: 0.969, alpha: 1)
    }

    private static var codeBackground: PlatformColor {
        platformColor(red: 0.958, green: 0.954, blue: 0.946, alpha: 1)
    }

    private static var codeTextColor: PlatformColor {
        platformColor(red: 0.22, green: 0.23, blue: 0.24, alpha: 1)
    }

    private static var codeInlineColor: PlatformColor {
        platformColor(red: 0.34, green: 0.23, blue: 0.20, alpha: 1)
    }

    private static var inlineCodeBackground: PlatformColor {
        platformColor(red: 0.943, green: 0.936, blue: 0.926, alpha: 1)
    }

    private static var linkColor: PlatformColor {
        platformColor(red: 0.22, green: 0.36, blue: 0.50, alpha: 1)
    }

    private static var linkUnderlineColor: PlatformColor {
        platformColor(red: 0.48, green: 0.60, blue: 0.70, alpha: 0.45)
    }

    private static var strongTextColor: PlatformColor {
        platformColor(red: 0.11, green: 0.11, blue: 0.10, alpha: 1)
    }

    private static var emphasisTextColor: PlatformColor {
        platformColor(red: 0.25, green: 0.24, blue: 0.22, alpha: 1)
    }

    private static func monoFont(size: CGFloat) -> PlatformFont {
        #if canImport(AppKit)
        return .monospacedSystemFont(ofSize: size, weight: .regular)
        #else
        return .monospacedSystemFont(ofSize: size, weight: .regular)
        #endif
    }

    private static func boldFont(size: CGFloat) -> PlatformFont {
        readingFont(size: size, weight: .semibold)
    }

    private static func italicFont(size: CGFloat) -> PlatformFont {
        #if canImport(AppKit)
        let font = readingFont(size: size, weight: .regular)
        return NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        #else
        let descriptor = readingFont(size: size, weight: .regular).fontDescriptor.withSymbolicTraits(.traitItalic)
        return descriptor.map { UIFont(descriptor: $0, size: size) } ?? UIFont.italicSystemFont(ofSize: size)
        #endif
    }

    private static func systemFont(size: CGFloat, weight: PlatformWeight) -> PlatformFont {
        #if canImport(AppKit)
        return .systemFont(ofSize: size, weight: weight)
        #else
        return .systemFont(ofSize: size, weight: weight)
        #endif
    }

    private static func readingFont(size: CGFloat, weight: PlatformWeight) -> PlatformFont {
        #if canImport(AppKit)
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.serif),
           let font = NSFont(descriptor: descriptor, size: size) {
            return font
        }
        return base
        #else
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.serif) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
        #endif
    }

    private static func platformColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> PlatformColor {
        #if canImport(AppKit)
        return .init(calibratedRed: red, green: green, blue: blue, alpha: alpha)
        #else
        return .init(red: red, green: green, blue: blue, alpha: alpha)
        #endif
    }

    private static func leadingWhitespaceCount(in line: String) -> Int {
        let prefix = line.prefix { $0 == " " || $0 == "\t" }
        return prefix.count
    }
}

#if canImport(AppKit)
private typealias PlatformWeight = NSFont.Weight
#elseif canImport(UIKit)
private typealias PlatformWeight = UIFont.Weight
#endif
