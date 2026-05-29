import Foundation

/// Networking namespace for restful-api.dev: builds URLs against the private
/// collection, attaches the `x-api-key` header, and normalizes failures to
/// `APIError`. Shared by `AuthClient` and `ProductsClient`.
enum RestfulAPI {
    static let baseURL = URL(string: "https://api.restful-api.dev")!
    /// Objects live under a private, key-scoped collection so that created items
    /// persist and appear in subsequent list calls.
    static let collection = "products"

    static func objectsURL(id: String? = nil) -> URL {
        let url = baseURL.appending(path: "collections/\(collection)/objects")
        return id.map { url.appending(path: $0) } ?? url
    }

    /// Sends a request and decodes the body.
    static func send<T: Decodable>(_ request: URLRequest, apiKey: String) async throws -> T {
        let data = try await perform(request, apiKey: apiKey)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    /// Sends a request, validates the status, and returns the raw body (callers
    /// that don't need the body — e.g. DELETE — can ignore it).
    @discardableResult
    static func perform(_ request: URLRequest, apiKey: String) async throws -> Data {
        var request = request
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        if request.httpBody != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.network
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.network }
        switch http.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            let message = (try? JSONDecoder().decode(ServerError.self, from: data))?.error
            throw APIError.server(status: http.statusCode, message: message)
        }
    }
}

private struct ServerError: Decodable {
    let error: String?
}
