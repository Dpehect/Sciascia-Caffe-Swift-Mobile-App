import SwiftUI
import SwiftData

struct OrderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var order: Order
    @State private var themeManager = ThemeManager.shared
    
    // PDF State
    @State private var shareURL: URL? = nil
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Status & Details Top Header
                    headerCard
                    
                    // Customer Details
                    customerDetailsCard
                    
                    // Ordered Items List
                    itemsCard
                    
                    // Summary and Calculations
                    summaryCard
                    
                    // Actions (Export & Delete)
                    actionButtons
                }
                .padding()
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(order.orderNumber)
        .onAppear {
            generateInvoiceURL()
        }
        .onChange(of: order.statusValue) { _, _ in
            generateInvoiceURL() // Regenerate if status updates
        }
    }
    
    // MARK: - Subviews
    
    var headerCard: some View {
        let activeColor = themeManager.currentTheme.accentColor
        
        return GlassCard(accentColor: activeColor) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sipariş Durumu")
                            .font(.caption)
                            .foregroundColor(.gray)
                        StatusBadge(status: order.status)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Tarih")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(order.date.formatted(date: .numeric, time: .shortened))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Status Switcher
                VStack(alignment: .leading, spacing: 10) {
                    Text("Durumu Güncelle")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        statusButton(status: .preparing)
                        statusButton(status: .ready)
                        statusButton(status: .delivered)
                        statusButton(status: .cancelled)
                    }
                }
            }
            .padding(16)
        }
    }
    
    func statusButton(status: OrderStatus) -> some View {
        let isCurrent = order.status == status
        var buttonColor = Color.gray
        
        switch status {
        case .preparing: buttonColor = .statusPreparing
        case .ready: buttonColor = .statusReady
        case .delivered: buttonColor = .statusDelivered
        case .cancelled: buttonColor = .statusCancelled
        }
        
        return Button(action: {
            withAnimation(.snappy) {
                order.status = status
                try? modelContext.save()
            }
        }) {
            Text(status.localizedName.replacingOccurrences(of: " Edildi", with: ""))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isCurrent ? .white : buttonColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCurrent ? buttonColor : buttonColor.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(buttonColor.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    var customerDetailsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("MÜŞTERİ BİLGİLERİ")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                if let customer = order.customer {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                            Text(customer.name)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        if !customer.phone.isEmpty {
                            Label(customer.phone, systemImage: "phone.fill")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        if !customer.email.isEmpty {
                            Label(customer.email, systemImage: "envelope.fill")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        if !customer.address.isEmpty {
                            Label(customer.address, systemImage: "mappin.and.ellipse")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Label("Perakende Satış / Anonim Müşteri", systemImage: "person.crop.circle.badge.questionmark")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
        }
    }
    
    var itemsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("SİPARİŞ İÇERİĞİ")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                let items = order.items
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.product?.name ?? "Silinmiş Ürün")
                                .font(.body)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Birim Fiyat: ₺\(String(format: "%.2f", item.priceAtPurchase))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("x\(item.quantity)")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.trailing, 16)
                        
                        Text("₺\(String(format: "%.2f", item.priceAtPurchase * Double(item.quantity)))")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 4)
                    
                    if item.id != items.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.08))
                    }
                }
            }
            .padding(16)
        }
    }
    
    var summaryCard: some View {
        let activeColor = themeManager.currentTheme.accentColor
        let items = order.items
        let subtotal = items.reduce(0.0) { $0 + ($1.priceAtPurchase * Double($1.quantity)) }
        
        return GlassCard(accentColor: activeColor) {
            VStack(spacing: 8) {
                HStack {
                    Text("Ara Toplam")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("₺\(String(format: "%.2f", subtotal))")
                        .foregroundColor(.white)
                }
                
                if order.discount > 0 {
                    HStack {
                        Text("İndirim")
                            .foregroundColor(.statusCancelled)
                        Spacer()
                        Text("-₺\(String(format: "%.2f", order.discount))")
                            .foregroundColor(.statusCancelled)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.12))
                    .padding(.vertical, 4)
                
                HStack {
                    Text("Genel Toplam")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text("₺\(String(format: "%.2f", order.totalAmount))")
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(activeColor)
                }
                
                if let notes = order.notes, !notes.isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.12))
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notlar")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
    }
    
    var actionButtons: some View {
        VStack(spacing: 12) {
            if let shareURL = shareURL {
                ShareLink(item: shareURL) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Fatura Paylaş (PDF)")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeManager.currentTheme.themeGradient)
                    .cornerRadius(16)
                    .shadow(color: themeManager.currentTheme.accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
                }
            } else {
                Button(action: {}) {
                    HStack {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 8)
                        Text("Fatura Hazırlanıyor...")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(16)
                }
                .disabled(true)
            }
            
            Button(role: .destructive, action: deleteOrder) {
                Text("Siparişi Sil")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.statusCancelled)
                    .padding()
            }
        }
    }
    
    // MARK: - Helpers
    
    func generateInvoiceURL() {
        DispatchQueue.global(qos: .userInitiated).async {
            let url = PDFService.generateInvoice(for: self.order)
            DispatchQueue.main.async {
                self.shareURL = url
            }
        }
    }
    
    func deleteOrder() {
        // Safe deletion
        // Restore stock when order is deleted? Let's check!
        // Usually, if we delete an order, we might want to return products to stock.
        // Let's implement stock restoration as a premium database integrity feature!
        if order.status != .cancelled {
            for item in order.items {
                if let product = item.product {
                    product.stockQuantity += item.quantity
                }
            }
        }
        
        modelContext.delete(order)
        try? modelContext.save()
        dismiss()
    }
}
