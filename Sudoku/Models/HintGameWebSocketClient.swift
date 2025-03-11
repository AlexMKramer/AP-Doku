import Foundation
import UserNotifications

extension HintGameWebSocketClient {
    // Define difficulty probabilities.
    static var difficultyProbs: [String: [Int: Double]] = [
        "Easy":   [1: 0.10, 0: 0.90, -1: 0.00],
        "Medium": [1: 0.40, 0: 0.60, -1: 0.00],
        "Killer": [1: 0.60, 0: 0.40, -1: 0.00],
        "Hard":   [1: 0.80, 0: 0.20, -1: 0.00]
    ]

    static func updateHintProbabilities(with newMapping: [String: [Int]]) {
        for (difficulty, values) in newMapping {
            // Ensure we have exactly three values.
            guard values.count == 3 else { continue }
            
            let progressionProb = Double(values[0]) / 100.0
            let everythingElseProb = Double(values[1]) / 100.0
            let noHintProb = Double(values[2]) / 100.0
            
            difficultyProbs[difficulty] = [1: progressionProb, 0: everythingElseProb, -1: noHintProb]
            print("Updated \(difficulty) probabilities: \(difficultyProbs[difficulty]!)")
        }
    }
    
    /// Returns a human‑readable string for the hint probabilities for a given difficulty.
    static func hintProbabilitiesString(for difficulty: String) -> String {
        guard let mapping = difficultyProbs[difficulty] else { return "N/A" }
        // Keys: 1: progression, 0: everything else, -1: no hint.
        let progression = mapping[1] ?? 0.0
        let nonProgression = mapping[0] ?? 0.0
        let noHint = mapping[-1] ?? 0.0
        // Multiply by 100 to get percentage values.
        let progressionPercent = Int(round(progression * 100))
        let nonProgressionPercent = Int(round(nonProgression * 100))
        let noHintPercent = Int(round(noHint * 100))
        return "\(progressionPercent) Prog, \(nonProgressionPercent) Non-prog, \(noHintPercent) No Hint"
    }
    
    /// Helper to retrieve the connected player's slot number from the slot list.
    func getConnectedSlotNumber() -> String? {
        // Assume the client’s slotName is the connected player's name.
        // Iterate over slotList and return the slot number for the matching entry.
        for slot in slotList {
            if let name = slot["name"] as? String,
               name == self.slotName,
               let number = slot["number"] as? String {
                return number
            }
        }
        return nil
    }
    
    /// Sends a packet to get existing hints for the given team and slot.
    func getAdminSettings() {
        let payload: [[String: Any]] = [[
            "cmd": "Get",
            "keys": ["APSudoku_Settings"],
            "password": password,
            "name": slotName,
            "version": ["build": 0, "class": "Version", "major": 0, "minor": 5],
            "tags": ["HintGame"],
            "items_handling": 0,
            "uuid": "",
            "game": "",
            "slot_data": true
        ]]
        send(payload: payload)
    }
    
    func setNotifySettingsUpdate() {
        
        /// SetNotify to listen to changes to the settings key
        let payload: [[String: Any]] = [[
            "cmd": "SetNotify",
            "keys": ["APSudoku_Settings"]
        ]]
        send(payload: payload)
    }
    
