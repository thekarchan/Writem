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
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.966, green: 0.951, blue: 0.928),
                            Color(red: 0.987, green: 0.982, blue: 0.968)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(Color.white.opacity(0.58))
                        .frame(width: 320, height: 320)
                        .blur(radius: 48)
                        .offset(x: -110, y: -180)

                    Circle()
                        .fill(Color(red: 0.82, green: 0.77, blue: 0.69).opacity(0.16))
                        .frame(width: 280, height: 280)
                        .blur(radius: 60)
                        .offset(x: 120, y: 210)
                }
            }
        }
        #endif
    }
}

#if os(iOS)
@available(iOS 18.0, *)
private struct WritemLaunchActionsView: View {
    var body: some View {
        VStack(spacing: 22) {
            paperPreview

            NewDocumentButton("New Draft") {
                MarkdownFileDocument()
            }
            .buttonStyle(.plain)
            .labelStyle(.titleOnly)
            .foregroundStyle(.clear)
            .frame(width: 164, height: 44)
            .overlay {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 13, weight: .semibold))
                    Text("New Draft")
                        .font(.system(size: 15, weight: .medium, design: .serif))
                }
                .foregroundStyle(Color(red: 0.28, green: 0.24, blue: 0.21))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.74))
            )
            .overlay {
                Capsule()
                    .stroke(Color(red: 0.56, green: 0.50, blue: 0.43).opacity(0.22), lineWidth: 0.8)
            }
        }
        .frame(maxWidth: 320, maxHeight: .infinity, alignment: .center)
        .padding(.top, 12)
    }

    private var paperPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.05))
                .blur(radius: 26)
                .scaleEffect(x: 0.92, y: 1.03)
                .offset(y: 20)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            Color(red: 0.992, green: 0.989, blue: 0.981)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.76))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(red: 0.57, green: 0.52, blue: 0.46).opacity(0.14), lineWidth: 0.8)
                }

            VStack(alignment: .leading, spacing: 14) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(red: 0.20, green: 0.18, blue: 0.17).opacity(0.88))
                    .frame(width: 122, height: 3)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(red: 0.48, green: 0.45, blue: 0.42).opacity(0.26))
                    .frame(width: 168, height: 2)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(red: 0.48, green: 0.45, blue: 0.42).opacity(0.22))
                    .frame(width: 156, height: 2)

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(red: 0.94, green: 0.93, blue: 0.91))
                    .frame(height: 56)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color(red: 0.66, green: 0.58, blue: 0.50).opacity(0.38))
                            .frame(width: 2)
                            .padding(.vertical, 10)
                            .padding(.leading, 12)
                    }

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(red: 0.93, green: 0.92, blue: 0.89))
                    .frame(height: 78)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
        }
        .frame(width: 232, height: 294)
    }
}
#endif
