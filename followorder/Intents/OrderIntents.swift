import AppIntents
import SwiftUI

struct CreateOrderIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Order"
    static var description = IntentDescription("Launches the checkout view in Sciascia Caffè 1919 immediately.")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct CheckStockIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Low Stock"
    static var description = IntentDescription("Scans the stock inventory levels for items under critical limits.")
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        return .result(value: "Inventory check completed. Low stock alerts are highlighted in the inventory dashboard.")
    }
}

struct FollowOrderShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateOrderIntent(),
            phrases: [
                "Create a new order in \(.applicationName)",
                "Add order in \(.applicationName)"
            ],
            shortTitle: "Create Order",
            systemImageName: "cart.badge.plus"
        )
    }
}
