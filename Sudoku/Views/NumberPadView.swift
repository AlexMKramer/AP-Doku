import SwiftUI

struct NumberPadView: View {
    let action: (Int?) -> Void
    let cells: [CellModel] // New property
    let numbers = Array(1...9)
    let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(numbers, id: \.self) { number in
                // Count the occurrences of this number in the puzzle.
                let count = cells.filter { $0.value == number }.count
                Button(action: {
                    action(number)
                }) {
                    Text("\(number)")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .font(.title)
                        .background(count >= 9 ? Color.gray : Color.accentColor.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            // Delete button remains unchanged
            Button(action: {
                action(nil) // Passing nil to indicate deletion
            }) {
                Image(systemName: "delete.left")
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .font(.title)
                    .background(Color.red.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}
