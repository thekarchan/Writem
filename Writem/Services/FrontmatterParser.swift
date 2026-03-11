import Foundation

enum FrontmatterParser {
    static func parse(_ markdown: String) -> Frontmatter {
        let parts = split(markdown)
        guard parts.hasFrontmatter else {
            return .empty
        }

        var frontmatter = Frontmatter.empty

        for line in parts.frontmatterLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("#"),
                  let separator = trimmed.firstIndex(of: ":") else {
                continue
            }

            let key = String(trimmed[..<separator]).trimmingCharacters(in: .whitespaces)
            let rawValue = String(trimmed[trimmed.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
            let value = unquote(rawValue)

            switch key {
            case "title":
                frontmatter.title = value
            case "date":
                frontmatter.date = value
            case "tags":
                frontmatter.tags = parseTags(rawValue)
            case "draft":
                frontmatter.draft = parseBool(rawValue)
            case "slug":
                frontmatter.slug = value
            case "cover":
                frontmatter.cover = value
            default:
                frontmatter.customFields.append(.init(key: key, value: value))
            }
        }

        return frontmatter
    }

    static func bodyText(from markdown: String) -> String {
        split(markdown).body
    }

    static func merge(_ frontmatter: Frontmatter, into markdown: String) -> String {
        let body = bodyText(from: markdown).trimmingCharacters(in: .newlines)
        let lines = serialize(frontmatter)

        guard !lines.isEmpty else {
            return body
        }

        let header = (["---"] + lines + ["---", ""]).joined(separator: "\n")
        guard !body.isEmpty else {
            return header
        }

        return header + body + "\n"
    }

    private static func split(_ markdown: String) -> (hasFrontmatter: Bool, frontmatterLines: [String], body: String) {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.components(separatedBy: "\n")

        guard lines.first == "---" else {
            return (false, [], normalized)
        }

        var frontmatterLines: [String] = []
        for index in 1..<lines.count {
            if lines[index] == "---" {
                let bodyLines = Array(lines.dropFirst(index + 1))
                return (true, frontmatterLines, bodyLines.joined(separator: "\n"))
            }

            frontmatterLines.append(lines[index])
        }

        return (false, [], normalized)
    }

    private static func serialize(_ frontmatter: Frontmatter) -> [String] {
        let hasPrimaryValue = !frontmatter.title.isEmpty ||
            !frontmatter.date.isEmpty ||
            !frontmatter.slug.isEmpty ||
            !frontmatter.cover.isEmpty ||
            !frontmatter.tags.isEmpty ||
            !frontmatter.customFields.isEmpty

        var lines: [String] = []

        if !frontmatter.title.isEmpty {
            lines.append("title: \(quoted(frontmatter.title))")
        }
        if !frontmatter.date.isEmpty {
            lines.append("date: \(quoted(frontmatter.date))")
        }
        if !frontmatter.tags.isEmpty {
            let values = frontmatter.tags.map { quoted($0) }.joined(separator: ", ")
            lines.append("tags: [\(values)]")
        }
        if hasPrimaryValue || frontmatter.draft {
            lines.append("draft: \(frontmatter.draft ? "true" : "false")")
        }
        if !frontmatter.slug.isEmpty {
            lines.append("slug: \(quoted(frontmatter.slug))")
        }
        if !frontmatter.cover.isEmpty {
            lines.append("cover: \(quoted(frontmatter.cover))")
        }

        for field in frontmatter.customFields where !field.key.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.append("\(field.key): \(quoted(field.value))")
        }

        return lines
    }

    private static func parseTags(_ raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            let inner = trimmed.dropFirst().dropLast()
            return inner
                .split(separator: ",")
                .map { unquote(String($0).trimmingCharacters(in: .whitespaces)) }
                .filter { !$0.isEmpty }
        }

        return trimmed
            .split(separator: ",")
            .map { unquote(String($0).trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }
    }

    private static func parseBool(_ raw: String) -> Bool {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return value == "true" || value == "yes"
    }

    private static func unquote(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            return trimmed
        }

        if (trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"")) ||
            (trimmed.hasPrefix("'") && trimmed.hasSuffix("'")) {
            return String(trimmed.dropFirst().dropLast())
        }

        return trimmed
    }

    private static func quoted(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "\"\""
        }

        let needsQuotes = trimmed.contains(":") ||
            trimmed.contains("#") ||
            trimmed.contains("[") ||
            trimmed.contains("]") ||
            trimmed.contains(",") ||
            trimmed.hasPrefix(" ") ||
            trimmed.hasSuffix(" ")

        let escaped = trimmed.replacingOccurrences(of: "\"", with: "\\\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }
}
