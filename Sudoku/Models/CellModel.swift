import SwiftUI

struct CellModel: Identifiable {
    let id = UUID()
    var value: Int?
    var isEditable: Bool
    var notes: [Int] = []
    var isIncorrect: Bool = false
    var isSelected: Bool = false
    var isHighlighted: Bool = false

    var displayText: String {
        if let value {
            return "\(value)"
        } else if !notes.isEmpty {
            return notes.map { "\($0)" }.joined()
            // If you have a specific format for notes, adjust accordingly
        } else {
            return ""
        }
    }
}
