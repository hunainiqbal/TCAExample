import ComposableArchitecture
import Foundation

/// API-key sign-in. Validates the key against the API and reports success to the
/// parent via a `delegate` action; it does not persist the key itself.
@Reducer
struct LoginFeature {
    @ObservableState
    struct State: Equatable {
        // Enter your restful-api.dev API key. Never hardcode a real key here —
        // it is stored in the Keychain after a successful sign-in.
        var apiKey = ""
        var isValidating = false
        var errorMessage: String?

        var isValid: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case connectButtonTapped
        case validateResponse(Result<String, APIError>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case authenticated(apiKey: String)
        }
    }

    @Dependency(\.authClient) var authClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .connectButtonTapped:
                guard state.isValid, !state.isValidating else { return .none }
                state.isValidating = true
                state.errorMessage = nil
                let key = state.apiKey.trimmingCharacters(in: .whitespaces)
                return .run { [authClient] send in
                    do {
                        try await authClient.validate(key)
                        await send(.validateResponse(.success(key)))
                    } catch let error as APIError {
                        await send(.validateResponse(.failure(error)))
                    } catch {
                        await send(.validateResponse(.failure(.unknown(error.localizedDescription))))
                    }
                }

            case let .validateResponse(.success(key)):
                state.isValidating = false
                return .send(.delegate(.authenticated(apiKey: key)))

            case let .validateResponse(.failure(error)):
                state.isValidating = false
                state.errorMessage = error.localizedDescription
                return .none

            case .delegate:
                return .none
            }
        }
        #if DEBUG
        ._printChanges()   // logs every action + state diff for this feature
        #endif
    }
}
