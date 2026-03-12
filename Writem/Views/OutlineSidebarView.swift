import SwiftUI

struct OutlineSidebarView: View {
    @Environment(\.colorScheme) private var colorScheme

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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Structure")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    if items.isEmpty {
                        Text("Add Markdown headings to generate an outline.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.25))
                                        .frame(width: 7, height: 7)

                                    Text(item.title)
                                        .font(.system(size: 13))
                                        .lineLimit(1)
                                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.84) : Color.black.opacity(0.72))
                                }
                                .padding(.leading, CGFloat(max(item.level - 1, 0)) * 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Checks")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Label("\(errorCount) errors", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(errorCount == 0 ? Color.secondary : Color.red)

                    Label("\(warningCount) warnings", systemImage: "exclamationmark.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(warningCount == 0 ? Color.secondary : Color.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }
}
