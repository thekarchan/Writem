import Foundation

enum SampleDocument {
    static let content = """
    ---
    title: "Welcome to Writem"
    date: 2026-03-11
    tags: [swiftui, markdown, writing]
    draft: true
    slug: writem-welcome
    cover: assets/cover.png
    ---

    # Writem

    Writem starts from a single-column writing surface so the document, not the chrome, stays in focus.

    ## Why it exists

    - Keep Markdown files native and portable
    - Lower syntax friction for general writers
    - Give blog authors a clean pre-publish workflow

    > Markdown should stay editable as plain text, even when the interface feels polished.

    ## Code blocks

    ```swift
    struct WelcomeCard: View {
        var body: some View {
            Text("Hello, Writem")
                .padding()
        }
    }
    ```

    ## Publish checklist

    Write in `Write`, inspect in `Read`, and validate in the `Preflight` panel before exporting or publishing.
    """
}

