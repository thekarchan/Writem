import Foundation

enum MarkdownAnalyzer {
    static func outline(for markdown: String) -> [OutlineItem] {
        let lines = FrontmatterParser.bodyText(from: markdown)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")

        var items: [OutlineItem] = []
        var inCodeBlock = false

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }

            guard !inCodeBlock else {
                continue
            }

            let level = trimmed.prefix { $0 == "#" }.count
            guard (1...6).contains(level),
                  trimmed.dropFirst(level).first == " " else {
                continue
            }

            let title = trimmed.dropFirst(level + 1).trimmingCharacters(in: .whitespacesAndNewlines)
            items.append(.init(lineNumber: index + 1, level: level, title: title))
        }

        return items
    }

    static func preflightIssues(for markdown: String, frontmatter: Frontmatter) -> [PreflightIssue] {
        var issues: [PreflightIssue] = []
        let body = FrontmatterParser.bodyText(from: markdown)

        if frontmatter.title.isEmpty {
            issues.append(.init(severity: .error, title: "Missing title", message: "Frontmatter should define a `title` before publishing.", lineNumber: 1))
        }
        if frontmatter.date.isEmpty {
            issues.append(.init(severity: .error, title: "Missing date", message: "Frontmatter should define a publish `date`.", lineNumber: 1))
        }
        if frontmatter.slug.isEmpty {
            issues.append(.init(severity: .warning, title: "Missing slug", message: "Add a stable `slug` for static site routes.", lineNumber: 1))
        }

        issues.append(contentsOf: headingHierarchyIssues(in: body))
        issues.append(contentsOf: emptyLinkIssues(in: body))
        issues.append(contentsOf: absolutePathIssues(in: body))
        issues.append(contentsOf: paragraphLengthIssues(in: body))

        let fenceCount = body
            .components(separatedBy: "\n")
            .filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("```") }
            .count
        if fenceCount.isMultiple(of: 2) == false {
            issues.append(.init(severity: .error, title: "Unclosed code fence", message: "A fenced code block is missing its closing ``` marker.", lineNumber: nil))
        }

        return issues
    }

    static func wordCount(for markdown: String) -> Int {
        FrontmatterParser.bodyText(from: markdown)
            .split { $0.isWhitespace || $0.isNewline }
            .count
    }

    private static func headingHierarchyIssues(in markdown: String) -> [PreflightIssue] {
        let headings = outline(for: markdown)
        guard headings.count > 1 else {
            return []
        }

        var issues: [PreflightIssue] = []
        var previousLevel = headings.first?.level ?? 1

        for item in headings.dropFirst() {
            if item.level > previousLevel + 1 {
                issues.append(.init(
                    severity: .warning,
                    title: "Heading jump",
                    message: "Heading level jumps from H\(previousLevel) to H\(item.level).",
                    lineNumber: item.lineNumber
                ))
            }
            previousLevel = item.level
        }

        return issues
    }

    private static func emptyLinkIssues(in markdown: String) -> [PreflightIssue] {
        issues(
            in: markdown,
            pattern: #"\[[^\]]*\]\(\s*\)"#,
            severity: .warning,
            title: "Empty link",
            message: "A Markdown link is present but the destination is empty."
        )
    }

    private static func absolutePathIssues(in markdown: String) -> [PreflightIssue] {
        issues(
            in: markdown,
            pattern: #"\]\((\/[^)\s]+)[^)]*\)"#,
            severity: .warning,
            title: "Absolute path reference",
            message: "Local absolute paths are fragile. Prefer project-relative asset paths."
        )
    }

    private static func paragraphLengthIssues(in markdown: String) -> [PreflightIssue] {
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var issues: [PreflightIssue] = []
        var currentParagraph: [String] = []
        var currentStartLine = 1
        var inCodeBlock = false

        func flushParagraph() {
            let paragraph = currentParagraph.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard paragraph.count > 400 else {
                currentParagraph.removeAll()
                return
            }

            issues.append(.init(
                severity: .warning,
                title: "Long paragraph",
                message: "Paragraphs over 400 characters are harder to scan before publishing.",
                lineNumber: currentStartLine
            ))
            currentParagraph.removeAll()
        }

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                flushParagraph()
                inCodeBlock.toggle()
                continue
            }

            if inCodeBlock {
                continue
            }

            if trimmed.isEmpty ||
                trimmed.hasPrefix("#") ||
                trimmed.hasPrefix(">") ||
                trimmed.hasPrefix("- ") ||
                trimmed.hasPrefix("* ") ||
                trimmed.hasPrefix("|") ||
                orderedListPrefix(in: trimmed) != nil {
                flushParagraph()
                continue
            }

            if currentParagraph.isEmpty {
                currentStartLine = index + 1
            }
            currentParagraph.append(trimmed)
        }

        flushParagraph()
        return issues
    }

    private static func issues(in markdown: String, pattern: String, severity: PreflightIssue.Severity, title: String, message: String) -> [PreflightIssue] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let nsRange = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
        return regex.matches(in: markdown, range: nsRange).compactMap { match in
            guard let range = Range(match.range, in: markdown) else {
                return nil
            }
            let lineNumber = markdown[..<range.lowerBound].components(separatedBy: "\n").count
            return .init(severity: severity, title: title, message: message, lineNumber: lineNumber)
        }
    }

    private static func orderedListPrefix(in line: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"^\d+\.\s"#) else {
            return nil
        }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let prefixRange = Range(match.range, in: line) else {
            return nil
        }
        return String(line[prefixRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