    /// Sends a local notification with the given message.
    func sendLocalNotification(with message: String) {
        // Ensure notification permissions have been granted elsewhere in your app.
        let content = UNMutableNotificationContent()
        content.title = "New Hint!"
        content.body = message
        content.sound = .default
        
        // Schedule the notification to fire almost immediately.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled: \(message)")
            }
        }
    }
    // Group rewards by their flag value.
    func groupRewards(rewards: [[String: Any]]) -> [Int: [[String: Any]]] {
        var grouped: [Int: [[String: Any]]] = [:]
        for reward in rewards {
            if let flag = reward["flags"] as? Int {
                grouped[flag, default: []].append(reward)
            }
        }
        return grouped
    }
    
    // Select a random reward based on difficulty using the new probability format.
    func getRandomReward(difficulty: String, rewards: [[String: Any]]) throws -> [String: Any] {
        // Group rewards into two groups: progression and everythingElse.
        var progressionRewards = [[String: Any]]()
        var everythingElseRewards = [[String: Any]]()
        
        for reward in rewards {
            if let flag = reward["flags"] as? Int {
                if flag == 1 {
                    progressionRewards.append(reward)
                } else {
                    everythingElseRewards.append(reward)
                }
            }
        }
        
        // Retrieve the new probability mapping.
        guard let probMap = HintGameWebSocketClient.difficultyProbs[difficulty] else {
            throw NSError(domain: "HintGameError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid difficulty provided"])
        }
        
        // Prepare arrays of keys and weights.
        let keys = Array(probMap.keys)
        let weights = keys.map { probMap[$0]! }
        let totalWeight = weights.reduce(0, +)
        let randomValue = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0
        var chosenKey: Int? = nil
        
        for (key, weight) in zip(keys, weights) {
            cumulative += weight
            if randomValue < cumulative {
                chosenKey = key
                break
            }
        }
        
        guard let chosenKey = chosenKey else {
            throw NSError(domain: "HintGameError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to choose a category"])
        }
        
        // If the no-hint chance is triggered, throw an error (or handle it as needed).
        if chosenKey == -1 {
            throw NSError(domain: "HintGameError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No hint triggered"])
        } else if chosenKey == 1 {
            // Prefer progression rewards.
            if !progressionRewards.isEmpty {
                return progressionRewards.randomElement()!
            } else if !everythingElseRewards.isEmpty {
                return everythingElseRewards.randomElement()!
            }
        } else if chosenKey == 0 {
            // Prefer everything else rewards.
            if !everythingElseRewards.isEmpty {
                return everythingElseRewards.randomElement()!
            } else if !progressionRewards.isEmpty {
                return progressionRewards.randomElement()!
            }
        }
        
        throw NSError(domain: "HintGameError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No available rewards in the pool"])
    }
    
    // Request a reward by selecting a reward location and then granting a hint.
    func grantReward(for difficulty: String) {
        // Make sure we have rewards (populated via earlier LocationInfo messages).
        guard !locationsProgression.isEmpty else {
            print("No rewards available to grant")
            return
        }
        if self.hintsEnabled == true {
            do {
                let reward = try getRandomReward(difficulty: difficulty, rewards: locationsProgression)
                if let location = reward["location"] as? String {
                    print("Granting reward for \(difficulty) difficulty at location: \(location)")
                    grantHint(for: location)
                }
            } catch {
                print("Error granting reward: \(error)")
            }
        } else {
            print("Hints are disabled for this server.")
            
        }
    }
    
    // Send the grant hint command.
    func grantHint(for location: String) {
        guard let intLocation = Int(location) else {
            print("Invalid location value: \(location)")
            return
        }
        let payload: [[String: Any]] = [[
            "cmd": "LocationScouts",
            "locations": [intLocation], // explicitly wrap in an array
            "create_as_hint": 1,
            "password": password,
            "name": slotName,
            "version": ["build": 0, "class": "Version", "major": 0, "minor": 5],
            "tags": ["HintGame"],
            "items_handling": 0,
            "uuid": "",
            "game": "",
            "slot_data": true
        ]]
        if let client = ArchipelagoConnectionManager.shared.client, client.webSocket != nil {
            send(payload: payload)
        } else {
            HintCacheManager.shared.addHints(payload)
        }
    }
    /// Sends a packet to get existing hints for the given team and slot.
    func getExistingHints(teamId: String, slotId: String) {
        let payload: [[String: Any]] = [[
            "cmd": "Get",
            "keys": ["_read_hints_\(teamId)_\(slotId)"],
            "password": password,
            "name": slotName,
            "version": ["build": 0, "class": "Version", "major": 0, "minor": 5],
            "tags": ["HintGame"],
            "items_handling": 0,
            "uuid": "",
            "game": "",
            "slot_data": true
        ]]
        send(payload: payload)
    }
    
    func checkHintProgressions(for locations: [String]) {
        // Convert each location from String to Int.
        let intLocations = locations.compactMap { Int($0) }
        let payload: [[String: Any]] = [[
            "cmd": "LocationScouts",
            "locations": intLocations,
            "create_as_hint": 0,
            "password": password,
            "name": slotName,
            "version": ["build": 0, "class": "Version", "major": 0, "minor": 5],
            "tags": ["HintGame"],
            "items_handling": 0,
            "uuid": "",
            "game": "",
            "slot_data": true
        ]]
        send(payload: payload)
    }
    
    /// Filters out any missing locations that have already been hinted.
    func cleanLocations() {
        missingLocations = missingLocations.filter { location in
            !hintedLocations.contains(location)
        }
    }
    
    /// Returns the team and slot numbers for the current slotName.
    func getTeamAndSlot() -> (team: String, slot: String)? {
        for entry in slotList {
            if let name = entry["name"] as? String, name == slotName,
               let number = entry["number"] as? String,
               let teamValue = entry["team"] {
                // Convert team to a String regardless of its type.
                let teamString = "\(teamValue)"
                return (teamString, number)
            }
        }
        return nil
    }
    
    /// Refreshes hint data:
    /// 1. Gets existing hints.
    /// 2. After 2 seconds, cleans the missing locations list.
    /// 3. For each remaining missing location, checks its progression.
    /// 4. Optionally prints the updated progression data.
    func refreshHintData(completion: @escaping () -> Void) {
        guard let (team, slot) = getTeamAndSlot() else {
            print("Slot info not found for \(slotName)")
            completion()
            return
        }
        
        // 1. Request the existing hinted locations.
        getExistingHints(teamId: team, slotId: slot)
        
        // 2. Wait 2 seconds to allow the server's response to arrive.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.cleanLocations()
            
            // Check if there are any missing (un-hinted) locations left.
            if self.missingLocations.isEmpty {
                // If not, notify the view model so the UI can show an alert.
                HintViewModel.shared.showNoMoreHints()
                completion()
            } else {
                
                // 3. Request progression data for all remaining missing locations at once.
                self.checkHintProgressions(for: self.missingLocations)
                
                // 4. Wait 5 seconds to let the progression responses process.
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    print("Updated Locations Progression: \(self.locationsProgression)")
                    // At this point your client has refreshed hint data for reward selection later.
                    completion()
                }
            }
        }
    }
    func getDataPackages(for games: [String]) {
        let payload: [[String: Any]] = [[
            "cmd": "GetDataPackage",
            "games": games,  // This should be an array of game names.
            "password": password,
            "name": slotName,
            "version": ["build": 0, "class": "Version", "major": 0, "minor": 5],
            "tags": ["HintGame"],
            "items_handling": 0,
            "uuid": "",
            "game": "",
            "slot_data": true
        ]]
        send(payload: payload)
    }

    /// Returns the player’s display name given a slot number (as String)
    func lookupPlayerName(for slotID: String) -> String? {
        // Iterate over slotList (which you populated in the "Connected" message)
        for slot in slotList {
            if let num = slot["number"] as? String,
               num == slotID,
               let name = slot["name"] as? String {
                return name
            }
        }
        return nil
    }

    /// Returns the game name for a given slot number.
    func lookupGameName(for slotID: String) -> String? {
        for slot in slotList {
            if let num = slot["number"] as? String,
               num == slotID,
               let game = slot["game"] as? String {
                return game
            }
        }
        return nil
    }

    // MARK: - Handling a Hint Packet

    /// Parses a PrintJSON packet for a hint, matches IDs to cached data,
    /// and constructs a human‑readable hint message.
    func handleHintMessage(msg: [String: Any]) {
        // Ensure this is a hint message.
        guard let type = msg["type"] as? String, type == "Hint" else {
            print("Not a hint message.")
            return
        }
        
        // Get the data array.
        guard let dataArray = msg["data"] as? [[String: Any]] else {
            print("No data array in hint message.")
            return
        }
        
        // Get the item dictionary.
        guard let itemDict = msg["item"] as? [String: Any] else {
            print("No item dictionary in hint message.")
            return
        }
        
        // Convert the item and location IDs to strings.
        let itemID: String? = {
            if let id = itemDict["item"] as? Int {
                return "\(id)"
            } else if let id = itemDict["item"] as? String {
                return id
            }
            return nil
        }()
        
        let locationID: String? = {
            if let id = itemDict["location"] as? Int {
                return "\(id)"
            } else if let id = itemDict["location"] as? String {
                return id
            }
            return nil
        }()
        
        // Extract player IDs from the data array.
        var playerIDs: [String] = []
        for element in dataArray {
            if let elemType = element["type"] as? String,
               elemType == "player_id",
               let text = element["text"] as? String {
                playerIDs.append(text)
            }
        }
        
        // Assume first player_id is the receiver and second is the sender.
        let receiverSlotID = playerIDs.first
        let senderSlotID = playerIDs.count > 1 ? playerIDs.last : nil
        
        // Lookup player names using your slot list.
        let senderName = lookupPlayerName(for: senderSlotID ?? "")
        let receiverName = lookupPlayerName(for: receiverSlotID ?? "")
        
        // Lookup game names from the slot list.
        let senderGame = lookupGameName(for: senderSlotID ?? "")
        let receiverGame = lookupGameName(for: receiverSlotID ?? "")
        
        // Look up the item name from the receiver's game cache.
        var itemName: String? = nil
        if let receiverGame = receiverGame,
           let dataCache = DataCacheManager.shared.datapackCache[receiverGame] {
            itemName = dataCache.itemIDToName[itemID ?? ""]
            if itemName == nil {
                print("Item name not found for id \(itemID ?? "nil") in receiver's game \(receiverGame)")
            }
        }
        
        // Look up the location name from the sender's game cache.
        var locationName: String? = nil
        if let senderGame = senderGame,
           let dataCache = DataCacheManager.shared.datapackCache[senderGame] {
            locationName = dataCache.locationIDToName[locationID ?? ""]
            if locationName == nil {
                print("Location name not found for id \(locationID ?? "nil") in sender's game \(senderGame)")
            }
        }
        
        // Build the final hint message.
        var message = ""
        if let receiverName = receiverName {
            message += "\(receiverName)'s "
        } else if let receiverSlotID = receiverSlotID {
            message += "\(receiverSlotID)'s "
        }
        if let itemName = itemName {
            message += "\(itemName) "
        } else if let itemID = itemID {
            message += "\(itemID) "
        }
        message += "is at "
        if let locationName = locationName {
            message += "\(locationName) "
        } else if let locationID = locationID {
            message += "\(locationID) "
        }
        message += "in "
        if let senderName = senderName {
            message += "\(senderName)'s World"
        } else if let senderSlotID = senderSlotID {
            message += "\(senderSlotID)'s World"
        }
        
        print("Parsed Hint Message: \(message)")
        HintViewModel.shared.showHint(message)
        
        
        // Optionally, if you still want to send a notification:
        if let connectedSlot = self.getConnectedSlotNumber(), let senderSlotID = senderSlotID, connectedSlot == senderSlotID {
            self.sendLocalNotification(with: message)
        }
    }
}
class HintGameWebSocketClient: NSObject {
    // In your WebSocket client class or extension
    var onHintReceived: ((String) -> Void)?
    
