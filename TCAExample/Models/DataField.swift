import Foundation

/// An editable key/value row used by the create/edit form to build an object's
/// free-form `data` dictionary.
struct DataField: Equatable, Identifiable, Sendable {
    let id: UUID
    var key: String
    var value: String

    init(id: UUID = UUID(), key: String = "", value: String = "") {
        self.id = id
        self.key = key
        self.value = value
    }
}
