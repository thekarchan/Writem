import SwiftUI

struct CodeToken: Hashable {
    enum Kind: Hashable {
        case plain
        case keyword
        case string
        case number
        case comment
        case type
        case literal
        case directive
        case key
        case `operator`
    }

    let text: String
    let kind: Kind
}

enum CodeHighlightingService {
    static func highlightedLines(for code: String, language: String) -> [[CodeToken]] {
        let normalizedLanguage = language.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return code.components(separatedBy: "\n").map { tokens(in: $0, language: normalizedLanguage) }
    }

    static func color(for kind: CodeToken.Kind) -> Color {
        switch kind {
        case .plain:
            return .white.opacity(0.94)
        case .keyword:
            return Color(red: 0.97, green: 0.66, blue: 0.33)
        case .string:
            return Color(red: 0.53, green: 0.84, blue: 0.68)
        case .number:
            return Color(red: 0.56, green: 0.78, blue: 0.95)
        case .comment:
            return .white.opacity(0.46)
        case .type:
            return Color(red: 0.80, green: 0.71, blue: 0.96)
        case .literal:
            return Color(red: 0.96, green: 0.80, blue: 0.55)
        case .directive:
            return Color(red: 0.96, green: 0.57, blue: 0.57)
        case .key:
            return Color(red: 0.85, green: 0.83, blue: 0.59)
        case .operator:
            return Color(red: 0.86, green: 0.86, blue: 0.89)
        }
    }

    private static func tokens(in line: String, language: String) -> [CodeToken] {
        if language == "json" {
            return jsonTokens(in: line)
        }

        if language == "yaml" || language == "yml" {
            return yamlTokens(in: line)
        }

        if language == "mermaid" {
            return mermaidTokens(in: line)
        }

        if language == "latex" || language == "tex" {
            return latexTokens(in: line)
        }

        return genericProgrammingTokens(in: line, language: language)
    }

    private static func genericProgrammingTokens(in line: String, language: String) -> [CodeToken] {
        let commentPrefix: String?
        switch language {
        case "swift", "javascript", "js", "typescript", "ts", "json":
            commentPrefix = "//"
        case "yaml", "yml":
            commentPrefix = "#"
        case "mermaid":
            commentPrefix = "%%"
        default:
            commentPrefix = nil
        }

        let keywords: Set<String> = [
            "actor", "as", "async", "await", "break", "case", "catch", "class", "const",
            "continue", "default", "defer", "do", "else", "enum", "extension", "false",
            "for", "func", "guard", "if", "import", "in", "init", "let", "nil", "private",
            "protocol", "public", "return", "self", "static", "struct", "switch", "throw",
            "throws", "true", "try", "typealias", "var", "where", "while"
        ]

        let typeNames: Set<String> = [
            "Bool", "CGFloat", "Color", "Data", "Date", "Double", "Float", "Int", "String",
            "URL", "UUID", "View"
        ]

        return tokenize(line: line, commentPrefix: commentPrefix) { word in
            if keywords.contains(word) {
                return .keyword
            }
            if typeNames.contains(word) || word.first?.isUppercase == true {
                return .type
            }
            if ["true", "false", "nil"].contains(word) {
                return .literal
            }
            return .plain
        }
    }

    private static func jsonTokens(in line: String) -> [CodeToken] {
        let quotedRanges = stringRanges(in: line)
        let keyRanges = quotedRanges.filter { range in
            let suffix = line[range.upperBound...]
            return suffix.drop { $0.isWhitespace }.first == ":"
        }

        return tokenize(line: line, commentPrefix: nil) { word in
            if ["true", "false", "null"].contains(word) {
                return .literal
            }
            if Double(word) != nil {
                return .number
            }
            return .plain
        } stringResolver: { range in
            keyRanges.contains(where: { $0 == range }) ? .key : .string
        }
    }

    private static func yamlTokens(in line: String) -> [CodeToken] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("#") {
            return [CodeToken(text: line, kind: .comment)]
        }

        if let separatorIndex = line.firstIndex(of: ":") {
            let key = String(line[..<separatorIndex])
            let value = String(line[separatorIndex...])
            var tokens = [CodeToken(text: key, kind: .key), CodeToken(text: ":", kind: .operator)]
            if value.count > 1 {
                let suffix = String(value.dropFirst())
                tokens.append(contentsOf: tokenize(line: suffix, commentPrefix: nil) { word in
                    if ["true", "false", "null", "yes", "no"].contains(word.lowercased()) {
                        return .literal
                    }
                    if Double(word) != nil {
                        return .number
                    }
                    return .plain
                })
            }
            return tokens
        }

