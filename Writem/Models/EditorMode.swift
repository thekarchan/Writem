import Foundation

enum EditorMode: String, CaseIterable, Identifiable {
    case writing = "Write"
    case reading = "Read"
    case source = "Source"

    var id: Self { self }

    var symbolName: String {
        switch self {
        case .writing:
            return "square.and.pencil"
        case .reading:
            return "book.closed"
        case .source:
            return "chevron.left.forwardslash.chevron.right"
        }
    }
}

