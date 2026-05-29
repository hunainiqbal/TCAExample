import ComposableArchitecture
import SwiftUI

@main
struct TCAExampleApp: App {
    /// The single root store for the app. Dependencies resolve to their live
    /// values here; previews and (future) tests override them per-store.
    @MainActor
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: Self.store)
        }
    }
}
