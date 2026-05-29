import ComposableArchitecture
import Foundation

/// Create/edit form shared by POST (create) and PUT (full replace). It builds a
/// `ProductInput` from a name plus editable key/value rows, calls the right verb
/// based on `mode`, reports the saved object via `delegate`, and dismisses itself.
@Reducer
struct ProductFormFeature {
    @ObservableState
    struct State: Equatable {
        enum Mode: Equatable {
            case create
            case edit(id: String)
        }

        var mode: Mode
        var name: String
        var fields: [DataField]
        var isSaving = false
        var errorMessage: String?

        init(mode: Mode = .create, product: Product? = nil) {
            self.mode = mode
            self.name = product?.name ?? ""
            self.fields = (product?.data ?? [:])
                .sorted { $0.key < $1.key }
                .map { DataField(key: $0.key, value: $0.value.displayString) }
        }

        var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

        var title: String {
            switch mode {
            case .create: "New Product"
            case .edit: "Edit Product"
            }
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case addFieldTapped
        case deleteFields(IndexSet)
        case cancelTapped
        case saveTapped
        case saveResponse(Result<Product, APIError>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case saved(Product)
        }
    }

    @Dependency(\.productsClient) var productsClient
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .addFieldTapped:
                state.fields.append(DataField())
                return .none

            case let .deleteFields(offsets):
                for index in offsets.sorted(by: >) {
                    state.fields.remove(at: index)
                }
                return .none

            case .cancelTapped:
                return .run { _ in await dismiss() }

            case .saveTapped:
                guard state.isValid, !state.isSaving else { return .none }
                state.isSaving = true
                state.errorMessage = nil

                var data: [String: JSONValue] = [:]
                for field in state.fields {
                    let key = field.key.trimmingCharacters(in: .whitespaces)
                    guard !key.isEmpty else { continue }
                    data[key] = JSONValue(parsing: field.value)
                }
                let input = ProductInput(
                    name: state.name.trimmingCharacters(in: .whitespaces),
                    data: data
                )
                let mode = state.mode

                return .run { [productsClient] send in
                    do {
                        let product: Product
                        switch mode {
                        case .create:
                            #if DEBUG
                            print("🟢 [effect] POST create — calling productsClient.create…")
                            #endif
                            product = try await productsClient.create(input)
                        case let .edit(id):
                            product = try await productsClient.update(id, input)
                        }
                        #if DEBUG
                        print("🟢 [effect] server returned product id=\(product.id) — sending .saveResponse(.success)")
                        #endif
                        await send(.saveResponse(.success(product)))
                    } catch let error as APIError {
                        await send(.saveResponse(.failure(error)))
                    } catch {
                        await send(.saveResponse(.failure(.unknown(error.localizedDescription))))
                    }
                }

            case let .saveResponse(.success(product)):
                state.isSaving = false
                return .run { send in
                    await send(.delegate(.saved(product)))
                    await dismiss()
                }

            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none

            case .delegate:
                return .none
            }
        }
        #if DEBUG
        ._printChanges()   // logs every action + state diff for this feature
        #endif
    }
}
