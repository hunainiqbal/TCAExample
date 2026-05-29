import ComposableArchitecture
import Foundation

/// The products list: loads all objects, supports pull-to-refresh, presents a
/// create form (POST) and a detail screen, and reconciles its list when children
/// report create/update/delete via `delegate` actions.
@Reducer
struct ProductsFeature {
    @ObservableState
    struct State: Equatable {
        var products: IdentifiedArrayOf<Product> = []
        var isLoading = false
        var errorMessage: String?
        var hasLoadedOnce = false
        @Presents var detail: ProductDetailFeature.State?
        @Presents var createForm: ProductFormFeature.State?
    }

    enum Action {
        case onAppear
        case refreshed
        case retryButtonTapped
        case addButtonTapped
        case productsResponse(Result<[Product], APIError>)
        case productTapped(Product)
        case detail(PresentationAction<ProductDetailFeature.Action>)
        case createForm(PresentationAction<ProductFormFeature.Action>)
    }

    private enum CancelID { case load }

    @Dependency(\.productsClient) var productsClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoadedOnce, !state.isLoading else { return .none }
                state.isLoading = true
                state.errorMessage = nil
                return load()

            case .refreshed:
                state.errorMessage = nil
                return load()

            case .retryButtonTapped:
                state.isLoading = true
                state.errorMessage = nil
                return load()

            case .addButtonTapped:
                state.createForm = ProductFormFeature.State(mode: .create)
                return .none

            case let .productsResponse(.success(items)):
                state.isLoading = false
                state.hasLoadedOnce = true
                state.errorMessage = nil
                state.products = IdentifiedArray(uniqueElements: items)
                return .none

            case let .productsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .productTapped(product):
                state.detail = ProductDetailFeature.State(product: product)
                return .none

            // Create form (POST)
            case let .createForm(.presented(.delegate(.saved(product)))):
                #if DEBUG
                print("🔵 [parent] received createForm.delegate.saved — inserting id=\(product.id) at top of list")
                #endif
                state.products.insert(product, at: 0)
                return .none

            case .createForm:
                return .none

            // Detail (PUT / PATCH / DELETE)
            case let .detail(.presented(.delegate(.updated(product)))):
                state.products.updateOrAppend(product)
                return .none

            case let .detail(.presented(.delegate(.deleted(id)))):
                state.products.remove(id: id)
                state.detail = nil
                return .none

            case .detail:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            ProductDetailFeature()
        }
        .ifLet(\.$createForm, action: \.createForm) {
            ProductFormFeature()
        }
        #if DEBUG
        ._printChanges()   // logs every action + state diff for this feature
        #endif
    }

    private func load() -> Effect<Action> {
        .run { [productsClient] send in
            do {
                let items = try await productsClient.fetchAll()
                await send(.productsResponse(.success(items)))
            } catch let error as APIError {
                await send(.productsResponse(.failure(error)))
            } catch {
                await send(.productsResponse(.failure(.unknown(error.localizedDescription))))
            }
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}
