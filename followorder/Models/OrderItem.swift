import Foundation
import SwiftData

@Model
final class OrderItem {
    var id: UUID = UUID()
    var quantity: Int
    var priceAtPurchase: Double
    
    // Cafe Özelleştirmeleri
    var size: String = "Medium"
    var milkType: String = "Normal"
    var sweetness: String = "Normal"
    var toppings: String = "" // Virgülle ayrılmış eklemeler (örn: "Ekstra Shot, Karamel Şurup")
    
    @Relationship(deleteRule: .nullify, inverse: \Product.orderItems)
    var product: Product?
    
    var order: Order?
    
    init(product: Product, quantity: Int, priceAtPurchase: Double, size: String = "Medium", milkType: String = "Normal", sweetness: String = "Normal", toppings: String = "") {
        self.id = UUID()
        self.product = product
        self.quantity = quantity
        self.priceAtPurchase = priceAtPurchase
        self.size = size
        self.milkType = milkType
        self.sweetness = sweetness
        self.toppings = toppings
    }
}
