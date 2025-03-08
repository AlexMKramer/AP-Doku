import Foundation

/// Represents a cage for Killer mode.
/// Cells are represented by their (row, col) positions.
struct KillerCage {
    let cells: [(row: Int, col: Int)]
    let sum: Int
}
