import SwiftUI
import GameKit
import UserNotifications

extension Difficulty {
    var color: Color {
        switch self {
        case .easy:
            return Color(.sRGB, red: 144/255, green: 208/255, blue: 144/255)
        case .medium:
            return Color(.sRGB, red: 236/255, green: 228/255, blue: 148/255)
        case .hard:
            return Color(.sRGB, red: 220/255, green: 164/255, blue: 124/255)
        case .killer:
            return Color(.sRGB, red: 204/255, green: 115/255, blue: 131/255)
        }
    }
}

struct HomeView: View {
    @StateObject var hintVM = HintViewModel.shared

    @State private var showHelpScreen = false
    @State private var showArchipelago = false
    @State private var leaderboardID = ""
    
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

    var body: some View {
        NavigationView {
            ZStack {
                Color.background1.ignoresSafeArea()
                
                // help button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showHelpScreen = true
                        }) {
                            Image(systemName: "questionmark")
                                .font(.callout)
                                .bold()
                                .foregroundColor(.text1)
                                .padding()
                                .background(Color(.sRGB, red: 204/255, green: 148/255, blue: 196/255))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
                
                // Archipelago button
                VStack {
                    HStack {
                        Button(action: {
                            showArchipelago = true
                        }) {
                            Image(systemName: "wifi")
                                .font(.callout)
                                .bold()
                                .foregroundColor(.text1)
                                .padding()
                                .background(Color(.sRGB, red: 115/255, green: 124/255, blue: 188/255))
                                .clipShape(Circle())
                        }
                        .padding()
                        Spacer()

                    }
                    Spacer()
                }
                
                VStack(spacing: 20) {
                    Spacer()
                    // Archipelago Icon Image above title text
                    ZStack {
                        Image("APLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                    }
                    .frame(width: 100, height: 100)
                    .cornerRadius(15)
                    .rotationEffect(.degrees(-15))
                    .padding(.top, 40)
                    .shadow(color: .shadow, radius: 8, x: 2, y: 3)

                    Text("AP Doku")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding()

                    // Difficulty buttons
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        NavigationLink(destination: GameView(difficulty: difficulty)) {
                            Text(difficulty.rawValue)
                                .shadow(color: .black.opacity(0.5), radius: 8)
                                .font(.title2)
                                .frame(width: 200, height: 50)
                                .background(difficulty.color.opacity(1))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                    Spacer()
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
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showHelpScreen) {
                HelpScreenView()
            }
            .sheet(isPresented: $showArchipelago) {
                ArchipelagoConnectView()
            }
        }
        .onAppear {
            requestNotificationAuthorization()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Wrapper for the authentication view controller
struct AuthenticationViewControllerWrapper: UIViewControllerRepresentable {
    let authViewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        return authViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

enum Difficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case killer = "Killer"
}

#Preview {
    HomeView()
}
