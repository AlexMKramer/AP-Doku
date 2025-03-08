import Foundation

// Represents an item (or location) from the server.
struct NetworkItem: Codable {
    let locId: Int
    let isProgression: Bool
    
    enum CodingKeys: String, CodingKey {
        case locId = "loc_id"
        case isProgression = "is_prog"
    }
}

// Represents a hint response from the server.
struct HintResponse: Codable {
    let type: String
    let loc_id: Int
    let hint: String
}
