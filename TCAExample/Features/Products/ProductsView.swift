import ComposableArchitecture
import SwiftUI

struct ProductsView: View {
    @Bindable var store: StoreOf<ProductsFeature>

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.products.isEmpty {
                    ProgressView().controlSize(.large)
                } else if store.products.isEmpty, let errorMessage = store.errorMessage {
                    ErrorStateView(title: "Couldn't load products", message: errorMessage) {
                        store.send(.retryButtonTapped)
                    }
                } else if store.products.isEmpty {
                    ContentUnavailableView(
                        "No Products",
                        systemImage: "shippingbox",
                        description: Text("Tap + to create your first object.")
                    )
                } else {
                    productList
                }
            }
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Product", systemImage: "plus") {
                        store.send(.addButtonTapped)
                    }
                }
            }
            .navigationDestination(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
                ProductDetailView(store: detailStore)
            }
        }
        .sheet(item: $store.scope(state: \.createForm, action: \.createForm)) { formStore in
            ProductFormView(store: formStore)
        }
        .task { store.send(.onAppear) }
    }

    private var productList: some View {
        List {
            ForEach(store.products) { product in
                Button {
                    store.send(.productTapped(product))
                } label: {
                    HStack {
                        ProductRow(product: product)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
        .refreshable { await store.send(.refreshed).finish() }
    }
}

#Preview {
    ProductsView(
        store: Store(initialState: ProductsFeature.State()) {
            ProductsFeature()
        }
    )
}
