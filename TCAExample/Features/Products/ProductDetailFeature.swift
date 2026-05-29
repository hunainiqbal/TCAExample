import ComposableArchitecture
import Foundation

/// Detail for a single object. Hosts the three mutating verbs:
/// - **Edit** → presents the form and saves with PUT (full replace).
/// - **Rename** → an inline alert that saves with PATCH (partial update).
/// - **Delete** → a confirmation dialog, then DELETE.
///
/// Outcomes are reported to `ProductsFeature` via `delegate` so the list stays in
/// sync; dismissal of the detail after delete is driven by the parent.
@Reducer
struct ProductDetailFeature {
    @ObservableState
    struct State: Equatable {
        var product: Product
        var isWorking = false
        var errorMessage: String?
        var isRenaming = false
        var renameText = ""
        @Presents var editForm: ProductFormFeature.State?
        @Presents var deleteConfirm: ConfirmationDialogState<Action.Dialog>?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case editButtonTapped
        case renameButtonTapped
        case renameSubmitted
        case deleteButtonTapped
        case patchResponse(Result<Product, APIError>)
        case deleteResponse(Result<String, APIError>)
        case editForm(PresentationAction<ProductFormFeature.Action>)
        case deleteConfirm(PresentationAction<Dialog>)
        case delegate(Delegate)

        enum Dialog: Equatable { case confirmDelete }
        enum Delegate: Equatable {
            case updated(Product)
            case deleted(id: String)
        }
    }

    @Dependency(\.productsClient) var productsClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .editButtonTapped:
                state.editForm = ProductFormFeature.State(
                    mode: .edit(id: state.product.id),
                    product: state.product
                )
                return .none

            case .renameButtonTapped:
                state.renameText = state.product.name
                state.isRenaming = true
                return .none

            case .renameSubmitted:
                let name = state.renameText.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return .none }
                state.isWorking = true
                state.errorMessage = nil
                let id = state.product.id
                return .run { [productsClient] send in
                    do {
                        let updated = try await productsClient.rename(id, name)
                        await send(.patchResponse(.success(updated)))
                    } catch let error as APIError {
                        await send(.patchResponse(.failure(error)))
                    } catch {
                        await send(.patchResponse(.failure(.unknown(error.localizedDescription))))
                    }
                }

            case .deleteButtonTapped:
                state.deleteConfirm = ConfirmationDialogState {
                    TextState("Delete “\(state.product.name)”?")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) { TextState("Delete") }
                    ButtonState(role: .cancel) { TextState("Cancel") }
                }
                return .none

            case .deleteConfirm(.presented(.confirmDelete)):
                state.isWorking = true
                state.errorMessage = nil
                let id = state.product.id
                return .run { [productsClient] send in
                    do {
                        try await productsClient.delete(id)
                        await send(.deleteResponse(.success(id)))
                    } catch let error as APIError {
                        await send(.deleteResponse(.failure(error)))
                    } catch {
                        await send(.deleteResponse(.failure(.unknown(error.localizedDescription))))
                    }
                }

            case .deleteConfirm:
                return .none

            case let .patchResponse(.success(product)):
                state.isWorking = false
                state.product = product
                return .send(.delegate(.updated(product)))

            case let .patchResponse(.failure(error)):
                state.isWorking = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .deleteResponse(.success(id)):
                state.isWorking = false
                return .send(.delegate(.deleted(id: id)))

            case let .deleteResponse(.failure(error)):
                state.isWorking = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .editForm(.presented(.delegate(.saved(product)))):
                state.product = product
                return .send(.delegate(.updated(product)))

            case .editForm:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$editForm, action: \.editForm) {
            ProductFormFeature()
        }
        .ifLet(\.$deleteConfirm, action: \.deleteConfirm)
        #if DEBUG
        ._printChanges()   // logs every action + state diff for this feature
        #endif
    }
}
