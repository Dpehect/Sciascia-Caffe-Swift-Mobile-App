import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var allOrders: [Order]
    @Query private var allProducts: [Product]
    
    @State private var themeManager = ThemeManager.shared
    
    // Financial math
    var totalRevenue: Double {
        allOrders.filter { $0.status != .cancelled }.reduce(0.0) { $0 + $1.totalAmount }
    }
    
    var totalCost: Double {
        var sum = 0.0
        for order in allOrders {
            guard order.status != .cancelled else { continue }
            for item in order.items {
                if let product = item.product {
                    sum += product.cost * Double(item.quantity)
                }
            }
        }
        return sum
    }
    
    var netProfit: Double {
        max(0.0, totalRevenue - totalCost)
    }
    
    var profitMarginPercentage: Double {
        guard totalRevenue > 0 else { return 0.0 }
        return (netProfit / totalRevenue) * 100.0
    }
    
    // Weekly Sales structures
    struct DailyRevenue: Identifiable {
        let id = UUID()
        let dayName: String
        let revenue: Double
    }
    
    var dailyRevenueData: [DailyRevenue] {
        let calendar = Calendar.current
        var list: [DailyRevenue] = []
        
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let dayName = date.formatted(.dateTime.weekday(.abbreviated))
                let revenueOfDay = allOrders.filter {
                    calendar.isDate($0.date, inSameDayAs: date) && $0.status != .cancelled
                }.reduce(0.0) { $0 + $1.totalAmount }
                
                list.append(DailyRevenue(dayName: dayName, revenue: revenueOfDay))
            }
        }
        return list
    }
    
    // Categories Share structures
    struct CategoryShare: Identifiable {
        let id = UUID()
        let category: String
        let salesCount: Int
    }
    
    var categoryShareData: [CategoryShare] {
        var dict: [String: Int] = [:]
        for order in allOrders {
            guard order.status != .cancelled else { continue }
            for item in order.items {
                if let product = item.product {
                    dict[product.category, default: 0] += item.quantity
                }
            }
        }
        return dict.map { CategoryShare(category: $0.key, salesCount: $0.value) }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 1. High-Level Summary Card
                    financialOverviewSection
                    
                    // 2. Circular Gauge Net Margin
                    profitMarginGaugeSection
                    
                    // 3. Swift Charts Bar chart
                    weeklyRevenueChartSection
                    
                    // 4. Swift Charts Pie chart
                    categoryShareChartSection
                    
                    // 5. Theme Settings Drawer
                    themeSelectorSection
                }
                .padding()
                .padding(.bottom, 75) // Safety space for custom tab bar
            }
        }
        .navigationTitle("Analytics")
        .preferredColorScheme(.light)
    }
    
    // MARK: - Sections
    
    var financialOverviewSection: some View {
        let activeColor = themeManager.currentTheme.accentColor
        
        return GlassCard(accentColor: activeColor) {
            VStack(spacing: 12) {
                Text("FINANCIAL OVERVIEW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Gross Revenue")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                        Text("₺\(String(format: "%.0f", totalRevenue))")
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Operating Cost")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                        Text("₺\(String(format: "%.0f", totalCost))")
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Net Profit")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                        Text("₺\(String(format: "%.0f", netProfit))")
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(.statusReady) // Emerald
                    }
                }
            }
            .padding(16)
        }
    }
    
    var profitMarginGaugeSection: some View {
        GlassCard(accentColor: .goldenYellow) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NET PROFIT MARGIN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.goldenYellow)
                        .tracking(1)
                    
                    Text("Measures the net profit margin generated relative to gross sales.")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Circular Gauge
                Gauge(value: profitMarginPercentage, in: 0...100) {
                    Text("Margin")
                } currentValueLabel: {
                    Text(String(format: "%.0f%%", profitMarginPercentage))
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.textPrimary)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(
                    LinearGradient(
                        colors: [.warmOrange, .goldenYellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(1.3)
                .padding(.trailing, 10)
            }
            .padding(16)
        }
    }
    
    var weeklyRevenueChartSection: some View {
        GlassCard(accentColor: themeManager.currentTheme.accentColor) {
            VStack(alignment: .leading, spacing: 14) {
                Text("WEEKLY SALES TREND")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(1)
                
                Chart {
                    ForEach(dailyRevenueData) { item in
                        BarMark(
                            x: .value("Day", item.dayName),
                            y: .value("Revenue (₺)", item.revenue)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .frame(height: 160)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
            .padding(16)
        }
    }
    
    var categoryShareChartSection: some View {
        GlassCard(accentColor: .warmOrange) {
            VStack(alignment: .leading, spacing: 14) {
                Text("CATEGORY SALES SHARE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(1)
                
                if categoryShareData.isEmpty {
                    Text("No order data available to display sales distribution.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.vertical, 20)
                } else {
                    Chart {
                        ForEach(categoryShareData) { item in
                            SectorMark(
                                angle: .value("Count", item.salesCount),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .cornerRadius(4)
                            .foregroundStyle(by: .value("Category", item.category))
                        }
                    }
                    .frame(height: 160)
                }
            }
            .padding(16)
        }
    }
    
    var themeSelectorSection: some View {
        GlassCard(accentColor: .espressoBrown) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Sciascia Cafe Branding", systemImage: "paintbrush.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("Select visual highlight schemes matching Sciascia Caffè 1919 accents.")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                    .padding(.bottom, 4)
                
                VStack(spacing: 8) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button(action: {
                            HapticHelper.playImpact(style: .medium)
                            withAnimation(.easeInOut) {
                                themeManager.currentTheme = theme
                            }
                        }) {
                            HStack {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 12, height: 12)
                                
                                Text(theme.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.accentColor)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(themeManager.currentTheme == theme ? Color.textPrimary.opacity(0.04) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeManager.currentTheme == theme ? theme.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    AnalyticsView()
}
