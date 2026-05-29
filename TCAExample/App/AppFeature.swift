import ComposableArchitecture
import Foundation

/// Root reducer and single owner of the API-key session:
///
/// - On launch it restores a stored key and validates it.
/// - It composes `LoginFeature` (always present) and an optional `HomeFeature`
///   (the authenticated shell, present only when a valid key exists).
/// - Login success and Account logout arrive as `delegate` actions and are
///   translated into Keychain writes here.
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var isRestoringSession = true
        var login = LoginFeature.State()
        var home: HomeFeature.State?
    }

    enum Action {
        case onAppear
        case validateResponse(Result<Void, APIError>)
        case login(LoginFeature.Action)
        case home(HomeFeature.Action)
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.apiKeyStore) var apiKeyStore

    var body: some ReducerOf<Self> {
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                guard let key = apiKeyStore.load() else {
                    state.isRestoringSession = false
                    return .none
                }
                return .run { [authClient] send in
                    do {
                        try await authClient.validate(key)
                        await send(.validateResponse(.success(())))
                    } catch let error as APIError {
                        await send(.validateResponse(.failure(error)))
                    } catch {
                        await send(.validateResponse(.failure(.unknown(error.localizedDescription))))
                    }
                }

            case .validateResponse(.success):
                state.isRestoringSession = false
                state.home = HomeFeature.State()
                return .none

            case .validateResponse(.failure(.unauthorized)):
                state.isRestoringSession = false
                apiKeyStore.clear()
                state.home = nil
                return .none

            case .validateResponse(.failure):
                // Transient failure — keep the key so the next launch can retry.
                state.isRestoringSession = false
                return .none

            case let .login(.delegate(.authenticated(key))):
                apiKeyStore.save(key)
                state.login = LoginFeature.State()
                state.home = HomeFeature.State()
                return .none

            case .login:
                return .none

            case .home(.account(.delegate(.logoutRequested))):
                apiKeyStore.clear()
                state.home = nil
                return .none

            case .home:
                return .none
            }
        }
        .ifLet(\.home, action: \.home) {
            HomeFeature()
        }
        #if DEBUG
        ._printChanges()   // logs every action + state diff for this feature
        #endif
    }
}
