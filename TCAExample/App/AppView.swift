import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if store.isRestoringSession {
                ProgressView("Restoring session…")
            } else if let homeStore = store.scope(state: \.home, action: \.home) {
                HomeView(store: homeStore)
            } else {
                LoginView(store: store.scope(state: \.login, action: \.login))
            }
        }
        .task { store.send(.onAppear) }
    }
}

#Preview("Logged out") {
    AppView(
        store: Store(initialState: AppFeature.State(isRestoringSession: false)) {
            AppFeature()
        }
    )
}

#Preview("Logged in") {
    AppView(
        store: Store(
            initialState: AppFeature.State(isRestoringSession: false, home: HomeFeature.State())
        ) {
            AppFeature()
        }
    )
}
