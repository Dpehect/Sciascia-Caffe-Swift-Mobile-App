import SwiftUI
import SwiftData

struct OrderListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Order.date, order: .reverse) private var allOrders: [Order]
    
    @State private var searchText = ""
    @State private var selectedStatusFilter: OrderStatus? = nil
    @State private var isShowingNewOrderSheet = false
    @State private var themeManager = ThemeManager.shared
    
    // Live statistics
    var todaysOrders: [Order] {
        let calendar = Calendar.current
        return allOrders.filter { calendar.isDateInToday($0.date) && $0.status != .cancelled }
    }
    
    var todaysRevenue: Double {
        todaysOrders.reduce(0.0) { $0 + $1.totalAmount }
    }
    
    var filteredOrders: [Order] {
        allOrders.filter { order in
            let matchesStatus = selectedStatusFilter == nil || order.status == selectedStatusFilter
            
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let orderNumMatch = order.orderNumber.localizedCaseInsensitiveContains(searchText)
                let customerMatch = order.customer?.name.localizedCaseInsensitiveContains(searchText) ?? false
                let tableMatch = order.tableNumber?.localizedCaseInsensitiveContains(searchText) ?? false
                let notesMatch = order.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                matchesSearch = orderNumMatch || customerMatch || tableMatch || notesMatch
            }
            
            return matchesStatus && matchesSearch
        }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Daily Live Overview Header
                dailySummaryHeader
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // 2. Search & Filters
                searchAndFilterHeader
                    .padding(.horizontal)
                    .padding(.top, 14)
                
                // 3. Orders List
                if filteredOrders.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredOrders) { order in
                            ZStack(alignment: .leading) {
                                NavigationLink(value: order) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                orderCard(order: order)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if order.status != .delivered && order.status != .cancelled {
                                    Button {
                                        updateStatus(order: order, to: .delivered)
                                    } label: {
                                        Label("Serve", systemImage: "bell.fill")
                                    }
                                    .tint(.statusReady) // Emerald green
                                    
                                    Button {
                                        updateStatus(order: order, to: .cancelled)
                                    } label: {
                                        Label("Cancel", systemImage: "xmark.circle.fill")
                                    }
                                    .tint(.statusCancelled)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.top, 4)
                    .padding(.bottom, 75) // Safety margin for custom tab bar
                }
            }
            
            // FAB (Floating Action Button) - Create Order
            floatingActionButtons
        }
        .navigationTitle("Order Tracking")
        .sheet(isPresented: $isShowingNewOrderSheet) {
            NewOrderView()
        }
    }
    
    // MARK: - Subviews
    
    var dailySummaryHeader: some View {
        let activeColor = themeManager.currentTheme.accentColor
        
        return GlassCard(accentColor: .goldenYellow) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SCIASCI CAFFÈ 1919 (LIVE)")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.textSecondary)
                        .tracking(1)
                    
                    HStack(spacing: 4) {
                        Text("₺\(String(format: "%.2f", todaysRevenue))")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.textPrimary)
                            .shadow(color: .goldenYellow.opacity(0.15), radius: 6, x: 0, y: 0)
                    }
                    
                    Text("\(todaysOrders.count) orders served today")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Mini Live Target Progress Ring
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.textPrimary.opacity(0.04), lineWidth: 6)
                            .frame(width: 50, height: 50)
                        
                        let progress = min(1.0, Double(todaysOrders.count) / 15.0) // Goal of 15 orders
                        Circle()
                            .trim(from: 0.0, to: progress)
                            .stroke(
                                LinearGradient(colors: [.warmOrange, activeColor], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                        
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .padding(16)
        }
    }
    
    var searchAndFilterHeader: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textPrimary.opacity(0.4))
                TextField("Search by table, order no, customer...", text: $searchText)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textPrimary.opacity(0.4))
                    }
                }
            }
            .padding(10)
            .background(Color.themeCardBase)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.textPrimary.opacity(0.08), lineWidth: 1)
            )
            
            // Status filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterButton(title: "All", status: nil)
                    ForEach(OrderStatus.allCases, id: \.self) { status in
                        filterButton(title: status.localizedName, status: status)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    func filterButton(title: String, status: OrderStatus?) -> some View {
        let isSelected = selectedStatusFilter == status
        let activeColor = themeManager.currentTheme.accentColor
        
        return Button(action: {
            HapticHelper.playImpact(style: .light)
            withAnimation(.snappy(duration: 0.2)) {
                selectedStatusFilter = status
            }
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : .textPrimary.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(themeManager.currentTheme.themeGradient) : AnyShapeStyle(Color.themeCardBase))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ?
                            AnyBorderGradient(activeColor) :
                            AnyBorderGradient(Color.textPrimary.opacity(0.08)),
                            lineWidth: 1
                        )
                )
        }
    }
    
    func orderCard(order: Order) -> some View {
        let activeColor = themeManager.currentTheme.accentColor
        
        return GlassCard(accentColor: activeColor) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 8) {
                    Text(order.orderNumber)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.textPrimary)
                    
                    if let tableNum = order.tableNumber {
                        Text("• \(tableNum)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.warmOrange)
                    }
                    
                    Spacer()
                    
                    StatusBadge(status: order.status)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(order.customer?.name ?? "Anonymous Order", systemImage: "cup.and.saucer.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary.opacity(0.85))
                        
                        Text(order.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "₺%.2f", order.totalAmount))
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.textPrimary)
                        
                        let itemCount = order.items.reduce(0) { $0 + $1.quantity }
                        Text("\(itemCount) cup\(itemCount > 1 ? "s" : "") / pastry")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Customize detail overview
                if !order.items.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(order.items) { item in
                                Text("\(item.product?.name ?? "") x\(item.quantity) (\(item.size), \(item.milkType))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.textPrimary.opacity(0.04)))
                            }
                        }
                    }
                    .padding(.top, 2)
                }
                
                if let notes = order.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .italic()
                        .foregroundColor(.textSecondary)
                        .padding(.top, 2)
                        .lineLimit(1)
                }
            }
            .padding(16)
        }
        .buttonStyle(PremiumCardButtonStyle())
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "cup.and.saucer")
                .font(.system(size: 60))
                .foregroundColor(.textPrimary.opacity(0.2))
            
            Text("No Orders Found")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text(searchText.isEmpty ? "No active orders have been taken yet. Tap the '+' button in the bottom right corner to add an order." : "No orders matched your search criteria.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
    
    var floatingActionButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    HapticHelper.playImpact(style: .medium)
                    isShowingNewOrderSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(16)
                        .background(themeManager.currentTheme.themeGradient)
                        .clipShape(Circle())
                        .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 95)
            }
        }
    }
    
    // Helpers
    func updateStatus(order: Order, to newStatus: OrderStatus) {
        HapticHelper.playNotification(type: .success)
        withAnimation {
            order.status = newStatus
            try? modelContext.save()
        }
    }
    
    // Custom gradient borders builder helper
    private func AnyBorderGradient(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    OrderListView()
        .modelContainer(for: [Product.self, Customer.self, Order.self, OrderItem.self], inMemory: true)
}
