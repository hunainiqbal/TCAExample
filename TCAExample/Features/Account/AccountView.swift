import ComposableArchitecture
import SwiftUI

struct AccountView: View {
    let store: StoreOf<AccountFeature>

    var body: some View {
        NavigationStack {
            List {
                Section("API Key") {
                    Text(store.maskedKey)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }

                Section {
                    Button("Log Out", role: .destructive) {
                        store.send(.logoutButtonTapped)
                    }
                }
            }
            .navigationTitle("Account")
        }
        .task { store.send(.onAppear) }
    }
}

#Preview {
    AccountView(
        store: Store(initialState: AccountFeature.State(maskedKey: "3118••••••••e37a3")) {
            AccountFeature()
        }
    )
}
