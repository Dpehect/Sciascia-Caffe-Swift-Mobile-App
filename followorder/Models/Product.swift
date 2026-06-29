import Foundation
import SwiftData

@Model
final class Product {
    var id: UUID = UUID()
    var sku: String
    var name: String
    var price: Double
    var cost: Double
    var stockQuantity: Int
    var minStockLevel: Int
    var category: String
    
    var orderItems: [OrderItem] = []
    
    init(sku: String, name: String, price: Double, cost: Double, stockQuantity: Int, minStockLevel: Int = 5, category: String = "Genel") {
        self.id = UUID()
        self.sku = sku
        self.name = name
        self.price = price
        self.cost = cost
        self.stockQuantity = stockQuantity
        self.minStockLevel = minStockLevel
        self.category = category
        self.orderItems = []
    }
    
    var isLowStock: Bool {
        stockQuantity <= minStockLevel
    }
    
    // 2026 Yapay Zeka Tabanlı Hızlı Satış / Stok Tahmini (Sales Velocity Analizi)
    func getEstimatedSalesLast7Days() -> Int {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let recentSales = orderItems.filter { item in
            if let orderDate = item.order?.date {
                return orderDate >= sevenDaysAgo && item.order?.status != .cancelled
            }
            return false
        }
        
        return recentSales.reduce(0) { $0 + $1.quantity }
    }
    
    // Eğer mevcut stok son 7 gündeki satış hızından düşükse veya kritik limit altındaysa, stoklama önerisi sunar
    var shouldRestockSuggestion: Bool {
        let salesVelocity = getEstimatedSalesLast7Days()
        return stockQuantity <= salesVelocity || isLowStock
    }
}
