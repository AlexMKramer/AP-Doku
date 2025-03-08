import Foundation

/// A structure representing a cached datapack with inverted lookups.
struct DataCache {
    let checksum: String?
    let fields: [String: Any]
    let itemIDToName: [String: String]
    let locationIDToName: [String: String]
    
    init(dictionary: [String: Any]) {
        // Store checksum if available.
        self.checksum = dictionary["checksum"] as? String
        // Store the entire dictionary (or filtered version) as fields.
        self.fields = dictionary
        
        // Invert "item_name_to_id" mapping.
        if let mapping = dictionary["item_name_to_id"] as? [String: Any] {
            var inv = [String: String]()
            for (name, value) in mapping {
                if let idInt = value as? Int {
                    inv["\(idInt)"] = name
                } else if let idStr = value as? String, let idInt = Int(idStr) {
                    inv["\(idInt)"] = name
                }
            }
            self.itemIDToName = inv
        } else {
            self.itemIDToName = [:]
        }
        
        // Invert "location_name_to_id" mapping.
        if let mapping = dictionary["location_name_to_id"] as? [String: Any] {
            var inv = [String: String]()
            for (name, value) in mapping {
                if let idInt = value as? Int {
                    inv["\(idInt)"] = name
                } else if let idStr = value as? String, let idInt = Int(idStr) {
                    inv["\(idInt)"] = name
                }
            }
            self.locationIDToName = inv
        } else {
            self.locationIDToName = [:]
        }
    }
}

/// Manager that handles caching combined datapack responses.
final class DataCacheManager {
    static let shared = DataCacheManager()
    
    /// In-memory cache mapping game names to a DataCache.
    var datapackCache: [String: DataCache] = [:]
    
    /// A raw cache dictionary that stores all filtered datapack dictionaries.
    var rawCache: [String: [String: Any]] = [:]
    
    /// Set of keys to keep in the cached datapack.
    let cachedFields: Set<String> = ["checksum", "item_name_to_id", "location_name_to_id"]
    
    private init() {}
    
    /// Handle a datapack for a single game.
    func handleDataPack(for game: String, data: [String: Any]) {
        var filteredData = data
        // Filter out keys not in our cachedFields.
        for key in data.keys {
            if !cachedFields.contains(key) {
                filteredData.removeValue(forKey: key)
            }
        }
        
        // Write filteredData to disk as a JSON file.
        let fileManager = FileManager.default
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: filteredData, options: [.prettyPrinted])
            let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let folderURL = docs.appendingPathComponent("ap/datapacks", isDirectory: true)
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let fileURL = folderURL.appendingPathComponent("\(game).json")
            try jsonData.write(to: fileURL)
            print("Datapack for \(game) written to \(fileURL.path)")
        } catch {
            print("Error writing datapack for \(game): \(error)")
        }
        
        // Create and store a DataCache.
        let dataCache = DataCache(dictionary: filteredData)
        datapackCache[game] = dataCache
        
        // Update raw cache.
        rawCache[game] = filteredData
        
        // Write the raw cache to disk.
        do {
            let cacheData = try JSONSerialization.data(withJSONObject: rawCache, options: [])
            let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let cacheURL = docs.appendingPathComponent("ap/datapacks/cache.dat")
            try cacheData.write(to: cacheURL)
            print("Updated raw cache written to \(cacheURL.path)")
        } catch {
            print("Error writing raw cache: \(error)")
        }
    }
    
    /// Handle a combined datapack response.
    /// Assumes the incoming dictionary has a structure like:
    /// ["data": { "games": { "GameName1": { ... }, "GameName2": { ... } } }]
    func handleCombinedDataPack(from response: [String: Any]) {
        // Check for a top-level "data" dictionary.
        guard let dataDict = response["data"] as? [String: Any] else {
            print("No 'data' key found in combined datapack response.")
            return
        }
        // Look for the "games" key.
        guard let gamesDict = dataDict["games"] as? [String: Any] else {
            print("No 'games' key found in datapack response.")
            return
        }
        
        // Process each game.
        for (game, pack) in gamesDict {
            if let packDict = pack as? [String: Any] {
                handleDataPack(for: game, data: packDict)
            } else {
                print("Datapack for game \(game) is not in the expected dictionary format.")
            }
        }
    }
}
