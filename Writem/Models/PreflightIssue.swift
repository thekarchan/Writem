import Foundation

struct PreflightIssue: Identifiable, Hashable {
    enum Severity: String, Hashable {
        case error
        case warning

        var title: String {
            switch self {
            case .error:
                return "Error"
            case .warning:
                return "Warning"
            }
        }
    }

    let id = UUID()
    let severity: Severity
    let title: String
    let message: String
    let lineNumber: Int?
}