        return tokenize(line: line, commentPrefix: "#") { word in
            Double(word) != nil ? .number : .plain
        }
    }

    private static func mermaidTokens(in line: String) -> [CodeToken] {
        let keywords: Set<String> = [
            "flowchart", "graph", "sequenceDiagram", "classDiagram", "erDiagram", "stateDiagram",
            "subgraph", "style", "classDef", "participant", "note", "title", "direction"
        ]

        let operators = ["-->", "---", "==>", "-.->", "<--", "<->"]
        var working = line

        if let commentRange = working.range(of: "%%") {
            let prefix = String(working[..<commentRange.lowerBound])
            let comment = String(working[commentRange.lowerBound...])
            var tokens = tokenize(line: prefix, commentPrefix: nil) { word in
                keywords.contains(word) ? .directive : .plain
            }
            tokens.append(CodeToken(text: comment, kind: .comment))
            return tokens
        }

        var result: [CodeToken] = []
        while !working.isEmpty {
            if let op = operators.first(where: { working.hasPrefix($0) }) {
                result.append(CodeToken(text: op, kind: .operator))
                working.removeFirst(op.count)
                continue
            }

            let character = working.removeFirst()
            if character.isWhitespace {
                result.append(CodeToken(text: String(character), kind: .plain))
            } else if character == "[" || character == "]" || character == "(" || character == ")" || character == "{" || character == "}" {
                result.append(CodeToken(text: String(character), kind: .directive))
            } else if character.isNumber {
                result.append(CodeToken(text: String(character), kind: .number))
            } else {
                var word = String(character)
                while let first = working.first, first.isLetter || first.isNumber || first == "_" {
                    word.append(working.removeFirst())
                }
                result.append(CodeToken(text: word, kind: keywords.contains(word) ? .directive : .plain))
            }
        }

        return result
    }

    private static func latexTokens(in line: String) -> [CodeToken] {
        var tokens: [CodeToken] = []
        var index = line.startIndex

        while index < line.endIndex {
            let character = line[index]

            if character == "%" {
                tokens.append(CodeToken(text: String(line[index...]), kind: .comment))
                break
            }

            if character == "\\" {
                var end = line.index(after: index)
                while end < line.endIndex, line[end].isLetter {
                    end = line.index(after: end)
                }
                tokens.append(CodeToken(text: String(line[index..<end]), kind: .directive))
                index = end
                continue
            }

            if character.isNumber {
                var end = line.index(after: index)
                while end < line.endIndex, line[end].isNumber || line[end] == "." {
                    end = line.index(after: end)
                }
                tokens.append(CodeToken(text: String(line[index..<end]), kind: .number))
                index = end
                continue
            }

            if "{}[]()^_+-=*/".contains(character) {
                tokens.append(CodeToken(text: String(character), kind: .operator))
            } else {
                tokens.append(CodeToken(text: String(character), kind: .plain))
            }

            index = line.index(after: index)
        }

        return tokens
    }

    private static func tokenize(
        line: String,
        commentPrefix: String?,
        resolver: (String) -> CodeToken.Kind,
        stringResolver: ((Range<String.Index>) -> CodeToken.Kind)? = nil
    ) -> [CodeToken] {
        if let commentPrefix,
           let commentRange = line.range(of: commentPrefix) {
            let prefix = String(line[..<commentRange.lowerBound])
            let comment = String(line[commentRange.lowerBound...])
            return tokenize(line: prefix, commentPrefix: nil, resolver: resolver, stringResolver: stringResolver) + [CodeToken(text: comment, kind: .comment)]
        }

        let stringRanges = stringRanges(in: line)
        var tokens: [CodeToken] = []
        var index = line.startIndex

        while index < line.endIndex {
            if let stringRange = stringRanges.first(where: { $0.lowerBound == index }) {
                let kind = stringResolver?(stringRange) ?? .string
                tokens.append(CodeToken(text: String(line[stringRange]), kind: kind))
                index = stringRange.upperBound
                continue
            }

            let character = line[index]
            if character.isNumber {
                var end = line.index(after: index)
                while end < line.endIndex, line[end].isNumber || line[end] == "." {
                    end = line.index(after: end)
                }
                tokens.append(CodeToken(text: String(line[index..<end]), kind: .number))
                index = end
                continue
            }

            if character.isLetter || character == "_" {
                var end = line.index(after: index)
                while end < line.endIndex, line[end].isLetter || line[end].isNumber || line[end] == "_" {
                    end = line.index(after: end)
                }
                let word = String(line[index..<end])
                tokens.append(CodeToken(text: word, kind: resolver(word)))
                index = end
                continue
            }

            let kind: CodeToken.Kind = "=:+-*/<>!&|.,(){}[]".contains(character) ? .operator : .plain
            tokens.append(CodeToken(text: String(character), kind: kind))
            index = line.index(after: index)
        }

        return tokens
    }

    private static func stringRanges(in line: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var index = line.startIndex

        while index < line.endIndex {
            guard line[index] == "\"" || line[index] == "'" else {
                index = line.index(after: index)
                continue
            }

            let quote = line[index]
            var end = line.index(after: index)
            var isEscaped = false

            while end < line.endIndex {
                let character = line[end]
                if character == "\\" {
                    isEscaped.toggle()
                    end = line.index(after: end)
                    continue
                }

                if character == quote && !isEscaped {
                    let upperBound = line.index(after: end)
                    ranges.append(index..<upperBound)
                    index = upperBound
                    break
                }

                isEscaped = false
                end = line.index(after: end)
            }

            if end >= line.endIndex {
                ranges.append(index..<line.endIndex)
                index = line.endIndex
            }
        }

        return ranges
    }
}
