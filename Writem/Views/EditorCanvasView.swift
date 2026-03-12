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

struct EditorCanvasView: View {
    @Binding var text: String

    let lineWidth: CGFloat
    let onDropImageFiles: ([URL]) -> Bool

    @State private var isImageDropTarget = false
    @State private var shouldFocusEditor = false

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
    }

    private var centeredEditor: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 0)
            MarkdownWritingTextView(text: $text, isFocused: $shouldFocusEditor)
                .frame(maxWidth: lineWidth, maxHeight: .infinity)
                .padding(.top, 30)
                .padding(.bottom, 26)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 46)
    }
}

private struct MarkdownWritingTextView: View {
    @Binding var text: String
    @Binding var isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.97),
                            Color(red: 0.998, green: 0.997, blue: 0.992)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.035), radius: 14, x: 0, y: 6)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.black.opacity(0.035), lineWidth: 1)

            PlatformMarkdownTextView(text: $text, isFocused: $isFocused)
                .padding(.horizontal, 28)
                .padding(.vertical, 28)
        }
    }
}

#if canImport(UIKit)
private struct PlatformMarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .sentences
        textView.spellCheckingType = .yes
        textView.smartQuotesType = .yes
        textView.smartDashesType = .yes
        textView.adjustsFontForContentSizeCategory = true
        textView.keyboardDismissMode = .interactive
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.tintColor = MarkdownEditorStyler.accentColor
        textView.typingAttributes = MarkdownEditorStyler.baseTypingAttributes
        context.coordinator.applyStyledText(on: textView, value: text, force: true)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.applyStyledText(on: textView, value: text, force: textView.text != text)

        if isFocused, !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding private var text: String
        @Binding private var isFocused: Bool
        private var isApplyingUpdate = false
        private var lastFocusedParagraphRange: NSRange?

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            _text = text
            _isFocused = isFocused
        }

        func applyStyledText(on textView: UITextView, value: String, force: Bool) {
            guard force || textView.attributedText?.string != value else {
                return
            }

            let selectedRange = textView.selectedRange
            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: value, selectedRange: selectedRange)
            isApplyingUpdate = true
            textView.attributedText = MarkdownEditorStyler.attributedText(for: value, focusedRange: focusedParagraphRange)
            textView.typingAttributes = MarkdownEditorStyler.baseTypingAttributes
            textView.selectedRange = NSRange(
                location: min(selectedRange.location, textView.text.utf16.count),
                length: min(selectedRange.length, max(textView.text.utf16.count - min(selectedRange.location, textView.text.utf16.count), 0))
            )
            isApplyingUpdate = false
            lastFocusedParagraphRange = focusedParagraphRange
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
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isFocused = false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isApplyingUpdate else {
                return
            }

            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: textView.text, selectedRange: textView.selectedRange)
            guard focusedParagraphRange != lastFocusedParagraphRange else {
                return
            }

            applyStyledText(on: textView, value: textView.text, force: true)
        }
    }
}
#elseif canImport(AppKit)
private struct PlatformMarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.textContainerInset = NSSize(width: 0, height: 0)
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
        context.coordinator.applyStyledText(on: textView, value: text, force: true)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        context.coordinator.applyStyledText(on: textView, value: text, force: textView.string != text)

        if isFocused, textView.window?.firstResponder !== textView {
            textView.window?.makeFirstResponder(textView)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String
        @Binding private var isFocused: Bool
        private var isApplyingUpdate = false
        private var lastFocusedParagraphRange: NSRange?

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            _text = text
            _isFocused = isFocused
        }

        func applyStyledText(on textView: NSTextView, value: String, force: Bool) {
            guard force || textView.string != value else {
                return
            }

            let selectedRanges = textView.selectedRanges
            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: value, selectedRange: textView.selectedRange())
            isApplyingUpdate = true
            textView.textStorage?.setAttributedString(MarkdownEditorStyler.attributedText(for: value, focusedRange: focusedParagraphRange))
            textView.setSelectedRanges(selectedRanges, affinity: .downstream, stillSelecting: false)
            isApplyingUpdate = false
            lastFocusedParagraphRange = focusedParagraphRange
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
        }

        func textDidEndEditing(_ notification: Notification) {
            isFocused = false
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isApplyingUpdate,
                  let textView = notification.object as? NSTextView else {
                return
            }

            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: textView.string, selectedRange: textView.selectedRange())
            guard focusedParagraphRange != lastFocusedParagraphRange else {
                return
            }

            applyStyledText(on: textView, value: textView.string, force: true)
        }
    }
}
#endif

