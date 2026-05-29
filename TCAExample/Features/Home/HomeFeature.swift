import ComposableArchitecture
import Foundation

/// The authenticated shell: composes the Products and Account tabs and owns the
/// selected tab. `AccountFeature`'s `delegate` (logout) falls through to
/// `AppFeature`, which owns the API key / session.
@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .products
        var products = ProductsFeature.State()
        var account = AccountFeature.State()

        enum Tab: Equatable { case products, account }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case products(ProductsFeature.Action)
        case account(AccountFeature.Action)
    }

    var body: some ReducerOf<Self> {
        CombineReducers {
            BindingReducer()
            Scope(state: \.products, action: \.products) {
                ProductsFeature()
            }
            Scope(state: \.account, action: \.account) {
                AccountFeature()
            }
        }
        #if DEBUG
        ._printChanges()   // logs every action + state diff for this feature
        #endif
    }
}
