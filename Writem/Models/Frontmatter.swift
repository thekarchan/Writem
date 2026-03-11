import Foundation

struct FrontmatterField: Identifiable, Equatable {
    let id: UUID
    var key: String
    var value: String

    init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

struct Frontmatter: Equatable {
    var title: String = ""
    var date: String = ""
    var tags: [String] = []
    var draft: Bool = false
    var slug: String = ""
    var cover: String = ""
    var customFields: [FrontmatterField] = []

    static let empty = Frontmatter()
}

