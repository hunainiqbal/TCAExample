import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        TabView(selection: $store.selectedTab) {
            Tab("Products", systemImage: "shippingbox", value: HomeFeature.State.Tab.products) {
                ProductsView(store: store.scope(state: \.products, action: \.products))
            }
            Tab("Account", systemImage: "person.crop.circle", value: HomeFeature.State.Tab.account) {
                AccountView(store: store.scope(state: \.account, action: \.account))
            }
        }
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}
