import SwiftUI

struct FrontmatterPanelView: View {
    @Binding var frontmatter: Frontmatter

    let onApply: (Frontmatter) -> Void

    @State private var newKey: String = ""
    @State private var newValue: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                field(title: "Title", text: $frontmatter.title)
                field(title: "Date", text: $frontmatter.date, prompt: "2026-03-11")
                field(title: "Slug", text: $frontmatter.slug)
                field(title: "Cover", text: $frontmatter.cover, prompt: "assets/cover.png")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.subheadline.weight(.semibold))
                    TextField(
                        "writing, markdown, swiftui",
                        text: Binding(
                            get: { frontmatter.tags.joined(separator: ", ") },
                            set: { value in
                                frontmatter.tags = value
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty }
                                onApply(frontmatter)
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                }

                Toggle(isOn: Binding(
                    get: { frontmatter.draft },
                    set: { newValue in
                        frontmatter.draft = newValue
                        onApply(frontmatter)
                    }
                )) {
                    Text("Draft")
                        .font(.subheadline.weight(.semibold))
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom fields")
                        .font(.subheadline.weight(.semibold))

                    ForEach($frontmatter.customFields) { $field in
                        HStack(spacing: 12) {
                            TextField("key", text: $field.key)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: field.key) { _, _ in
                                    onApply(frontmatter)
                                }
                            TextField("value", text: $field.value)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: field.value) { _, _ in
                                    onApply(frontmatter)
                                }
                            Button(role: .destructive) {
                                frontmatter.customFields.removeAll { $0.id == field.id }
                                onApply(frontmatter)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        TextField("new key", text: $newKey)
                            .textFieldStyle(.roundedBorder)
                        TextField("new value", text: $newValue)
                            .textFieldStyle(.roundedBorder)
                        Button("Add") {
                            let key = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !key.isEmpty else {
                                return
                            }
                            frontmatter.customFields.append(.init(key: key, value: newValue))
                            newKey = ""
                            newValue = ""
                            onApply(frontmatter)
                        }
                    }
                }
            }
        }
    }

    private func field(title: String, text: Binding<String>, prompt: String = "") -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            TextField(prompt, text: text)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text.wrappedValue) { _, _ in
                    onApply(frontmatter)
                }
        }
    }
}
