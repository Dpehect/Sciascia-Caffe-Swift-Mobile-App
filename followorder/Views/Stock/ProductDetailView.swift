import SwiftUI
import SwiftData

struct ProductDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // If editing existing
    var product: Product? = nil
    
    // If prefilled from scanner
    var scannedSku: String? = nil
    
    // Theme
    @State private var themeManager = ThemeManager.shared
    
    // Form States
    @State private var name = ""
    @State private var sku = ""
    @State private var category = "Genel"
    @State private var priceText = ""
    @State private var costText = ""
    @State private var stockQuantityText = ""
    @State private var minStockLevelText = "5"
    
    // Scanner
    @State private var isShowingScanner = false
    
    // Validation alert
    @State private var errorMessage: String? = nil
    @State private var isShowingErrorAlert = false
    
    // Standard categories list
    let categoriesList = ["Genel", "Gıda", "Tekstil", "Elektronik", "Hizmet", "Kozmetik", "Aksesuar", "Diğer"]
    
    var isEditing: Bool {
        product != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground
                    .ignoresSafeArea()
                
                Form {
                    Section("Ürün Tanımı") {
                        TextField("Ürün Adı", text: $name)
                            .foregroundColor(.white)
                        
                        HStack {
                            TextField("Barkod (SKU)", text: $sku)
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                            
                            Button(action: {
                                isShowingScanner = true
                            }) {
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundColor(themeManager.currentTheme.accentColor)
                            }
                        }
                        
                        Picker("Kategori", selection: $category) {
                            ForEach(categoriesList, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .adaptivePickerStyle()
                    }
                    .listRowBackground(Color.themeCardBase.opacity(0.4))
                    
                    Section("Fiyatlandırma & Maliyet") {
                        HStack {
                            Text("Satış Fiyatı (₺)")
                            Spacer()
                            TextField("0.00", text: $priceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Birim Maliyet (₺)")
                            Spacer()
                            TextField("0.00", text: $costText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.themeCardBase.opacity(0.4))
                    
                    Section("Stok Takibi") {
                        HStack {
                            Text("Mevcut Stok Adedi")
                            Spacer()
                            TextField("0", text: $stockQuantityText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Kritik Stok Alarm Eşiği")
                            Spacer()
                            TextField("5", text: $minStockLevelText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color.themeCardBase.opacity(0.4))
                }
                .scrollContentBackground(.hidden)
                .navigationTitle(isEditing ? "Ürünü Düzenle" : "Yeni Ürün Ekle")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("İptal") {
                            dismiss()
                        }
                        .foregroundColor(.gray)
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Kaydet") {
                            saveProduct()
                        }
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
                .sheet(isPresented: $isShowingScanner) {
                    barcodeScannerSheet
                }
                .alert("Hata", isPresented: $isShowingErrorAlert, presenting: errorMessage) { _ in
                    Button("Tamam") {}
                } message: { msg in
                    Text(msg)
                }
                .onAppear {
                    loadProductDetails()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    
    var barcodeScannerSheet: some View {
        NavigationStack {
            BarcodeScannerView { barcode in
                sku = barcode
                isShowingScanner = false
            }
            .ignoresSafeArea()
            .navigationTitle("Barkod Tarayıcı")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { isShowingScanner = false }.foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Logic
    
    func loadProductDetails() {
        if let product = product {
            name = product.name
            sku = product.sku
            category = product.category
            priceText = String(format: "%.2f", product.price)
            costText = String(format: "%.2f", product.cost)
            stockQuantityText = "\(product.stockQuantity)"
            minStockLevelText = "\(product.minStockLevel)"
        } else if let scannedSku = scannedSku {
            sku = scannedSku
        }
    }
    
    func saveProduct() {
        // Validation
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Lütfen geçerli bir ürün adı girin.")
            return
        }
        
        guard !sku.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Lütfen bir barkod/SKU tanımlayın.")
            return
        }
        
        guard let price = Double(priceText.replacingOccurrences(of: ",", with: ".")), price >= 0 else {
            showError("Lütfen geçerli bir satış fiyatı girin.")
            return
        }
        
        let cost = Double(costText.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        
        guard let stock = Int(stockQuantityText), stock >= 0 else {
            showError("Lütfen geçerli bir stok miktarı girin.")
            return
        }
        
        let minLevel = Int(minStockLevelText) ?? 5
        
        if let product = product {
            // Edit
            product.name = name
            product.sku = sku
            product.category = category
            product.price = price
            product.cost = cost
            product.stockQuantity = stock
            product.minStockLevel = minLevel
        } else {
            // New
            let newProd = Product(
                sku: sku,
                name: name,
                price: price,
                cost: cost,
                stockQuantity: stock,
                minStockLevel: minLevel,
                category: category
            )
            modelContext.insert(newProd)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            showError("Veri kaydedilirken hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func showError(_ msg: String) {
        errorMessage = msg
        isShowingErrorAlert = true
    }
}
