import SwiftUI

@main
struct WritemApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownFileDocument()) { file in
            EditorRootView(document: file.$document)
        }
    }
}

