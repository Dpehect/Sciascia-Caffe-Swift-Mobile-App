import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Order.date, order: .reverse) private var recentOrders: [Order]
    @Query(sort: \Customer.name) private var customers: [Customer]
    
    @State private var themeManager = ThemeManager.shared
    @State private var isShowingARView = false
    @State private var successMessage: String? = nil
    @State private var isShowingSuccessAlert = false
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Italian Welcoming Header
                    welcomingHeader
                    
                    // 2. Immersive AR Menu Launch Card
                    arMenuHeroCard
                    
                    // 3. Loyalty Stamp Preview
                    loyaltyQuickWidget
                    
                    // 4. Quick Reorder Section
                    quickReorderSection
                }
                .padding()
                .padding(.bottom, 75) // Safety space for custom tab bar
            }
            
            // Confetti or Success Alert Overlay
            if isShowingSuccessAlert {
                successAlertOverlay
            }
        }
        .navigationDestination(isPresented: $isShowingARView) {
            ARMenuView()
        }
    }
    
    // MARK: - Sections
    
    var welcomingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("BUONGIORNO")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.goldenYellow)
                    .tracking(2)
                
                Text("Sciascia Caffè 1919")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.textPrimary)
                
                Text("Rome's Historic Espresso Excellence")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 24))
                .foregroundColor(.espressoBrown)
                .padding(14)
                .background(Color.themeCardBase)
                .clipShape(Circle())
                .shadow(color: Color.espressoBrown.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }
    
    var arMenuHeroCard: some View {
        Button(action: {
            HapticHelper.playImpact(style: .heavy)
            isShowingARView = true
        }) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "arkit")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("3D LIVE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Interactive AR Menu")
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    Text("Scan your table to view floating 3D espresso cups, pastries, allergens, and nutritional info directly in RealityKit.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
            }
            .padding(20)
            .frame(height: 180)
            .background(
                ZStack {
                    ThemeGradients.orange
                    
                    // Geometric circle highlights for luxury feel
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 200, height: 200)
                        .offset(x: 120, y: -40)
                }
            )
            .cornerRadius(24)
            .shadow(color: Color.warmOrange.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var loyaltyQuickWidget: some View {
        // Fetch first customer's loyalty stamps or mock preview
        let currentStamps = customers.first?.loyaltyStamps ?? 4
        let name = customers.first?.name.components(separatedBy: " ").first ?? "Guest"
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("YOUR LOYALTY CARD")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(1)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ciao, \(name)!")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    Text("You have earned \(currentStamps) stamps out of 10. Buy \(10 - currentStamps) more to claim a free Caffè Sciascia.")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Mini stamp count container
                HStack(spacing: 3) {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(.goldenYellow)
                    Text("\(currentStamps)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.creamyLatte)
                .cornerRadius(12)
            }
            .padding()
            .glassCard(cornerRadius: 18, accentColor: .goldenYellow)
        }
    }
    
    var quickReorderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK REORDER")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(1)
            
            if recentOrders.isEmpty {
                VStack(spacing: 8) {
                    Text("No order history records yet.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .glassCard(cornerRadius: 16)
            } else {
                VStack(spacing: 10) {
                    ForEach(recentOrders.prefix(2)) { order in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(order.orderNumber)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                
                                Text("\(order.items.count) item\(order.items.count > 1 ? "s" : "") • \(order.tableNumber ?? "Takeaway")")
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                duplicateOrder(order)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption.bold())
                                    Text("Reorder")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(themeManager.currentTheme.themeGradient)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.themeCardBase.opacity(0.4))
                        .cornerRadius(14)
                    }
                }
            }
        }
    }
    
    var successAlertOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.statusReady)
                
                Text("Order Placed!")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text(successMessage ?? "Your duplicated order was successfully sent to the barista queue.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .frame(width: 280)
            .background(Color.themeCardBase)
            .cornerRadius(20)
            .shadow(radius: 10)
            .transition(.scale.combined(with: .opacity))
        }
        .onTapGesture {
            withAnimation {
                isShowingSuccessAlert = false
            }
        }
    }
    
    // MARK: - Logic
    
    func duplicateOrder(_ order: Order) {
        HapticHelper.playImpact(style: .medium)
        
        let newNum = "#\(allOrderCount() + 1)"
        let newOrder = Order(
            orderNumber: newNum,
            date: Date(),
            status: .preparing,
            discount: order.discount,
            notes: order.notes,
            customer: order.customer,
            tableNumber: order.tableNumber
        )
        
        modelContext.insert(newOrder)
        
        // Duplicate items
        for item in order.items {
            if let product = item.product {
                let duplicatedItem = OrderItem(
                    product: product,
                    quantity: item.quantity,
                    priceAtPurchase: item.priceAtPurchase,
                    size: item.size,
                    milkType: item.milkType,
                    sweetness: item.sweetness,
                    toppings: item.toppings
                )
                modelContext.insert(duplicatedItem)
                duplicatedItem.order = newOrder
                
                // Decrease stock quantity
                product.stockQuantity = max(0, product.stockQuantity - item.quantity)
            }
        }
        
        do {
            try modelContext.save()
            successMessage = "Reordered successfully! New adisyon code is \(newNum)."
            withAnimation {
                isShowingSuccessAlert = true
            }
            HapticHelper.playNotification(type: .success)
            
            // Auto dismiss notification overlay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isShowingSuccessAlert = false
                }
            }
        } catch {
            print("Failed to duplicate order: \(error)")
        }
    }
    
    func allOrderCount() -> Int {
        // Safe query helper
        recentOrders.count + 1000
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Product.self, Customer.self, Order.self, OrderItem.self], inMemory: true)
}
