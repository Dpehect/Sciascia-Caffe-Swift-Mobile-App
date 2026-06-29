import SwiftUI

struct StatusBadge: View {
    var status: OrderStatus
    
    var body: some View {
        Text(status.localizedName.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(badgeColor.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(badgeColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var badgeColor: Color {
        switch status {
        case .preparing:
            return .statusPreparing
        case .ready:
            return .statusReady
        case .delivered:
            return .statusDelivered
        case .cancelled:
            return .statusCancelled
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        StatusBadge(status: .preparing)
        StatusBadge(status: .ready)
        StatusBadge(status: .delivered)
        StatusBadge(status: .cancelled)
    }
    .padding()
    .background(Color.themeBackground)
}
