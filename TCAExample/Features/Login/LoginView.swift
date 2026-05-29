import ComposableArchitecture
import SwiftUI

struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("API Key", text: $store.apiKey, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                } header: {
                    Text("restful-api.dev API Key")
                } footer: {
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    } else {
                        Text("Your key is validated against the API and stored securely in the Keychain.")
                    }
                }

                Section {
                    Button {
                        store.send(.connectButtonTapped)
                    } label: {
                        Group {
                            if store.isValidating {
                                ProgressView()
                            } else {
                                Text("Connect").bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!store.isValid || store.isValidating)
                }
            }
            .navigationTitle("Sign In")
        }
    }
}

#Preview {
    LoginView(
        store: Store(initialState: LoginFeature.State()) {
            LoginFeature()
        }
    )
}
