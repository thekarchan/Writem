import SwiftUI

@main
struct WritemApp: App {
    @StateObject private var settings = EditorSettingsStore()

    @SceneBuilder
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownFileDocument()) { file in
            EditorRootView(document: file.$document, fileURL: file.fileURL)
                .environmentObject(settings)
        }

        #if os(iOS)
        if #available(iOS 18.0, *) {
            DocumentGroupLaunchScene("Writem") {
                WritemLaunchActionsView()
                    .environmentObject(settings)
            } background: {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.91, blue: 0.86),
                        Color(red: 0.99, green: 0.98, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        #endif
    }
}

#if os(iOS)
@available(iOS 18.0, *)
private struct WritemLaunchActionsView: View {
    var body: some View {
        VStack(spacing: 14) {
            NewDocumentButton("Create Document") {
                MarkdownFileDocument()
            }
            .buttonStyle(.plain)
            .labelStyle(.titleOnly)
            .overlay {
                Text("Create Document")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
            .foregroundStyle(.white)
            .background(
                Capsule()
                    .fill(Color(red: 0.78, green: 0.42, blue: 0.28))
            )

            Text("This launch action uses the app's document scene directly instead of the generated iPhone/iPad create flow.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: 320)
    }
}
#endif
