import ComposableArchitecture
import Foundation

/// The "Account" tab. Shows the masked API key and a Log Out button; the actual
/// key clearing happens in `AppFeature` (single owner of the session), reached
/// via a `delegate` action.
@Reducer
struct AccountFeature {
    @ObservableState
    struct State: Equatable {
        var maskedKey = ""
    }

    enum Action {
        case onAppear
        case logoutButtonTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case logoutRequested
        }
    }

    @Dependency(\.apiKeyStore) var apiKeyStore

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.maskedKey = Self.mask(apiKeyStore.load())
                return .none

            case .logoutButtonTapped:
                return .send(.delegate(.logoutRequested))

            case .delegate:
                return .none
            }
        }
        #if DEBUG
        ._printChanges()   // logs every action + state diff for this feature
        #endif
    }

    private static func mask(_ key: String?) -> String {
        guard let key, key.count > 8 else { return "••••••••" }
        return "\(key.prefix(4))••••••••\(key.suffix(4))"
    }
}
