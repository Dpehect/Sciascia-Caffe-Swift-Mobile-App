import Foundation
import SwiftData

enum OrderStatus: String, Codable, CaseIterable {
    case preparing = "preparing"
    case ready = "ready"
    case delivered = "delivered"
    case cancelled = "cancelled"
    
    var localizedName: String {
        switch self {
        case .preparing: return "Preparing"
        case .ready: return "Ready"
        case .delivered: return "Served"
        case .cancelled: return "Cancelled"
        }
    }
}

@Model
final class Order {
    var id: UUID = UUID()
    var orderNumber: String
    var date: Date
    var statusValue: String
    var discount: Double
    var notes: String?
    var tableNumber: String? // Table number or "Takeaway"
    
    @Relationship(deleteRule: .nullify, inverse: \Customer.orders)
    var customer: Customer?
    
    @Relationship(deleteRule: .cascade, inverse: \OrderItem.order)
    var items: [OrderItem] = []
    
    init(orderNumber: String, date: Date = Date(), status: OrderStatus = .preparing, discount: Double = 0.0, notes: String? = nil, customer: Customer? = nil, tableNumber: String? = nil) {
        self.id = UUID()
        self.orderNumber = orderNumber
        self.date = date
        self.statusValue = status.rawValue
        self.discount = discount
        self.notes = notes
        self.customer = customer
        self.tableNumber = tableNumber
        self.items = []
    }
    
    var status: OrderStatus {
        get {
            OrderStatus(rawValue: statusValue) ?? .preparing
        }
        set {
            statusValue = newValue.rawValue
        }
    }
    
    var totalAmount: Double {
        let itemsTotal = items.reduce(0.0) { sum, item in
            sum + (item.priceAtPurchase * Double(item.quantity))
        }
        return max(0.0, itemsTotal - discount)
    }
}
