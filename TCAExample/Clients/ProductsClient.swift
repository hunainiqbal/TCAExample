import ComposableArchitecture
import Foundation

/// Full CRUD over restful-api.dev objects. The live value reads the stored API
/// key from the Keychain and attaches it to every request.
struct ProductsClient: Sendable {
    var fetchAll: @Sendable () async throws -> [Product]
    var fetch: @Sendable (_ id: String) async throws -> Product
    var create: @Sendable (_ input: ProductInput) async throws -> Product       // POST
    var update: @Sendable (_ id: String, _ input: ProductInput) async throws -> Product  // PUT
    var rename: @Sendable (_ id: String, _ name: String) async throws -> Product // PATCH
    var delete: @Sendable (_ id: String) async throws -> Void                    // DELETE
}

extension ProductsClient: DependencyKey {
    static let liveValue: ProductsClient = {
        @Sendable func apiKey() throws -> String {
            guard let key = APIKeyStore.liveValue.load() else { throw APIError.unauthorized }
            return key
        }

        return ProductsClient(
            fetchAll: {
                var request = URLRequest(url: RestfulAPI.objectsURL())
                request.httpMethod = "GET"
                do {
                    return try await RestfulAPI.send(request, apiKey: apiKey())
                } catch APIError.notFound {
                    return []   // empty collection
                }
            },
            fetch: { id in
                var request = URLRequest(url: RestfulAPI.objectsURL(id: id))
                request.httpMethod = "GET"
                return try await RestfulAPI.send(request, apiKey: apiKey())
            },
            create: { input in
                var request = URLRequest(url: RestfulAPI.objectsURL())
                request.httpMethod = "POST"
                request.httpBody = try JSONEncoder().encode(input)
                return try await RestfulAPI.send(request, apiKey: apiKey())
            },
            update: { id, input in
                var request = URLRequest(url: RestfulAPI.objectsURL(id: id))
                request.httpMethod = "PUT"
                request.httpBody = try JSONEncoder().encode(input)
                return try await RestfulAPI.send(request, apiKey: apiKey())
            },
            rename: { id, name in
                var request = URLRequest(url: RestfulAPI.objectsURL(id: id))
                request.httpMethod = "PATCH"
                request.httpBody = try JSONEncoder().encode(["name": name])
                return try await RestfulAPI.send(request, apiKey: apiKey())
            },
            delete: { id in
                var request = URLRequest(url: RestfulAPI.objectsURL(id: id))
                request.httpMethod = "DELETE"
                try await RestfulAPI.perform(request, apiKey: apiKey())
            }
        )
    }()

    static let previewValue = ProductsClient(
        fetchAll: { [.preview] },
        fetch: { _ in .preview },
        create: { _ in .preview },
        update: { _, _ in .preview },
        rename: { _, _ in .preview },
        delete: { _ in }
    )
}

extension DependencyValues {
    var productsClient: ProductsClient {
        get { self[ProductsClient.self] }
        set { self[ProductsClient.self] = newValue }
    }
}
