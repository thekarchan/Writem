import Foundation

struct OutlineItem: Identifiable, Hashable {
    let lineNumber: Int
    let level: Int
    let title: String

    var id: Int { lineNumber }
}

