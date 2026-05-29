import Foundation

/// The request body for creating (POST) or replacing (PUT) an object.
struct ProductInput: Codable, Equatable, Sendable {
    var name: String
    var data: [String: JSONValue]
}