    var slotName: String
    var password: String
    var serverURL: URL
    var webSocket: URLSessionWebSocketTask?
    
    // Closure to notify connection status.
    var onConnected: (() -> Void)?
    var onDisconnected: (() -> Void)?
    
    // Tracks whether the socket is currently open.
    var isOpen: Bool = false
    
    // Other properties matching your Python globals.
    var allLocations: [String] = []
    var missingLocations: [String] = []
    var checkedLocations: [String] = []
    var slotList: [[String: Any]] = []
    var hintedLocations: [String] = []
    var locationsProgression: [[String: Any]] = []
    
    var hintsEnabled: Bool = true
    
    let session = URLSession(configuration: .default)
    
    // New initializer that accepts IP and port.
    init(ip: String, port: Int, slotName: String, password: String) {
        self.slotName = slotName
        self.password = password
        self.serverURL = URL(string: "ws://\(ip):\(port)")!
    }
    
    func connect() {
        webSocket = session.webSocketTask(with: serverURL)
        webSocket?.resume()
        sendConnectPacket()
        receiveMessages()
    }
    
    func send(payload: [[String: Any]]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)

                print("Sending packet: \(message)")
                webSocket?.send(message) { error in
                    if let error = error {
                        print("WebSocket sending error: \(error)")
                    }
                }
            }
        } catch {
            print("Error encoding JSON: \(error)")
        }
    }
    
    // Send the initial connection payload.
    func sendConnectPacket() {
        let payload: [[String: Any]] = [[
            "cmd": "Connect",
            "password": password,
            "name": slotName,
            "version": ["build": 0, "class": "Version", "major": 0, "minor": 5],
            "tags": ["HintGame"],
            "items_handling": 0,  // 0b000 in Python
            "uuid": "",
            "game": "",
            "slot_data": false
        ]]
        print("Sending Connect packet: \(payload)")
        send(payload: payload)
    }
    
    func receiveMessages() {
        guard let webSocket = self.webSocket, webSocket.state == .running else {
            print("WebSocket is not running; stopping receive loop.")
            return
        }
        webSocket.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.isOpen = false
                self.onDisconnected?()
                // Only continue receiving if the socket is still running.
                if webSocket.state == .running {
                    self.receiveMessages()
                } else {
                    print("WebSocket no longer running after error; stopping loop.")
                }
            case .success(let message):
                print("Received message: \(message)")
                switch message {
                case .data(let data):
                    self.handleMessageData(data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self.handleMessageData(data)
                    }
                @unknown default:
                    print("Received unknown message format")
                }
                // Continue receiving if still running.
                if webSocket.state == .running {
                    self.receiveMessages()
                }
            }
        }
    }
    
    func sendPing(completion: @escaping (Error?) -> Void) {
        webSocket?.sendPing { error in
            if let error = error {
                print("Ping failed with error: \(error)")
            } else {
                print("Ping successful")
            }
            completion(error)
        }
    }
    
    func handleMessageData(_ data: Data) {
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                for msg in jsonArray {
                    readResponse(msg: msg)
                }
            }
        } catch {
            print("Error decoding JSON message: \(error)")
        }
    }
    
    func readResponse(msg: [String: Any]) {
        guard let cmd = msg["cmd"] as? String else { return }
        print("Complete Response:!!! \(msg)!!!")
        switch cmd {
        case "Connected":
            print("Connected: \(msg)")
            onConnected?()
            
            
            // Process location data.
            if let checkedArray = msg["checked_locations"] as? [Any],
               let missingArray = msg["missing_locations"] as? [Any] {
                self.checkedLocations = checkedArray.map { "\($0)" }
                self.missingLocations = missingArray.map { "\($0)" }
                self.allLocations = self.checkedLocations + self.missingLocations
                print("All Locations: \(self.allLocations)")
                print("Missing Locations: \(self.missingLocations)")
                print("Checked Locations: \(self.checkedLocations)")
            }
            
            // Process slot info.
            if let slotInfo = msg["slot_info"] as? [String: Any] {
                self.slotList = slotInfo.map { (key, value) in
                    var entry = value as? [String: Any] ?? [:]
                    entry["number"] = key
                    return entry
                }
                print("Slot List before mapping team: \(self.slotList)")
            }
            
            // Set connection open to true
            isOpen = true
            
            // Build a mapping from slot (as a string) to team number using the players array.
            if let players = msg["players"] as? [[String: Any]] {
                var slotTeamMapping: [String: Any] = [:]
                for player in players {
                    if let slot = player["slot"] as? CustomStringConvertible,
                       let team = player["team"] {
                        slotTeamMapping["\(slot)"] = team
                    }
                }
                // Update the slot list entries with the corresponding team.
                for i in 0..<self.slotList.count {
                    if let slotNumber = self.slotList[i]["number"] as? String,
                       let team = slotTeamMapping[slotNumber] {
                        self.slotList[i]["team"] = team
                    }
                }
                print("Slot List after mapping team: \(self.slotList)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.getAdminSettings()
                self.setNotifySettingsUpdate()
            }
                
            // Wait 1 second after connection, then refresh hint data.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                
                // Check if hints are enabled
                print("hintsEnabled: \(self.hintsEnabled)")
                if self.hintsEnabled {
                    print("Hints are enabled, refreshing hint data.")
                    
                    self.refreshHintData {
                        // Once hint data is refreshed, extract game names from the slot list.
                        let games = self.slotList.compactMap { $0["game"] as? String }
                        print("Requesting datapacks for games: \(games)")
                        self.getDataPackages(for: games)
                    }
                } else {
                    print("Hints are disabled, closing connection if open.")
                    if self.isOpen {
                        ArchipelagoConnectionManager.shared.disconnect()
                    }
                }
            }
        
            
        case "Retrieved":
            print("Retrieved: \(msg)")
            if let keys = msg["keys"] as? [String: Any] {
                // Handle settings changes if they exist.
                if let settings = keys["APSudoku_Settings"] as? [String: Any] {
                    print("Received settings: \(settings)")
                    
                    // Update hintsEnabled
                    if let areHintsEnabled = settings["enabled"] as? Bool {
                        self.hintsEnabled = areHintsEnabled
                        print("hintsEnabled set to: \(self.hintsEnabled)")
                    }
                    if self.hintsEnabled  == false {
                        HintViewModel.shared.showHintsDisabledOnServer()
                        ArchipelagoConnectionManager.shared.disconnect()
                    }
                    // Update the hint probabilities if weights are provided.
                    if let weights = settings["weights"] as? [String: [Int]] {
                        HintGameWebSocketClient.updateHintProbabilities(with: weights)
                    }
                }
                for (key, value) in keys {
                    if key.hasPrefix("_read_hints_"),
                       let hints = value as? [[String: Any]] {
                        for hint in hints {
                            // Convert the location value to a string regardless of its type.
                            if let locationValue = hint["location"] {
                                let locString = "\(locationValue)"
                                self.hintedLocations.append(locString)
                            }
                        }
                    }
                }
                print("Hinted locations: \(self.hintedLocations)")
            }
            
        case "LocationInfo":
            if let locations = msg["locations"] as? [[String: Any]] {
                for locInfo in locations {
                    // Convert the location value to a string.
                    var locationString: String? = nil
                    if let loc = locInfo["location"] as? String {
                        locationString = loc
                    } else if let loc = locInfo["location"] {
                        locationString = "\(loc)"
                    }
                    
                    if let locationValue = locationString,
                       let flagValue = locInfo["flags"] {
                        if !self.locationsProgression.contains(where: {
                            if let existingLoc = $0["location"] as? String {
                                return existingLoc == locationValue
                            }
                            return false
                        }) {
                            self.locationsProgression.append(["location": locationValue, "flags": flagValue])
                        }
                    }
                }
                print("Locations Progression:", self.locationsProgression)
            }
            
        case "DataPackage":
            if let responseData = msg["data"] as? [String: Any] {
                DataCacheManager.shared.handleCombinedDataPack(from: ["data": responseData])
            }
        case "PrintJSON":
            print("PrintJSON: \(msg)")
            if let type = msg["type"] as? String, type == "Hint" {
                self.handleHintMessage(msg: msg)
            }
        case "SetReply":
            print("SetReply: \(msg)")
            if let key = msg["key"] as? String, key == "APSudoku_Settings",
               let valueDict = msg["value"] as? [String: Any] {
                // Update hintsEnabled: enabled is provided as an integer (1 for true, 0 for false)
                if let areHintsEnabled = valueDict["enabled"] as? Bool {
                    
                    self.hintsEnabled = areHintsEnabled
                    print("Hints enabled set to: \(self.hintsEnabled)")
                    if self.hintsEnabled  == false {
                        HintViewModel.shared.showHintsDisabledOnServer()
                        ArchipelagoConnectionManager.shared.disconnect()
                    }
                }
                // Update hint probabilities using the new weights.
                if let weights = valueDict["weights"] as? [String: [Int]] {
                    HintGameWebSocketClient.updateHintProbabilities(with: weights)
                }
            }
        default:
            print("Received unhandled message:!!! \(msg)!!!")

        }
    }
}
