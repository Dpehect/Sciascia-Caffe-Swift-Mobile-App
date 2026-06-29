import SwiftUI
import SwiftData
import TipKit

@main
struct followorderApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Product.self,
                Customer.self,
                Order.self,
                OrderItem.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Seed mock data if database is empty
            seedMockDataIfNeeded()
            
            // TipKit Konfigürasyonu
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
    
    @MainActor
    private func seedMockDataIfNeeded() {
        let context = container.mainContext
        
        // Ürünler boşsa tohumlama yap
        let productDescriptor = FetchDescriptor<Product>()
        guard let existingProducts = try? context.fetch(productDescriptor), existingProducts.isEmpty else {
            return
        }
        
        // 1. Sciascia Caffè 1919 English Menu Seeding
        let p1 = Product(sku: "SC-01", name: "Caffè Sciascia 1919", price: 65.0, cost: 14.0, stockQuantity: 200, minStockLevel: 25, category: "Espresso Classics")
        let p2 = Product(sku: "SC-02", name: "Granita di Caffè", price: 85.0, cost: 18.0, stockQuantity: 90, minStockLevel: 15, category: "Cold Beverages")
        let p3 = Product(sku: "SC-03", name: "Cappuccino Sciascia", price: 80.0, cost: 20.0, stockQuantity: 120, minStockLevel: 15, category: "Espresso Classics")
        let p4 = Product(sku: "SC-04", name: "Caffè Macchiato", price: 60.0, cost: 12.0, stockQuantity: 80, minStockLevel: 10, category: "Espresso Classics")
        let p5 = Product(sku: "SC-05", name: "Sfogliatella Napoletana", price: 75.0, cost: 26.0, stockQuantity: 6, minStockLevel: 10, category: "Italian Pastries") // Low Stock!
        let p6 = Product(sku: "SC-06", name: "Cannoli Siciliani", price: 80.0, cost: 28.0, stockQuantity: 40, minStockLevel: 12, category: "Italian Pastries")
        let p7 = Product(sku: "SC-07", name: "Tiramisù Classico", price: 120.0, cost: 40.0, stockQuantity: 25, minStockLevel: 5, category: "Classic Desserts")
        let p8 = Product(sku: "SC-08", name: "Cornetto al Pistacchio", price: 85.0, cost: 30.0, stockQuantity: 30, minStockLevel: 8, category: "Italian Pastries")
        
        context.insert(p1)
        context.insert(p2)
        context.insert(p3)
        context.insert(p4)
        context.insert(p5)
        context.insert(p6)
        context.insert(p7)
        context.insert(p8)
        
        // 2. Mock English Customers
        let c1 = Customer(name: "Alexander Wright", email: "alex.w@email.com", phone: "0532 111 2233", address: "Rome, Italy", loyaltyStamps: 4)
        let c2 = Customer(name: "Eleanor Smith", email: "eleanor.s@email.com", phone: "0542 222 3344", address: "Milan, Italy", loyaltyStamps: 8)
        let c3 = Customer(name: "Charles Miller", email: "charles.m@email.com", phone: "0505 333 4455", address: "Florence, Italy", loyaltyStamps: 2)
        
        context.insert(c1)
        context.insert(c2)
        context.insert(c3)
        
        // 3. Mock Order History (English Notes)
        let calendar = Calendar.current
        let today = Date()
        
        // Order 1 (Served - 2 days ago - Table 2)
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let o1 = Order(orderNumber: "#1001", date: twoDaysAgo, status: .delivered, discount: 10.0, notes: "Extra cocoa powder on top, please.", customer: c1, tableNumber: "Table 2")
        context.insert(o1)
        
        let item1_1 = OrderItem(product: p1, quantity: 1, priceAtPurchase: p1.price, size: "Single", milkType: "None", sweetness: "Sade")
        context.insert(item1_1)
        item1_1.order = o1
        
        let item1_2 = OrderItem(product: p5, quantity: 2, priceAtPurchase: p5.price)
        context.insert(item1_2)
        item1_2.order = o1
        
        // Order 2 (Preparing - 1 day ago - Table 5)
        let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: today)!
        let o2 = Order(orderNumber: "#1002", date: oneDayAgo, status: .preparing, discount: 0.0, notes: "Oat milk macchiato.", customer: c2, tableNumber: "Table 5")
        context.insert(o2)
        
        let item2_1 = OrderItem(product: p4, quantity: 2, priceAtPurchase: p4.price, size: "Double", milkType: "Oat Milk", sweetness: "Regular")
        context.insert(item2_1)
        item2_1.order = o2
        
        let item2_2 = OrderItem(product: p6, quantity: 2, priceAtPurchase: p6.price)
        context.insert(item2_2)
        item2_2.order = o2
        
        // Order 3 (Ready - Today - Takeaway)
        let o3 = Order(orderNumber: "#1003", date: today, status: .ready, discount: 0.0, notes: "For takeaway.", customer: c3, tableNumber: "Takeaway")
        context.insert(o3)
        
        let item3_1 = OrderItem(product: p3, quantity: 1, priceAtPurchase: p3.price, size: "Medium", milkType: "Regular", sweetness: "Regular")
        context.insert(item3_1)
        item3_1.order = o3
        
        let item3_2 = OrderItem(product: p7, quantity: 1, priceAtPurchase: p7.price)
        context.insert(item3_2)
        item3_2.order = o3
        
        // Save database changes
        try? context.save()
    }
}
