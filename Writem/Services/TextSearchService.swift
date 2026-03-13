import Foundation

enum TextSearchDirection {
    case forward
    case backward
}

enum TextSearchService {
    private static let options: NSString.CompareOptions = [.caseInsensitive]

    static func matchRanges(for query: String, in text: String) -> [NSRange] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        let nsText = text as NSString
        let queryLength = (trimmedQuery as NSString).length
        guard queryLength > 0, nsText.length > 0 else {
            return []
        }

        var matches: [NSRange] = []
        var searchRange = NSRange(location: 0, length: nsText.length)

        while searchRange.length > 0 {
            let match = nsText.range(of: trimmedQuery, options: options, range: searchRange)
            guard match.location != NSNotFound else {
                break
            }

            matches.append(match)

            let nextLocation = match.location + max(match.length, 1)
            guard nextLocation < nsText.length else {
                break
            }

            searchRange = NSRange(location: nextLocation, length: nsText.length - nextLocation)
        }

        return matches
    }

    static func nextMatchRange(
        for query: String,
        in text: String,
        from selectedRange: NSRange,
        direction: TextSearchDirection
    ) -> NSRange? {
        let matches = matchRanges(for: query, in: text)
        guard !matches.isEmpty else {
            return nil
        }

        switch direction {
        case .forward:
            let anchor = selectedRange.location + selectedRange.length
            return matches.first(where: { $0.location >= anchor }) ?? matches.first
        case .backward:
            let anchor = selectedRange.location
            return matches.last(where: { NSMaxRange($0) <= anchor }) ?? matches.last
        }
    }

    static func selectionMatchesQuery(_ selectedRange: NSRange, query: String, in text: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty, selectedRange.length > 0 else {
            return false
        }

        let nsText = text as NSString
        guard NSMaxRange(selectedRange) <= nsText.length else {
            return false
        }

        let selectedText = nsText.substring(with: selectedRange)
        return selectedText.compare(trimmedQuery, options: options) == .orderedSame
    }

    static func replacingAll(query: String, replacement: String, in text: String) -> (text: String, count: Int, firstReplacedRange: NSRange?) {
        let matches = matchRanges(for: query, in: text)
        guard !matches.isEmpty else {
            return (text, 0, nil)
        }

        let mutable = NSMutableString(string: text)
        let replacementLength = (replacement as NSString).length
        var offset = 0
        var firstRange: NSRange?

        for match in matches {
            let adjustedRange = NSRange(location: match.location + offset, length: match.length)
            mutable.replaceCharacters(in: adjustedRange, with: replacement)

            if firstRange == nil {
                firstRange = NSRange(location: adjustedRange.location, length: replacementLength)
            }

            offset += replacementLength - match.length
        }

        return (mutable as String, matches.count, firstRange)
    }
}
