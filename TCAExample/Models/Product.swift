import Foundation

/// An object from restful-api.dev. (We keep the user-facing name "Product".)
struct Product: Codable, Equatable, Identifiable, Sendable {
    let id: String
    var name: String
    var data: [String: JSONValue]?
    var createdAt: String?
    var updatedAt: String?

    /// `data` rendered as a short "key: value · key: value" line for list rows.
    var subtitle: String? {
        guard let data, !data.isEmpty else { return nil }
        return data
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value.displayString)" }
            .joined(separator: " · ")
    }

    /// `data` as a stable, sorted array for rendering in `ForEach`.
    var sortedData: [(key: String, value: JSONValue)] {
        (data ?? [:]).sorted { $0.key < $1.key }
    }
}

extension Product {
    static let preview = Product(
        id: "7",
        name: "Apple MacBook Pro 16",
        data: [
            "year": .int(2019),
            "price": .double(1849.99),
            "CPU model": .string("Intel Core i9"),
            "Hard disk size": .string("1 TB"),
        ],
        createdAt: "2022-11-21T20:06:23.986Z",
        updatedAt: nil
    )
}
