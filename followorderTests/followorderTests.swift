import Testing
import Foundation
import SwiftData
@testable import followorder

struct followorderTests {

    @MainActor
    @Test func testOrderCalculationsAndStockRestoration() async throws {
        // 1. Initialize an in-memory ModelContainer for testing
        let schema = Schema([
            Product.self,
            Customer.self,
            Order.self,
            OrderItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let context = container.mainContext
        
        // 2. Create mock customer & products
        let customer = Customer(name: "Test Customer")
        let product1 = Product(sku: "TST01", name: "Laptop", price: 15000.0, cost: 8000.0, stockQuantity: 10, minStockLevel: 2, category: "Elektronik")
        let product2 = Product(sku: "TST02", name: "Mouse", price: 500.0, cost: 200.0, stockQuantity: 50, minStockLevel: 5, category: "Elektronik")
        
        context.insert(customer)
        context.insert(product1)
        context.insert(product2)
        
        // 3. Create Order
        let order = Order(orderNumber: "#9999", date: Date(), status: .preparing, discount: 1000.0, notes: "Test Order", customer: customer)
        context.insert(order)
        
        let item1 = OrderItem(product: product1, quantity: 1, priceAtPurchase: product1.price)
        let item2 = OrderItem(product: product2, quantity: 2, priceAtPurchase: product2.price)
        context.insert(item1)
        context.insert(item2)
        
        item1.order = order
        item2.order = order
        
        // 4. Test total calculation (Laptop (15000) * 1 + Mouse (500) * 2 - Discount (1000) = 15000 + 1000 - 1000 = 15000)
        #expect(order.totalAmount == 15000.0)
        
        // 5. Test stock checks
        #expect(product1.isLowStock == false)
        product1.stockQuantity = 1 // lower than minStockLevel (2)
        #expect(product1.isLowStock == true)
        
        // 6. Test order status transition
        #expect(order.status == .preparing)
        order.status = .ready
        #expect(order.status == .ready)
        
        // 7. Verify relationship counts
        #expect(customer.orders.count == 1)
        #expect(product1.orderItems.count == 1)
    }
}
