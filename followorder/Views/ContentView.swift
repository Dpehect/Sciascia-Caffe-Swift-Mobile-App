import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.themeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationStack {
                            HomeView()
                        }
                    case 1:
                        NavigationStack {
                            OrderListView()
                        }
                    case 2:
                        NavigationStack {
                            StockListView()
                        }
                    case 3:
                        NavigationStack {
                            CustomerListView()
                        }
                    case 4:
                        NavigationStack {
                            AnalyticsView()
                        }
                    default:
                        Text("Unknown Tab")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer(minLength: 85) // Padding for custom tab bar
            }
            
            customTabBar
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
        .preferredColorScheme(.light) // Luxurious light mode theme
    }
    
    var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, title: "Home", systemImage: "house.fill")
            tabButton(index: 1, title: "Orders", systemImage: "cup.and.saucer.fill")
            tabButton(index: 2, title: "Stock", systemImage: "shippingbox.fill")
            tabButton(index: 3, title: "Customers", systemImage: "person.2.fill")
            tabButton(index: 4, title: "Analytics", systemImage: "chart.line.uptrend.xyaxis")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .glassCard(cornerRadius: 24, accentColor: themeManager.currentTheme.accentColor)
    }
    
    func tabButton(index: Int, title: String, systemImage: String) -> some View {
        let isSelected = selectedTab == index
        let activeColor = themeManager.currentTheme.accentColor
        
        return Button(action: {
            HapticHelper.playImpact(style: .soft)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 17))
                    .foregroundStyle(
                        isSelected ?
                        AnyShapeStyle(themeManager.currentTheme.themeGradient) :
                        AnyShapeStyle(Color.textPrimary.opacity(0.35))
                    )
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .shadow(color: isSelected ? activeColor.opacity(0.3) : .clear, radius: 6, x: 0, y: 0)
                
                Text(title)
                    .font(.system(size: 9, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? .textPrimary : .textPrimary.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Product.self, Customer.self, Order.self, OrderItem.self], inMemory: true)
}
