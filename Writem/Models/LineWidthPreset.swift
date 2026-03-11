import SwiftUI

enum LineWidthPreset: String, CaseIterable, Identifiable {
    case narrow
    case comfortable
    case wide

    var id: Self { self }

    var title: String {
        switch self {
        case .narrow:
            return "Narrow"
        case .comfortable:
            return "Comfort"
        case .wide:
            return "Wide"
        }
    }

    var width: CGFloat {
        switch self {
        case .narrow:
            return 620
        case .comfortable:
            return 760
        case .wide:
            return 920
        }
    }
}

