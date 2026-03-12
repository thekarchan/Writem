import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct MarkdownSyntaxHelpView: View {
    private let sections: [MarkdownSyntaxSection] = [
        .init(
            title: "Headings",
            items: [
                .init(label: "H1", syntax: "# Title"),
                .init(label: "H2", syntax: "## Section"),
                .init(label: "H3", syntax: "### Subsection")
            ]
        ),
        .init(
            title: "Emphasis",
            items: [
                .init(label: "Bold", syntax: "**bold**"),
                .init(label: "Italic", syntax: "*italic*"),
                .init(label: "Inline Code", syntax: "`code`")
            ]
        ),
        .init(
            title: "Lists",
            items: [
                .init(label: "Bullet", syntax: "- First item"),
                .init(label: "Numbered", syntax: "1. First step"),
                .init(label: "Checklist", syntax: "- [ ] Task")
            ]
        ),
        .init(
            title: "Links & Media",
            items: [
                .init(label: "Link", syntax: "[OpenAI](https://openai.com)"),
                .init(label: "Image", syntax: "![Cover](assets/cover.png)")
            ]
        ),
        .init(
            title: "Blocks",
            items: [
                .init(label: "Quote", syntax: "> A highlighted note"),
                .init(label: "Divider", syntax: "---"),
                .init(label: "Code Block", syntax: "```swift\nprint(\"Hello\")\n```")
            ]
        ),
        .init(
            title: "Tables",
            items: [
                .init(label: "Basic Table", syntax: "| Name | Value |\n| --- | --- |\n| Title | Writem |")
            ]
        ),
        .init(
            title: "Frontmatter",
            items: [
                .init(label: "Metadata", syntax: "---\ntitle: Writem\ndate: 2026-03-12\nslug: writem\n---")
            ]
        ),
        .init(
            title: "Shortcuts",
            items: [
                .init(label: "New Draft", syntax: "Cmd + N"),
                .init(label: "Open", syntax: "Cmd + O"),
                .init(label: "Save", syntax: "Cmd + S"),
                .init(label: "Save As", syntax: "Shift + Cmd + S"),
                .init(label: "Bold", syntax: "Cmd + B"),
                .init(label: "Italic", syntax: "Cmd + I"),
                .init(label: "Inline Code", syntax: "Cmd + E"),
                .init(label: "Link", syntax: "Cmd + K"),
                .init(label: "Markdown Help", syntax: "Shift + Cmd + /")
            ]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Markdown Syntax")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                    Text("Quick reference for the markdown syntax and shortcuts Writem supports in everyday writing.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 10) {
                            ForEach(section.items) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(item.label)
                                        .font(.system(size: 13, weight: .medium))
                                        .frame(width: 96, alignment: .leading)
                                        .foregroundStyle(.primary)

                                    Text(item.syntax)
                                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Self.syntaxBlockBackground)
                                        )
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 640, minHeight: 620)
        .background(Self.syntaxWindowBackground)
    }

    #if os(macOS)
    private static let syntaxBlockBackground = Color(nsColor: .textBackgroundColor).opacity(0.75)
    private static let syntaxWindowBackground = Color(nsColor: .windowBackgroundColor)
    #else
    private static let syntaxBlockBackground = Color(uiColor: .secondarySystemBackground)
    private static let syntaxWindowBackground = Color(uiColor: .systemBackground)
    #endif
}

private struct MarkdownSyntaxSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [MarkdownSyntaxItem]
}

private struct MarkdownSyntaxItem: Identifiable {
    let id = UUID()
    let label: String
    let syntax: String
}
