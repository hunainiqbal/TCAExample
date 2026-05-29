import ComposableArchitecture
import SwiftUI

struct ProductFormView: View {
    @Bindable var store: StoreOf<ProductFormFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $store.name)
                }

                Section("Data") {
                    ForEach($store.fields) { $field in
                        HStack {
                            TextField("Key", text: $field.key)
                                .autocorrectionDisabled()
                            Divider()
                            TextField("Value", text: $field.value)
                                .autocorrectionDisabled()
                        }
                    }
                    .onDelete { store.send(.deleteFields($0)) }

                    Button("Add Field", systemImage: "plus") {
                        store.send(.addFieldTapped)
                    }
                }

                if let errorMessage = store.errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(store.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.send(.cancelTapped) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { store.send(.saveTapped) }
                        .disabled(!store.isValid || store.isSaving)
                }
            }
            .overlay {
                if store.isSaving {
                    ProgressView().controlSize(.large)
                }
            }
        }
    }
}

#Preview("Create") {
    ProductFormView(
        store: Store(initialState: ProductFormFeature.State(mode: .create)) {
            ProductFormFeature()
        }
    )
}

#Preview("Edit") {
    ProductFormView(
        store: Store(initialState: ProductFormFeature.State(mode: .edit(id: "7"), product: .preview)) {
            ProductFormFeature()
        }
    )
}
