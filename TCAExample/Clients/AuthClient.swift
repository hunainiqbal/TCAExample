import ComposableArchitecture
import Foundation

/// "Authentication" for a keyless public API: validates an API key by making a
/// real request with it. A 401/403 means the key is bad; an empty collection
/// (404) still means the key itself is valid.
struct AuthClient: Sendable {
    var validate: @Sendable (_ apiKey: String) async throws -> Void
}

extension AuthClient: DependencyKey {
    static let liveValue = AuthClient(
        validate: { apiKey in
            var request = URLRequest(url: RestfulAPI.objectsURL())
            request.httpMethod = "GET"
            do {
                let _: [Product] = try await RestfulAPI.send(request, apiKey: apiKey)
            } catch APIError.notFound {
                // Valid key, the collection simply has no objects yet.
            }
        }
    )

    static let previewValue = AuthClient(validate: { _ in })
}

extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}
