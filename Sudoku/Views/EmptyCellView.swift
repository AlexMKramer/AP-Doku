import SwiftUI

struct EmptyCellView: View {
    let row: Int
    let col: Int

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 35, height: 35)
            .overlay(borderOverlay)
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
                // Top border
                Rectangle()
                    .frame(height: topWidth)
                    .foregroundColor(.text1)
                    .position(x: width / 2, y: topWidth / 2)
                // Bottom border
                Rectangle()
                    .frame(height: bottomWidth)
                    .foregroundColor(.text1)
                    .position(x: width / 2, y: height - bottomWidth / 2)
                // Left border
                Rectangle()
                    .frame(width: leftWidth)
                    .foregroundColor(.text1)
                    .position(x: leftWidth / 2, y: height / 2)
                // Right border
                Rectangle()
                    .frame(width: rightWidth)
                    .foregroundColor(.text1)
                    .position(x: width - rightWidth / 2, y: height / 2)
            }
        }
        .clipped()
    }
}