private enum MarkdownEditorStyler {
    static var baseTypingAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bodyFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle(lineSpacing: 10, paragraphSpacing: 16)
        ]
    }

    static var cursorColor: PlatformColor {
        textColor
    }

    static func attributedText(for text: String, focusedRange: NSRange? = nil) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attributed.length)
        attributed.addAttributes(
            [
                .font: bodyFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle(lineSpacing: 10, paragraphSpacing: 16)
            ],
            range: fullRange
        )

        let lines = text.components(separatedBy: "\n")
        var location = 0
        var inFrontmatter = false
        var inCodeBlock = false

        for (index, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: location, length: lineLength)
            let trimmed = line.trimmingCharacters(in: .whitespaces)

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
                location += lineLength + 1
                continue
            }

            if inCodeBlock {
                styleCodeLine(in: attributed, lineRange: lineRange)
                location += lineLength + 1
                continue
            }

            if styleHeadingIfNeeded(in: attributed, line: line, lineRange: lineRange) {
                applyInlineStyles(in: attributed, line: line, lineRange: lineRange)
                location += lineLength + 1
                continue
            }

            if styleQuoteIfNeeded(in: attributed, line: line, lineRange: lineRange) {
                applyInlineStyles(in: attributed, line: line, lineRange: lineRange)
                location += lineLength + 1
                continue
            }

            if styleListIfNeeded(in: attributed, line: line, lineRange: lineRange) {
                applyInlineStyles(in: attributed, line: line, lineRange: lineRange)
                location += lineLength + 1
                continue
            }

            if styleDividerIfNeeded(in: attributed, trimmedLine: trimmed, lineRange: lineRange) {
                location += lineLength + 1
                continue
            }

            if styleTableIfNeeded(in: attributed, line: line, lineRange: lineRange) {
                location += lineLength + 1
                continue
            }

            if styleImageIfNeeded(in: attributed, line: line, lineRange: lineRange) {
                location += lineLength + 1
                continue
            }

            attributed.addAttributes(
                [
                    .font: bodyFont,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraphStyle(lineSpacing: 10, paragraphSpacing: 16)
                ],
                range: lineRange
            )
            applyInlineStyles(in: attributed, line: line, lineRange: lineRange)
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
            [
                .font: monoFont(size: 12),
                .foregroundColor: ghostSyntaxColor
            ],
            range: lineRange
        )
    }

    private static func styleFrontmatterLine(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) {
        attributed.addAttributes(
            [
                .font: monoFont(size: 13),
                .foregroundColor: textColor,
                .backgroundColor: frontmatterBackground
            ],
            range: lineRange
        )

        guard let separator = line.firstIndex(of: ":") else {
            return
        }

        let keyLength = line.distance(from: line.startIndex, to: separator)
        attributed.addAttributes(
            [
                .foregroundColor: structuralSyntaxColor
            ],
            range: NSRange(location: lineRange.location, length: keyLength)
        )
    }

    private static func styleCodeFence(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) {
        attributed.addAttributes(
            [
                .font: monoFont(size: 12),
                .foregroundColor: ghostSyntaxColor,
                .backgroundColor: codeBackground
            ],
            range: lineRange
        )

        if line.count > 3 {
            attributed.addAttributes(
                [
                    .foregroundColor: faintSyntaxColor
                ],
                range: NSRange(location: lineRange.location + 3, length: max(lineRange.length - 3, 0))
            )
        }
    }

    private static func styleCodeLine(in attributed: NSMutableAttributedString, lineRange: NSRange) {
        attributed.addAttributes(
            [
                .font: monoFont(size: 14),
                .foregroundColor: codeTextColor,
                .backgroundColor: codeBackground,
                .paragraphStyle: paragraphStyle(lineSpacing: 5, paragraphSpacing: 10, firstLineHeadIndent: 18, headIndent: 18)
            ],
            range: lineRange
        )
    }

    private static func styleHeadingIfNeeded(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let markerCount = trimmed.prefix { $0 == "#" }.count

        guard (1...6).contains(markerCount),
              trimmed.dropFirst(markerCount).first == " " else {
            return false
        }

        let leadingWhitespace = leadingWhitespaceCount(in: line)
        let markerRange = NSRange(location: lineRange.location + leadingWhitespace, length: markerCount)
        let spacerRange = NSRange(location: markerRange.location + markerCount, length: 1)
        let titleLength = max(lineRange.length - leadingWhitespace - markerCount - 1, 0)
        let titleRange = NSRange(location: spacerRange.location + 1, length: titleLength)

        attributed.addAttributes(
            [
                .font: headingFont(level: markerCount),
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle(
                    lineSpacing: 10,
                    paragraphSpacing: headingSpacing(level: markerCount),
                    firstLineHeadIndent: 0,
                    headIndent: 0
                )
            ],
            range: lineRange
        )
        attributed.addAttributes(
            [
                .font: monoFont(size: headingMarkerSize(level: markerCount)),
                .foregroundColor: ghostSyntaxColor
            ],
            range: markerRange
        )
        attributed.addAttributes(
            [
                .foregroundColor: ghostSyntaxColor
            ],
            range: spacerRange
        )
        attributed.addAttributes(
            [
                .font: headingFont(level: markerCount),
                .foregroundColor: textColor
            ],
            range: titleRange
        )
        return true
    }

    private static func styleQuoteIfNeeded(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("> ") else {
            return false
        }

        let leadingWhitespace = leadingWhitespaceCount(in: line)
        let markerRange = NSRange(location: lineRange.location + leadingWhitespace, length: 1)

        attributed.addAttributes(
            [
                .font: bodyFont,
                .foregroundColor: quoteColor,
                .backgroundColor: quoteBackground,
                .paragraphStyle: paragraphStyle(lineSpacing: 10, paragraphSpacing: 16, firstLineHeadIndent: 22, headIndent: 22)
            ],
            range: lineRange
        )
        attributed.addAttributes(
            [
                .foregroundColor: faintSyntaxColor
            ],
            range: markerRange
        )
        return true
    }

    private static func styleListIfNeeded(in attributed: NSMutableAttributedString, line: String, lineRange: NSRange) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let leadingWhitespace = leadingWhitespaceCount(in: line)

        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            attributed.addAttributes(
                [
                    .font: bodyFont,
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraphStyle(lineSpacing: 10, paragraphSpacing: 10, firstLineHeadIndent: 22, headIndent: 22)
                ],
                range: lineRange
            )
            attributed.addAttributes(
                [
                    .foregroundColor: faintSyntaxColor,
                    .font: monoFont(size: 12)
                ],
                range: NSRange(location: lineRange.location + leadingWhitespace, length: 1)
            )
            return true
        }

        guard let regex = try? NSRegularExpression(pattern: #"^\d+\.\s"#) else {
            return false
        }

        let searchRange = NSRange(location: 0, length: (trimmed as NSString).length)
        guard let match = regex.firstMatch(in: trimmed, range: searchRange) else {
            return false
        }

        attributed.addAttributes(
            [
                .font: bodyFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle(lineSpacing: 10, paragraphSpacing: 10, firstLineHeadIndent: 28, headIndent: 28)
                ],
                range: lineRange
            )
        attributed.addAttributes(
            [
                .foregroundColor: faintSyntaxColor,
                .font: monoFont(size: 12)
            ],
            range: NSRange(location: lineRange.location + leadingWhitespace, length: match.range.length)
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
                .foregroundColor: ghostSyntaxColor
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
                .font: monoFont(size: 14),
                .foregroundColor: textColor,
                .backgroundColor: tableBackground,
                .paragraphStyle: paragraphStyle(lineSpacing: 7, paragraphSpacing: 10)
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
                .foregroundColor: textColor
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
                    .foregroundColor: ghostSyntaxColor
                ],
                range: left
            )
            attributed.addAttributes(
                [
                    .foregroundColor: ghostSyntaxColor
                ],
                range: right
            )
            attributed.addAttributes(
                [
                    .font: monoFont(size: inlineFontSize(attributed, range: innerRange)),
                    .foregroundColor: codeInlineColor,
                    .backgroundColor: inlineCodeBackground
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
                    .foregroundColor: linkColor
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
                    .font: boldFont(size: inlineFontSize(attributed, range: inner))
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
                    .font: italicFont(size: inlineFontSize(attributed, range: inner))
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

    private static var bodyFont: PlatformFont {
        readingFont(size: 18, weight: .regular)
    }

    private static func headingFont(level: Int) -> PlatformFont {
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

    private static func headingMarkerSize(level: Int) -> CGFloat {
        switch level {
        case 1:
            return 11
        case 2:
            return 10.5
        default:
            return 10
        }
    }

    private static func headingSpacing(level: Int) -> CGFloat {
        switch level {
        case 1:
            return 28
        case 2:
            return 24
        case 3:
            return 20
        default:
            return 16
        }
    }

    private static func paragraphStyle(
        lineSpacing: CGFloat,
        paragraphSpacing: CGFloat,
        firstLineHeadIndent: CGFloat = 0,
        headIndent: CGFloat = 0
    ) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        style.firstLineHeadIndent = firstLineHeadIndent
        style.headIndent = headIndent
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

    private static var accentColor: PlatformColor {
        platformColor(red: 0.63, green: 0.38, blue: 0.30, alpha: 1)
    }

    private static var quoteColor: PlatformColor {
        platformColor(red: 0.39, green: 0.41, blue: 0.42, alpha: 1)
    }

    private static var subtleBackground: PlatformColor {
        platformColor(red: 0.95, green: 0.95, blue: 0.93, alpha: 1)
    }

    private static var frontmatterBackground: PlatformColor {
        platformColor(red: 0.975, green: 0.973, blue: 0.966, alpha: 1)
    }

    private static var quoteBackground: PlatformColor {
        platformColor(red: 0.982, green: 0.981, blue: 0.975, alpha: 1)
    }

    private static var tableBackground: PlatformColor {
        platformColor(red: 0.985, green: 0.984, blue: 0.979, alpha: 1)
    }

    private static var codeBackground: PlatformColor {
        platformColor(red: 0.965, green: 0.962, blue: 0.954, alpha: 1)
    }

    private static var codeTextColor: PlatformColor {
        platformColor(red: 0.22, green: 0.23, blue: 0.24, alpha: 1)
    }

    private static var codeInlineColor: PlatformColor {
        platformColor(red: 0.37, green: 0.26, blue: 0.23, alpha: 1)
    }

    private static var inlineCodeBackground: PlatformColor {
        platformColor(red: 0.95, green: 0.944, blue: 0.935, alpha: 1)
    }

    private static var linkColor: PlatformColor {
        platformColor(red: 0.23, green: 0.39, blue: 0.57, alpha: 1)
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
