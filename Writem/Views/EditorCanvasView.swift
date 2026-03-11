import SwiftUI

struct EditorCanvasView: View {
    @Binding var text: String

    let mode: EditorMode
    let lineWidth: CGFloat
    let jumpToLine: Int?

    var body: some View {
        Group {
            switch mode {
            case .reading:
                HStack {
                    Spacer(minLength: 0)
                    MarkdownPreviewView(text: text, jumpToLine: jumpToLine)
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
