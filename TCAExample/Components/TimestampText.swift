import SwiftUI

/// Renders an ISO-8601 timestamp string from the API as a localized date/time,
/// falling back to the raw string if it can't be parsed.
struct TimestampText: View {
    let iso: String

    var body: some View {
        if let date = try? Date(iso, strategy: .iso8601) {
            Text(date, format: .dateTime.month().day().year().hour().minute())
        } else {
            Text(iso)
        }
    }
}

#Preview {
    List {
        TimestampText(iso: "2022-11-21T20:06:23.986Z")
        TimestampText(iso: "not-a-date")
    }
}
