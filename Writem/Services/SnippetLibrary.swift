import Foundation

struct Snippet: Identifiable {
    let id: String
    let title: String
    let symbolName: String
    let content: String
}

enum SnippetLibrary {
    static let all: [Snippet] = [
        .init(id: "heading", title: "Heading", symbolName: "textformat.size", content: "# New section"),
        .init(id: "list", title: "Bullet list", symbolName: "list.bullet", content: "- First point\n- Second point\n- Third point"),
        .init(id: "quote", title: "Quote", symbolName: "text.quote", content: "> A highlighted quote block"),
        .init(id: "code", title: "Code block", symbolName: "curlybraces", content: "```swift\nprint(\"Hello, Writem\")\n```"),
        .init(id: "table", title: "Table", symbolName: "tablecells", content: "| Column A | Column B |\n| --- | --- |\n| Value | Value |"),
        .init(id: "divider", title: "Divider", symbolName: "minus", content: "---"),
        .init(id: "image", title: "Image", symbolName: "photo", content: "![Describe image](assets/example.png)")
    ]
}

