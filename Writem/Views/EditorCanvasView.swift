import SwiftUI

struct EditorCanvasView: View {
    @Binding var text: String

    let mode: EditorMode
    let lineWidth: CGFloat
    let documentURL: URL?
    let jumpToLine: Int?
    let onDropImageFiles: ([URL]) -> Bool

    @State private var isImageDropTarget = false

    var body: some View {
        Group {
            switch mode {
            case .reading:
                HStack {
                    Spacer(minLength: 0)
                    MarkdownPreviewView(text: text, jumpToLine: jumpToLine, documentURL: documentURL)
                        .frame(maxWidth: lineWidth, maxHeight: .infinity)
                        .padding(.vertical, 30)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
            case .writing:
                centeredEditor(font: .system(size: 19, weight: .regular, design: .serif))
            case .source:
                centeredEditor(font: .system(size: 15, weight: .regular, design: .monospaced))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .dropDestination(for: URL.self) { items, _ in
            onDropImageFiles(items)
        } isTargeted: { isTargeted in
            isImageDropTarget = isTargeted
        }
        .overlay(alignment: .topTrailing) {
            if isImageDropTarget {
                Label("Drop image to import into assets", systemImage: "photo.badge.plus")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.92))
                    )
                    .foregroundStyle(.white)
                    .padding(.top, 18)
                    .padding(.trailing, 24)
            }
        }
    }

    private func centeredEditor(font: Font) -> some View {
        HStack {
            Spacer(minLength: 0)
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(font)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.86))
                        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
                )
                .frame(maxWidth: lineWidth, maxHeight: .infinity)
                .padding(.vertical, 28)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }
}
