import SwiftUI

struct NotesGridView: View {
    let notes: [Int]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { row in
                HStack(spacing: 0) {
                    ForEach(1..<4) { col in
                        let number = row * 3 + col
                        Text(notes.contains(number) ? "\(number)" : "")
                            .font(.system(size: 11))
                            .frame(width: 13, height: 13, alignment: .center)
                    }
                }
            }
        }
    }
}
