import SwiftUI

struct CellView: View {
    let cell: CellModel
    let row: Int
    let col: Int
    /// If non‑nil, this cell belongs to a Killer cage.
    let killerCage: KillerCage?
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(cellBackgroundColor())
            
            if let value = cell.value {
                Text("\(value)")
                    .foregroundColor(cell.isIncorrect ? .red : .text1)
                    .font(.system(size: 24))
                    .fontWeight(cell.isEditable ? .thin : .bold)
            } else {
                if !cell.notes.isEmpty {
                    NotesGridView(notes: cell.notes)
                }
            }
        }
        .frame(width: 42, height: 42)
        .overlay(borderOverlay)
        .overlay(killerBorderOverlay)
        .border(cell.isSelected ? Color.accentColor : .clear, width: cell.isSelected ? 2 : 0)
    }
    
    private func cellBackgroundColor() -> Color {
        if cell.isSelected {
            return Color.accentColor.opacity(0.4)
        } else if cell.isHighlighted {
            return Color.cellHighlight
        } else {
            return Color.background1
        }
    }
    
    var borderOverlay: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            let topWidth: CGFloat = (row % 3 == 0) ? 2 : 0.5
            let bottomWidth: CGFloat = (row == 8) ? 2 : 0.5
            let leftWidth: CGFloat = (col % 3 == 0) ? 2 : 0.5
            let rightWidth: CGFloat = (col == 8) ? 2 : 0.5
            
            ZStack {
                Rectangle()
                    .frame(height: topWidth)
                    .foregroundColor(.text1)
                    .position(x: width / 2, y: topWidth / 2)
                Rectangle()
                    .frame(height: bottomWidth)
                    .foregroundColor(.text1)
                    .position(x: width / 2, y: height - bottomWidth / 2)
                Rectangle()
                    .frame(width: leftWidth)
                    .foregroundColor(.text1)
                    .position(x: leftWidth / 2, y: height / 2)
                Rectangle()
                    .frame(width: rightWidth)
                    .foregroundColor(.text1)
                    .position(x: width - rightWidth / 2, y: height / 2)
            }
        }
        .clipped()
    }
    
    var killerBorderOverlay: some View {
        GeometryReader { geometry in
            if let cage = killerCage, cage.cells.contains(where: { $0.row == row && $0.col == col }) {
                let width = geometry.size.width
                let height = geometry.size.height
                // For each side, if the adjacent cell is not in the cage, mark that side as a boundary.
                let drawTop = !cage.cells.contains(where: { $0.row == row - 1 && $0.col == col })
                let drawBottom = !cage.cells.contains(where: { $0.row == row + 1 && $0.col == col })
                let drawLeft = !cage.cells.contains(where: { $0.row == row && $0.col == col - 1 })
                let drawRight = !cage.cells.contains(where: { $0.row == row && $0.col == col + 1 })
                
                ZStack {
                    if drawTop {
                        Rectangle()
                            .frame(height: 3)
                            .foregroundColor(.red)
                            .position(x: width / 2, y: 1.5)
                    }
                    if drawBottom {
                        Rectangle()
                            .frame(height: 3)
                            .foregroundColor(.red)
                            .position(x: width / 2, y: height - 1.5)
                    }
                    if drawLeft {
                        Rectangle()
                            .frame(width: 3)
                            .foregroundColor(.red)
                            .position(x: 1.5, y: height / 2)
                    }
                    if drawRight {
                        Rectangle()
                            .frame(width: 3)
                            .foregroundColor(.red)
                            .position(x: width - 1.5, y: height / 2)
                    }
                    
                    // If this is the top-left cell of the cage, display the cage sum.
                    if isTopLeftCell(of: cage) {
                        Text("\(cage.sum)")
                            .font(.system(size: 8))
                            .foregroundColor(.red)
                            .padding(2)
                            .background(Color.white.opacity(0.7))
                            .position(x: 10, y: 10)
                    }
                }
            } else {
                EmptyView()
            }
        }
    }
    
    func isTopLeftCell(of cage: KillerCage) -> Bool {
        let minRow = cage.cells.map { $0.row }.min() ?? row
        let minCol = cage.cells.filter { $0.row == minRow }.map { $0.col }.min() ?? col
        return row == minRow && col == minCol
    }
}
