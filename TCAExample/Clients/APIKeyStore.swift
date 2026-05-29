import ComposableArchitecture
import Foundation

/// Persists the restful-api.dev API key across launches (Keychain-backed live
/// value; in-memory `previewValue`).
struct APIKeyStore: Sendable {
    var load: @Sendable () -> String?
    var save: @Sendable (String) -> Void
    var clear: @Sendable () -> Void
}

extension APIKeyStore: DependencyKey {
    static let liveValue: APIKeyStore = {
        let service = "com.harry.TCAExample.apikey"
        let account = "restful-api.dev"

        return APIKeyStore(
            load: {
                guard let data = Keychain.load(service: service, account: account) else { return nil }
                return String(data: data, encoding: .utf8)
            },
            save: { key in
                Keychain.save(Data(key.utf8), service: service, account: account)
            },
            clear: {
                Keychain.delete(service: service, account: account)
            }
        )
    }()

    static let previewValue = APIKeyStore(load: { "preview-key" }, save: { _ in }, clear: {})
}

extension DependencyValues {
    var apiKeyStore: APIKeyStore {
        get { self[APIKeyStore.self] }
        set { self[APIKeyStore.self] = newValue }
    }
}
