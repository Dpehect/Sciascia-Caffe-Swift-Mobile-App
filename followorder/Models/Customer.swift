import Foundation
import SwiftData

@Model
final class Customer {
    var id: UUID = UUID()
    var name: String
    var email: String
    var phone: String
    var address: String
    var loyaltyStamps: Int = 0 // Sadakat Damga Kartı sayacı
    
    var orders: [Order] = []
    
    init(name: String, email: String = "", phone: String = "", address: String = "", loyaltyStamps: Int = 0) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.loyaltyStamps = loyaltyStamps
        self.orders = []
    }
}
