import Foundation

/// A normalized error surfaced by the API clients.
enum APIError: Error, Equatable, LocalizedError, Sendable {
    /// 401/403 — the API key is missing or rejected.
    case unauthorized
    /// 404 — the object (or collection) doesn't exist.
    case notFound
    /// Any other non-2xx response, with the server's message when available.
    case server(status: Int, message: String?)
    /// The response body could not be decoded into the expected shape.
    case decoding
    /// The request never completed (offline, timeout, DNS, …).
    case network
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your API key was rejected. Please sign in again."
        case .notFound:
            return "That item could not be found."
        case let .server(status, message):
            return message ?? "Something went wrong (status \(status))."
        case .decoding:
            return "We received an unexpected response. Please try again."
        case .network:
            return "Couldn't reach the server. Check your connection and try again."
        case let .unknown(message):
            return message
        }
    }
}
