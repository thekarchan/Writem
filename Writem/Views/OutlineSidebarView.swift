import SwiftUI

struct OutlineSidebarView: View {
    let items: [OutlineItem]
    let issues: [PreflightIssue]
    let onSelect: (OutlineItem) -> Void

    private var errorCount: Int {
        issues.filter { $0.severity == .error }.count
    }

    private var warningCount: Int {
        issues.filter { $0.severity == .warning }.count
    }

    var body: some View {
        List {
            Section("Structure") {
                if items.isEmpty {
                    Text("Add Markdown headings to generate an outline.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(items) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.25))
                                    .frame(width: 8, height: 8)
                                Text(item.title)
                                    .lineLimit(1)
                            }
                            .padding(.leading, CGFloat(max(item.level - 1, 0)) * 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Checks") {
                Label("\(errorCount) errors", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(errorCount == 0 ? Color.secondary : Color.red)
                Label("\(warningCount) warnings", systemImage: "exclamationmark.circle")
                    .foregroundStyle(warningCount == 0 ? Color.secondary : Color.orange)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Outline")
    }
}
