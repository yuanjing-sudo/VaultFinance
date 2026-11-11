import SwiftUI

// MARK: - Generic Route Destination

/// Placeholder detail view for routes that don't have a dedicated screen yet.
/// Keeps deep breadcrumbs functional and navigable without deleting anything.
struct RouteDestinationView: View {
    let route: Route
    var subtitle: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: route.icon)
                .font(.system(size: 50))
                .foregroundColor(.blue)
            Text(route.label).font(.title2).bold()
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundColor(.secondary)
            }
            Text("Detail view for \(route.label) — navigate back with the breadcrumb trail above.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
