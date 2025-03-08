import SwiftUI

struct SudokuGridView: View {
    let cells: [CellModel]
    @Binding var selectedCell: CellModel?
    
    /// Optional list of cages (used for Killer mode)
    let cages: [KillerCage]?
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { col in
                        let index = row * 9 + col
                        if let cell = cells[safe: index] {
                            CellView(cell: cell,
                                     row: row,
                                     col: col,
                                     killerCage: cageForCell(row: row, col: col))
                                .onTapGesture {
                                    selectedCell = cell
                                }
                                .overlay(
                                    Rectangle()
                                        .stroke(lineWidth: getBorderWidth(row: row, col: col))
                                        .foregroundColor(.text1)
                                )
                        } else {
                            EmptyCellView(row: row, col: col)
                                .overlay(
                                    Rectangle()
                                        .stroke(lineWidth: getBorderWidth(row: row, col: col))
                                        .foregroundColor(.text1)
                                )
                        }
                    }
                }
            }
        }
    }
    
    private func getBorderWidth(row: Int, col: Int) -> CGFloat {
        var width: CGFloat = 0.5
        
        if col % 3 == 0 {
            width = 1.5 // Left border
        }
        if col == 8 {
            width = 1.5 // Right border
        }
        if row % 3 == 0 {
            width = max(width, 1.5) // Top border
        }
        if row == 8 {
            width = max(width, 1.5) // Bottom border
        }
        
        return width
    }
    
    /// Returns the cage that contains the cell at (row, col), if any.
    private func cageForCell(row: Int, col: Int) -> KillerCage? {
        guard let cages = cages else { return nil }
        for cage in cages {
            if cage.cells.contains(where: { $0.row == row && $0.col == col }) {
                return cage
            }
        }
        return nil
    }
}
