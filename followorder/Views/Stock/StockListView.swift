import SwiftUI
import SwiftData

struct StockListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    
    // Authorization States
    @State private var isUnlocked = false
    @State private var authErrorText: String? = nil
    
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var isShowingScanner = false
    @State private var isShowingAddProduct = false
    @State private var selectedProductForEdit: Product? = nil
    
    // Quick stock edit
    @State private var quickEditProduct: Product? = nil
    @State private var quickStockAmount = ""
    @State private var isShowingQuickEdit = false
    
    // Scanning result mapping
    @State private var scannedCodeToCreate: String? = nil
    
    @State private var themeManager = ThemeManager.shared
    
    var categories: [String] {
        let distinct = Array(Set(products.map { $0.category }))
        return ["All"] + distinct.sorted()
    }
    
    var filteredProducts: [Product] {
        products.filter { product in
            let matchesCategory = selectedCategory == "All" || product.category == selectedCategory
            
            let matchesSearch: Bool
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                let nameMatch = product.name.localizedCaseInsensitiveContains(searchText)
                let skuMatch = product.sku.localizedCaseInsensitiveContains(searchText)
                let catMatch = product.category.localizedCaseInsensitiveContains(searchText)
                matchesSearch = nameMatch || skuMatch || catMatch
            }
            
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            if isUnlocked {
                VStack(spacing: 0) {
                    // Search & Filter Header
                    searchAndFilterHeader
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Products List
                    if filteredProducts.isEmpty {
                        emptyStateView
                    } else {
                        List {
                            ForEach(filteredProducts) { product in
                                productRow(product: product)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            quickStockEditTrigger(product)
                                        } label: {
                                            Label("Quick Stock", systemImage: "plus.forwardslash.minus")
                                        }
                                        .tint(themeManager.currentTheme.accentColor)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            deleteProduct(product)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.top, 4)
                        .padding(.bottom, 75) // Safety margin for floating tab bar
                    }
                }
                
                // FAB buttons (Barcode Scan & Add Product)
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Spacer()
                        
                        // Barcode scan FAB
                        Button(action: {
                            isShowingScanner = true
                        }) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .padding(14)
                                .background(themeManager.currentTheme.accentColor.opacity(0.85))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
                        }
                        
                        // Add Product FAB
                        Button(action: {
                            scannedCodeToCreate = nil
                            isShowingAddProduct = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .padding(15)
                                .background(themeManager.currentTheme.themeGradient)
                                .clipShape(Circle())
                                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 95)
                }
            } else {
                // Lock Screen
                lockScreenView
            }
        }
        .navigationTitle("Inventory Control")
        .sheet(isPresented: $isShowingScanner) {
            barcodeScannerSheet
        }
        .sheet(isPresented: $isShowingAddProduct) {
            ProductDetailView(scannedSku: scannedCodeToCreate)
        }
        .sheet(item: $selectedProductForEdit) { product in
            ProductDetailView(product: product)
        }
        .sheet(isPresented: $isShowingQuickEdit) {
            quickStockEditSheet
        }
        .onAppear(perform: triggerBiometricAuthentication)
    }
    
    // MARK: - Lock Screen
    
    var lockScreenView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.warmOrange)
                .padding(.bottom, 10)
            
            Text("Staff Mode Locked")
                .font(.title2)
                .fontWeight(.black)
                .foregroundColor(.textPrimary)
            
            Text("Biometric verification (Face ID) is required to view and edit cafe inventory levels.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let error = authErrorText {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.statusCancelled)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: triggerBiometricAuthentication) {
                Label("Authenticate with Face ID", systemImage: "faceid")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(themeManager.currentTheme.themeGradient)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .padding()
        .glassCard()
        .padding(24)
    }
    
    // MARK: - Subviews
    
    var searchAndFilterHeader: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textPrimary.opacity(0.4))
                TextField("Search product, SKU, or category...", text: $searchText)
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
            
            // Category scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        categoryFilterButton(title: category)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    func categoryFilterButton(title: String) -> some View {
        let isSelected = selectedCategory == title
        let activeColor = themeManager.currentTheme.accentColor
        
        return Button(action: {
            withAnimation(.snappy(duration: 0.2)) {
                selectedCategory = title
            }
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? activeColor.opacity(0.25) : Color.themeCardBase.opacity(0.4))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? activeColor.opacity(0.5) : Color.textPrimary.opacity(0.08), lineWidth: 1)
                )
        }
    }
    
    func productRow(product: Product) -> some View {
        let activeColor = themeManager.currentTheme.accentColor
        
        return Button(action: {
            selectedProductForEdit = product
        }) {
            GlassCard(accentColor: product.isLowStock ? .statusCancelled : activeColor) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(product.name)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            Text(product.category)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.textPrimary.opacity(0.04)))
                            
                            Text("SKU: \(product.sku)")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("₺\(String(format: "%.2f", product.price))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 4) {
                            if product.isLowStock {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.statusCancelled)
                            }
                            
                            Text("\(product.stockQuantity) Units")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(product.isLowStock ? .statusCancelled : .statusReady)
                        }
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "archivebox")
                .font(.system(size: 60))
                .foregroundColor(.textPrimary.opacity(0.2))
            
            Text("No Products Found")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text(searchText.isEmpty ? "No products registered in stock. Start by creating a new product." : "No products matched your search parameters.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
    
    var barcodeScannerSheet: some View {
        NavigationStack {
            BarcodeScannerView { barcode in
                isShowingScanner = false
                handleScannedBarcode(barcode)
            }
            .ignoresSafeArea()
            .navigationTitle("Scan Product Barcode")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isShowingScanner = false }.foregroundColor(.white)
                }
            }
        }
    }
    
    var quickStockEditSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let product = quickEditProduct {
                        Text(product.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text("Current Stock: \(product.stockQuantity) Units")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        HStack {
                            Button(action: {
                                adjustStock(amount: -1)
                            }) {
                                Image(systemName: "minus.square.fill")
                                    .font(.title)
                                    .foregroundColor(.statusCancelled)
                            }
                            
                            TextField("Adjustment Amount", text: $quickStockAmount)
                                .padding()
                                .background(Color.themeCardBase.opacity(0.8))
                                .cornerRadius(10)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 140)
                            
                            Button(action: {
                                adjustStock(amount: 1)
                            }) {
                                Image(systemName: "plus.square.fill")
                                    .font(.title)
                                    .foregroundColor(.statusReady)
                            }
                        }
                        .padding(.vertical)
                        
                        HStack(spacing: 16) {
                            Button("Remove") {
                                applyStockAdjustment(add: false)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.statusCancelled.opacity(0.95))
                            .cornerRadius(12)
                            
                            Button("Add") {
                                applyStockAdjustment(add: true)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.statusReady.opacity(0.95))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Quick Stock Update")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isShowingQuickEdit = false }.foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    func triggerBiometricAuthentication() {
        BiometricHelper.authenticateUser { success, error in
            if success {
                isUnlocked = true
                authErrorText = nil
            } else {
                isUnlocked = false
                authErrorText = error ?? "Verification failed."
            }
        }
    }
    
    func quickStockEditTrigger(_ product: Product) {
        quickEditProduct = product
        quickStockAmount = "1"
        isShowingQuickEdit = true
    }
    
    func adjustStock(amount: Int) {
        if let current = Int(quickStockAmount) {
            let next = max(1, current + amount)
            quickStockAmount = "\(next)"
        } else {
            quickStockAmount = "1"
        }
    }
    
    func applyStockAdjustment(add: Bool) {
        guard let product = quickEditProduct, let amt = Int(quickStockAmount) else { return }
        
        withAnimation {
            if add {
                product.stockQuantity += amt
            } else {
                product.stockQuantity = max(0, product.stockQuantity - amt)
            }
            try? modelContext.save()
        }
        isShowingQuickEdit = false
    }
    
    func handleScannedBarcode(_ barcode: String) {
        if let match = products.first(where: { $0.sku == barcode }) {
            selectedProductForEdit = match
        } else {
            scannedCodeToCreate = barcode
            isShowingAddProduct = true
        }
    }
    
    func deleteProduct(_ product: Product) {
        withAnimation {
            modelContext.delete(product)
            try? modelContext.save()
        }
    }
}
