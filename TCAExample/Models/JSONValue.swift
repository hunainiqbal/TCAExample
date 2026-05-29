import Foundation

/// A single value inside a restful-api.dev object's free-form `data` dictionary.
/// The API mixes strings, numbers, and booleans, so we model the cases we care
/// about and render/parse them explicitly.
enum JSONValue: Codable, Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .int(value): try container.encode(value)
        case let .double(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    /// Best-effort parse of free-text form input into the most specific case.
    init(parsing text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            self = .null
        } else if trimmed == "true" || trimmed == "false" {
            self = .bool(trimmed == "true")
        } else if let int = Int(trimmed) {
            self = .int(int)
        } else if let double = Double(trimmed) {
            self = .double(double)
        } else {
            self = .string(text)
        }
    }

    var displayString: String {
        switch self {
        case let .string(value): value
        case let .int(value): String(value)
        case let .double(value): value.formatted()
        case let .bool(value): String(value)
        case .null: "—"
        }
    }
}
