import SwiftUI
import UserNotifications


struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var hintVM = HintViewModel.shared
    
    let difficulty: Difficulty
    @StateObject var viewModel: SudokuViewModel
    @State private var showConfetti = false
    @State private var showArchipelago = false
    
    @ObservedObject var connectionManager = ArchipelagoConnectionManager.shared
    
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            } else {
                print("Notification authorization granted: \(granted)")
            }
        }
    }

    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        _viewModel = StateObject(wrappedValue: SudokuViewModel(difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            Color.background1.ignoresSafeArea()
            
            VStack {
                
                // Connection Status
                Button(action: {
                    showArchipelago = true })
                {
                    Text("\(connectionManager.connectionStatus)")
                        .font(.title3)
                        .foregroundColor(connectionManager.isConnected ? .green : .red)
                        .padding([.top, .horizontal])
                }
                
                Text("\(difficulty.rawValue) Puzzle")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .bold()
                    

                Text("\(viewModel.timerString)")
                    .font(.subheadline)
                    .padding(.bottom, 5)

                // Buttons positioned under the timer
                HStack {
                    Spacer()

                    // Pencil Mode Button
                    Button(action: {
                        viewModel.togglePencilMode()
                    }) {
                        VStack {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "pencil")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 15)
                                    .foregroundColor(.text1)
                                    .padding()
                                    .background(viewModel.isPencilMode ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(viewModel.isPencilMode ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                if viewModel.isPencilMode {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Text("ON")
                                                .font(.system(size: 8))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 8, y: -8)
                                }
                            }
                            Text("Pencil")
                                .font(.caption)
                                .foregroundColor(.text1)
                        }
                    }

                    Spacer()

                    // Check Button
                    Button(action: {
                        viewModel.checkPuzzle()
                    }) {
                        VStack {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 15)
                                .foregroundColor(.text1)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            Text("Check")
                                .font(.caption)
                                .foregroundColor(.text1)
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 5)

                SudokuGridView(cells: viewModel.cells, selectedCell: $viewModel.selectedCell, cages: viewModel.cages)
                    .padding()

                NumberPadView(action: { number in
                    viewModel.enterNumber(number)
                }, cells: viewModel.cells)
                .padding(.bottom, 40)
                .padding(.horizontal, 40)
            }
            
            if viewModel.isGameOver {
                Rectangle()
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                GameOverView(
                    isGameCompleted: $viewModel.isGameCompleted,
                    completionTime: $viewModel.timerString,
                    onNewGame: {
                        dismiss()
                    },
                    onContinue: {
                        viewModel.isGameOver = false
                    }
                )
            }
        }
        .alert(item: $hintVM.currentAlert) { alert in
            switch alert {
            case .newHint(let message):
                return Alert(
                    title: Text("New Hint"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"), action: {
                        hintVM.clearAlert()
                    })
                )
            case .noMoreHints:
                return Alert(
                    title: Text("All Hints Found!"),
                    message: Text("There are no more un-hinted locations. Disconnect from the server and join with another slot."),
                    dismissButton: .default(Text("OK"), action: {
                        hintVM.clearAlert()
                    })
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: customBackButton)
        .onAppear {
            viewModel.startGame(difficulty: difficulty)
        }
        .onReceive(viewModel.$isGameCompleted) { isCompleted in
            if isCompleted {
                showConfetti = true
                // Grant a reward based on puzzle difficulty
                if let client = ArchipelagoConnectionManager.shared.client, client.webSocket != nil {
                    client.grantReward(for: difficulty.rawValue)
                }
            }
        }
        .sheet(isPresented: $showArchipelago) {
            ArchipelagoConnectView()
        }
        .displayConfetti(isActive: $showConfetti)
    }
    
    private var customBackButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.body)
                .foregroundColor(.text1)
                .padding()
                .background(Color.background3)
                .clipShape(Circle())
        }
        
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
