import SwiftUI

struct EditorCanvasView: View {
    @Binding var text: String

    let lineWidth: CGFloat
    let onDropImageFiles: ([URL]) -> Bool

    @State private var isImageDropTarget = false
    @FocusState private var isEditorFocused: Bool

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
                isEditorFocused = true
            }
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

    private var centeredEditor: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 0)
            TextEditor(text: $text)
                .focused($isEditorFocused)
                .scrollContentBackground(.hidden)
                .font(.system(size: 17, weight: .regular, design: .default))
                .foregroundStyle(Color(red: 0.14, green: 0.14, blue: 0.13))
                .padding(.horizontal, 6)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                )
                .frame(maxWidth: lineWidth, maxHeight: .infinity)
                .padding(.top, 28)
                .padding(.bottom, 22)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
    }
}
