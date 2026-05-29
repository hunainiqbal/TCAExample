import ComposableArchitecture
import SwiftUI

struct ProductDetailView: View {
    @Bindable var store: StoreOf<ProductDetailFeature>

    private var product: Product { store.product }

    var body: some View {
        List {
            Section {
                LabeledContent("Name", value: product.name)
                LabeledContent("ID", value: product.id)
            }

            Section("Data") {
                if product.sortedData.isEmpty {
                    Text("No data").foregroundStyle(.secondary)
                } else {
                    ForEach(product.sortedData, id: \.key) { pair in
                        LabeledContent(pair.key, value: pair.value.displayString)
                    }
                }
            }

            if product.createdAt != nil || product.updatedAt != nil {
                Section("Timestamps") {
                    if let createdAt = product.createdAt {
                        LabeledContent("Created") { TimestampText(iso: createdAt) }
                    }
                    if let updatedAt = product.updatedAt {
                        LabeledContent("Updated") { TimestampText(iso: updatedAt) }
                    }
                }
            }

            if let errorMessage = store.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Options", systemImage: "ellipsis.circle") {
                    Button("Edit", systemImage: "pencil") { store.send(.editButtonTapped) }
                    Button("Rename", systemImage: "character.cursor.ibeam") { store.send(.renameButtonTapped) }
                    Button("Delete", systemImage: "trash", role: .destructive) { store.send(.deleteButtonTapped) }
                }
                .disabled(store.isWorking)
            }
        }
        .overlay {
            if store.isWorking {
                ProgressView().controlSize(.large)
            }
        }
        .sheet(item: $store.scope(state: \.editForm, action: \.editForm)) { formStore in
            ProductFormView(store: formStore)
        }
        .confirmationDialog($store.scope(state: \.deleteConfirm, action: \.deleteConfirm))
        .alert("Rename", isPresented: $store.isRenaming) {
            TextField("Name", text: $store.renameText)
            Button("Save") { store.send(.renameSubmitted) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(
            store: Store(initialState: ProductDetailFeature.State(product: .preview)) {
                ProductDetailFeature()
            }
        )
    }
}
