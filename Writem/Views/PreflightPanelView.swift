import SwiftUI

struct PreflightPanelView: View {
    let issues: [PreflightIssue]
    let onSelect: (PreflightIssue) -> Void

    private var errors: Int {
        issues.filter { $0.severity == .error }.count
    }

    private var warnings: Int {
        issues.filter { $0.severity == .warning }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    summaryChip(
                        title: "\(errors) errors",
                        symbol: "exclamationmark.triangle.fill",
                        color: errors == 0 ? .secondary : .red
                    )
                    summaryChip(
                        title: "\(warnings) warnings",
                        symbol: "exclamationmark.circle",
                        color: warnings == 0 ? .secondary : .orange
                    )
                    Spacer()
                }

                if issues.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("No findings in the current document.", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.green.opacity(0.10))
                    )
                } else {
                    ForEach(issues) { issue in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: issue.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(issue.severity == .error ? .red : .orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(issue.title)
                                    .font(.headline)
                                Text(issue.message)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let lineNumber = issue.lineNumber {
                                    Text("Line \(lineNumber)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if issue.lineNumber != nil {
                                Button("Jump") {
                                    onSelect(issue)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.72))
                        )
                    }
                }
            }
        }
    }

    private func summaryChip(title: String, symbol: String, color: Color) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.68))
            )
    }
}
