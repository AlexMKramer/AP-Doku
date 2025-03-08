import Foundation
import SwiftUI

final class ArchipelagoConnectionManager: ObservableObject {
    static let shared = ArchipelagoConnectionManager()
    
    @Published var connectionStatus: String = "Not Connected"
    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    
    // This flag indicates the user has requested a connection.
    @Published var shouldAutoReconnect: Bool = false
    @Published var client: HintGameWebSocketClient?
    
    // Timer that checks the connection every 15 seconds.
    private var connectionTimer: Timer?
    
    private init() {}
    
    func storeCredentials(ip: String, slotName: String, password: String) {
        let defaults = UserDefaults.standard
        defaults.set(ip, forKey: "ipAddress")
        defaults.set(slotName, forKey: "slotName")
        defaults.set(password, forKey: "password")
    }
    
    func connect(ip: String, port: Int, slotName: String, password: String) {
        // If already connected or in the process of connecting, do nothing.
        if isConnected || isConnecting { return }
        
        DispatchQueue.main.async {
            // Mark that the user wants to be connected.
            self.shouldAutoReconnect = true
            
            // Cache credentials.
            self.storeCredentials(ip: "\(ip):\(port)", slotName: slotName, password: password)
            self.isConnecting = true
            self.connectionStatus = "Connecting..."
            self.isConnected = false
        }
        
        let newClient = HintGameWebSocketClient(ip: ip, port: port, slotName: slotName, password: password)
        
        newClient.onConnected = { [weak self] in
            DispatchQueue.main.async {
                self?.connectionStatus = "Connected!"
                self?.isConnected = true
                self?.isConnecting = false
                newClient.isOpen = true
                print("New connection established.")
                
                // Attempt to send any cached hints now that we are connected.
                HintCacheManager.shared.dispatchPendingHints()
            }
        }
        
        newClient.onDisconnected = { [weak self] in
            DispatchQueue.main.async {
                self?.connectionStatus = "Disconnected"
                self?.isConnected = false
                newClient.isOpen = false
                print("Connection disconnected.")
            }
        }
        
        client = newClient
        newClient.connect()
        
        // Start monitoring the connection.
        startConnectionMonitoring()
        
        // If still connecting after 15 seconds, mark a timeout.
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            guard let self = self else { return }
            if self.isConnecting {
                self.connectionStatus = "Connection timed out"
                self.isConnecting = false
                self.objectWillChange.send()
                print("Connection timed out.")
            }
        }
    }
    
    // Disconnect and stop auto-reconnect.
    func disconnect() {
        DispatchQueue.main.async {
            self.shouldAutoReconnect = false
            self.client?.webSocket?.cancel(with: .normalClosure, reason: nil)
            self.client = nil
            self.connectionStatus = "Not Connected"
            self.isConnected = false
            self.isConnecting = false
            self.connectionTimer?.invalidate()
            self.connectionTimer = nil
            self.objectWillChange.send()  // Force observers to update
        }
    }
    
    // Attempt to reconnect using cached credentials.
    func attemptReconnect() {
        guard shouldAutoReconnect else {
            print("Auto-reconnect not enabled.")
            return
        }
        
        // If client is nil or not open, attempt a reconnect.
        if client == nil || client?.isOpen == false {
            let defaults = UserDefaults.standard
            guard let ipString = defaults.string(forKey: "ipAddress"),
                  let slotName = defaults.string(forKey: "slotName"),
                  let password = defaults.string(forKey: "password") else {
                print("No cached credentials to reconnect.")
                return
            }
            
            let components = ipString.split(separator: ":")
            guard components.count == 2,
                  let port = Int(components[1]) else {
                print("Invalid cached IP format.")
                return
            }
            
            print("Attempting to reconnect with \(ipString), slot: \(slotName)")
            // Immediately update the UI to indicate reconnection is in progress.
            DispatchQueue.main.async {
                self.connectionStatus = "Connecting..."
                self.isConnected = false
                self.isConnecting = true
            }
            connect(ip: String(components[0]), port: port, slotName: slotName, password: password)
        }
    }
    
    // Starts a timer that sends a ping every 15 seconds to verify the connection.
    private func startConnectionMonitoring() {
        DispatchQueue.main.async {
            self.connectionTimer?.invalidate()
            self.connectionTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] timer in
                guard let self = self else { timer.invalidate(); return }
                if self.shouldAutoReconnect {
                    if let client = self.client {
                        client.sendPing { error in
                            if let error = error {
                                print("Ping error: \(error) – attempting reconnect.")
                                self.attemptReconnect()
                            } else {
                                // Ping succeeded; update UI if not already marked as connected.
                                DispatchQueue.main.async {
                                    if !self.isConnected {
                                        self.connectionStatus = "Connected!"
                                        self.isConnected = true
                                        self.isConnecting = false
                                        self.objectWillChange.send()
                                        print("Ping successful; connection restored.")
                                    }
                                }
                            }
                        }
                    } else {
                        self.attemptReconnect()
                    }
                }
            }
        }
    }
}
