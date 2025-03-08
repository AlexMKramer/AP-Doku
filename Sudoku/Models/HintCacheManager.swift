import Foundation

final class HintCacheManager {
    static let shared = HintCacheManager()
    
    // The key for UserDefaults
    private let cacheKey = "PendingHints"
    
    // In-memory cache of pending hints (each is a dictionary)
    private(set) var pendingHints: [[String: Any]] = []
    
    private init() {
        load()
    }
    
    /// Adds a hint to the cache and saves it.
    func addHints(_ hints: [[String: Any]]) {
        pendingHints.append(contentsOf: hints)
        save()
    }
    
    /// Dispatch pending hints by sending them via the WebSocket client.
    /// This function should be called once the client has reconnected.
    func dispatchPendingHints() {
        guard let client = ArchipelagoConnectionManager.shared.client, client.webSocket != nil else {
            print("No active WebSocket to dispatch hints.")
            return
        }
        
        for hint in pendingHints {
            // Check that the hint's intended recipient matches the connected client's credentials.
            if let hintName = hint["name"] as? String,
               let hintPassword = hint["password"] as? String,
               hintName == client.slotName && hintPassword == client.password {
                // Dispatch this hint.
                client.send(payload: [hint])
            } else {
                print("Skipping hint due to mismatched credentials: \(hint)")
            }
        }
        
        clear()
    }
    
    /// Clears the pending hints cache.
    func clear() {
        pendingHints.removeAll()
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
    
    /// Persists the pending hints to UserDefaults.
    private func save() {
        do {
            let data = try JSONSerialization.data(withJSONObject: pendingHints, options: [])
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            print("Error saving pending hints: \(error)")
        }
    }
    
    /// Loads the pending hints from UserDefaults.
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }
        do {
            if let array = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                pendingHints = array
            }
        } catch {
            print("Error loading pending hints: \(error)")
        }
    }
}
