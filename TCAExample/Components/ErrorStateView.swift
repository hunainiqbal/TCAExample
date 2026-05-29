import SwiftUI

/// Reusable full-screen empty/error state with a retry affordance, built on the
/// system `ContentUnavailableView`.
struct ErrorStateView: View {
    var title = "Something went wrong"
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ErrorStateView(
        title: "Couldn't load products",
        message: "Couldn't reach the server. Check your connection and try again."
    ) {}
}
