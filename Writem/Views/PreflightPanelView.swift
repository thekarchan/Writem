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
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preflight")
                            .font(.title3.weight(.bold))
                        Text("Run these checks before exporting or publishing.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("\(errors) errors", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(errors == 0 ? Color.secondary : Color.red)
                    Label("\(warnings) warnings", systemImage: "exclamationmark.circle")
                        .foregroundStyle(warnings == 0 ? Color.secondary : Color.orange)
                }

                if issues.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("No findings in the current document.", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                        Text("This is the baseline check set. Later iterations can add filesystem-aware image validation and export checks.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
}
