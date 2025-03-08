import SwiftUI

struct ArchipelagoConnectView: View {
    // Load cached credentials, or use default values.
    @State private var ipAddress: String = UserDefaults.standard.string(forKey: "ipAddress") ?? "archipelago.gg:38281"
    @State private var slotName: String = UserDefaults.standard.string(forKey: "slotName") ?? ""
    @State private var password: String = UserDefaults.standard.string(forKey: "password") ?? ""
    
    @ObservedObject var connectionManager = ArchipelagoConnectionManager.shared
    @StateObject var hintVM = HintViewModel.shared
    
    // A dummy state property to force a view update.
    @State private var forceUpdate: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Label("Archipelago Settings", systemImage: "")
                        .font(.title)
                        .bold(true)
                        .foregroundColor(.primary)
                        .offset(y: -260)
                        .padding(.top, 100)
                    
                    // Connection Status
                    Label(connectionManager.connectionStatus, systemImage: "")
                        .font(.title)
                        .foregroundColor(connectionManager.isConnected ? .green : .red)
                        .offset(y: -275)
                }
                
                VStack {
                    TextField("Enter IP Address", text: $ipAddress)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.all, 2)
                        .frame(width: 300, height: 37)
                        .background(Color.background2)
                        .cornerRadius(5)
                    
                    TextField("Slot Name", text: $slotName)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.all, 2)
                        .frame(width: 300, height: 37)
                        .background(Color.background2)
                        .cornerRadius(5)
                    
                    SecureField("Password", text: $password)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.all, 2)
                        .frame(width: 300, height: 37)
                        .background(Color.background2)
                        .cornerRadius(5)
                    
                    // Connect / Disconnect / Cancel Button
                    Button(action: {
                        buttonAction()
                    }) {
                        Text(buttonLabel())
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 150, height: 50)
                            .background(connectionManager.isConnected ? .gray : .blue)
                            .cornerRadius(25)
                            .shadow(radius: 5)
                    }
                    .padding()
                }
                // Use the dummy state as an id so that toggling it forces a refresh.
                .id(forceUpdate)
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
            .onReceive(connectionManager.$connectionStatus) { newStatus in
                print("Connection status updated: \(newStatus)")
                // Toggle dummy state to force a view update.
                forceUpdate.toggle()
            }
        }
    }
    
    func buttonLabel() -> String {
        if connectionManager.isConnected {
            return "Disconnect"
        } else if connectionManager.isConnecting {
            return "Cancel"
        } else {
            return "Connect"
        }
    }
    
    func buttonAction() {
        if connectionManager.isConnected || connectionManager.isConnecting {
            connectionManager.disconnect()
            // Optionally reset local state to allow re-editing:
            ipAddress = UserDefaults.standard.string(forKey: "ipAddress") ?? "archipelago.gg:38281"
            // Clear slot name and password if desired:
            slotName = UserDefaults.standard.string(forKey: "slotName") ?? ""
            password = UserDefaults.standard.string(forKey: "password") ?? ""
        } else {
            let components = ipAddress.split(separator: ":")
            guard components.count == 2, let port = Int(components[1]) else {
                connectionManager.connectionStatus = "Invalid IP format"
                return
            }
            connectionManager.connect(ip: String(components[0]), port: port, slotName: slotName, password: password)
        }
    }
}

struct ArchipelagoConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ArchipelagoConnectView()
    }
}
