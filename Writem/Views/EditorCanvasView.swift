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
                .padding(.top, 24)
                .padding(.bottom, 22)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
    }
}

private struct MarkdownWritingTextView: View {
    @Binding var text: String
    @Binding var isFocused: Bool

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

            PlatformMarkdownTextView(text: $text, isFocused: $isFocused, layoutProfile: layoutProfile)
                .padding(.horizontal, 42)
                .padding(.vertical, layoutProfile.pageVerticalPadding)
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

#if canImport(UIKit)
private struct PlatformMarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let layoutProfile: WritingLayoutProfile

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
            let clampedSelectedRange = NSRange(
                location: min(selectedRange.location, textView.text.utf16.count),
                length: min(selectedRange.length, max(textView.text.utf16.count - min(selectedRange.location, textView.text.utf16.count), 0))
            )
            textView.selectedRange = clampedSelectedRange
            textView.typingAttributes = MarkdownEditorStyler.typingAttributes(for: value, selectedRange: clampedSelectedRange)
            keepSelectionComfortablyVisible(in: textView)
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
            keepSelectionComfortablyVisible(in: textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isFocused = false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isApplyingUpdate else {
                return
            }

            textView.typingAttributes = MarkdownEditorStyler.typingAttributes(for: textView.text, selectedRange: textView.selectedRange)
            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: textView.text, selectedRange: textView.selectedRange)
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
    }
}
#elseif canImport(AppKit)
private struct PlatformMarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let layoutProfile: WritingLayoutProfile

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
            textView.typingAttributes = MarkdownEditorStyler.typingAttributes(for: value, selectedRange: textView.selectedRange())
            keepSelectionComfortablyVisible(in: textView)
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

            guard let textView = notification.object as? NSTextView else {
                return
            }

            keepSelectionComfortablyVisible(in: textView)
        }

        func textDidEndEditing(_ notification: Notification) {
            isFocused = false
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isApplyingUpdate,
                  let textView = notification.object as? NSTextView else {
                return
            }

            textView.typingAttributes = MarkdownEditorStyler.typingAttributes(for: textView.string, selectedRange: textView.selectedRange())
            let focusedParagraphRange = MarkdownEditorStyler.focusedParagraphRange(in: textView.string, selectedRange: textView.selectedRange())
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
    }
}
#endif

private enum MarkdownEditorStyler {
    private struct ActiveLineContext {
        enum Kind {
            case body
            case frontmatter
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
        case .frontmatter:
            return [
                .font: monoFont(size: 13),
                .foregroundColor: textColor,
                .backgroundColor: frontmatterBackground,
                .paragraphStyle: paragraphStyle(lineSpacing: 7, paragraphSpacing: 4, firstLineHeadIndent: 14, headIndent: 14, tailIndent: -12)
            ]
        case .codeBlock:
            return [
                .font: monoFont(size: 13.5),
                .foregroundColor: codeTextColor,
                .backgroundColor: codeBackground,
                .paragraphStyle: paragraphStyle(lineSpacing: 4, paragraphSpacing: 1, firstLineHeadIndent: 24, headIndent: 24, tailIndent: -18)
            ]
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
                .backgroundColor: frontmatterBackground,
                .paragraphStyle: paragraphStyle(lineSpacing: 7, paragraphSpacing: 4, firstLineHeadIndent: 14, headIndent: 14, tailIndent: -12)
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
                .foregroundColor: structuralSyntaxColor,
                .backgroundColor: codeBackground,
                .paragraphStyle: paragraphStyle(lineSpacing: 4, paragraphSpacing: 4, paragraphSpacingBefore: 8, firstLineHeadIndent: 24, headIndent: 24, tailIndent: -18)
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
                .font: monoFont(size: 13.5),
                .foregroundColor: codeTextColor,
                .backgroundColor: codeBackground,
                .paragraphStyle: paragraphStyle(lineSpacing: 4, paragraphSpacing: 1, firstLineHeadIndent: 24, headIndent: 24, tailIndent: -18)
            ],
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
                    return .init(kind: .frontmatter, lineRange: lineRange, isLeadingBlock: false)
                }
                inFrontmatter = true
                location = lineBoundaryEnd
                continue
            }

            if inFrontmatter {
                if isTargetLine {
                    return .init(kind: .frontmatter, lineRange: lineRange, isLeadingBlock: false)
                }
                if trimmed == "---" {
                    inFrontmatter = false
                }
                location = lineBoundaryEnd
                continue
            }

            if trimmed.hasPrefix("```") {
                if isTargetLine {
                    return .init(kind: .codeBlock, lineRange: lineRange, isLeadingBlock: isLeadingBlock)
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
