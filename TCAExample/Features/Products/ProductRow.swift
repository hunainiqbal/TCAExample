import SwiftUI

/// A single row in the products list: object name plus a short summary of its data.
struct ProductRow: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(product.name)
                .font(.headline)
                .lineLimit(1)
            if let subtitle = product.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ProductRow(product: .preview)
    }
}
