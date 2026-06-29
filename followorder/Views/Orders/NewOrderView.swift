import SwiftUI
import SwiftData
import TipKit

struct NewOrderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Customer.name) private var customers: [Customer]
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \Order.date, order: .reverse) private var allOrders: [Order]
    
    // Theme
    @State private var themeManager = ThemeManager.shared
    
    // Order info
    @State private var selectedCustomer: Customer? = nil
    @State private var tableNumber = ""
    @State private var cartItems: [CartItem] = []
    @State private var discountText = ""
    @State private var notes = ""
    
    // Customization Sheet states
    @State private var isShowingCustomizer = false
    @State private var productToCustomize: Product? = nil
    @State private var customSize = "Medium"
    @State private var customMilk = "Normal"
    @State private var customSweetness = "Normal"
    @State private var customTemp = "Hot" // Hot / Iced
    @State private var selectedExtras: Set<String> = []
    @State private var customizeQuantity = 1
    
    // Picker/Scanner sheets
    @State private var customerSearchText = ""
    @State private var productSearchText = ""
    @State private var isShowingCustomerPicker = false
    @State private var isShowingProductPicker = false
    @State private var isShowingScanner = false
    @State private var isShowingQuickCustomerAdd = false
    @State private var isShowingARView = false
    
    // Quick customer add inputs
    @State private var newName = ""
    @State private var newCustPhone = ""
    
    // Errors
    @State private var errorMessage: String? = nil
    @State private var isShowingErrorAlert = false
    
    // Animations
    @State private var isShowingConfetti = false
    
    // TipKit tip definition
    let quickOrderTip = QuickOrderTip()
    
    // Cart Item Model
    struct CartItem: Identifiable {
        let id = UUID()
        let product: Product
        var quantity: Int
        var size: String
        var milkType: String
        var sweetness: String
        var temperature: String
        var toppings: String
    }
    
    var subtotal: Double {
        cartItems.reduce(0.0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    var discount: Double {
        Double(discountText) ?? 0.0
    }
    
    var total: Double {
        max(0.0, subtotal - discount)
    }
    
    var quickCustomers: [Customer] {
        Array(customers.prefix(3))
    }
    
    var quickProducts: [Product] {
        Array(products.prefix(4))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 0. TipKit Tip Alert
                        TipView(quickOrderTip, arrowEdge: .bottom)
                            .padding(.horizontal, 4)
                        
                        // 1. AR Camera Launcher
                        arMenuSection
                        
                        // 2. Loyalty Stamp Card (if customer selected)
                        if let customer = selectedCustomer {
                            LoyaltyStampCard(stampsCount: customer.loyaltyStamps)
                                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                        }
                        
                        // 3. One-Tap Quick Order Panel
                        quickActionSection
                        
                        // 4. Table Position & Location
                        locationSection
                        
                        // 5. Customer Profile Selection
                        customerSection
                        
                        // 6. Shopping Cart Items
                        cartSection
                        
                        // 7. Discounts, Notes, & Pricing Details
                        detailsSection
                        summarySection
                        
                        // Checkout Button
                        saveButton
                            .padding(.top, 10)
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
                
                // Particle Confetti overlay on checkout
                ConfettiView(isPresented: $isShowingConfetti)
            }
            .navigationTitle("New Order")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary.opacity(0.6))
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                barcodeScannerSheet
            }
            .sheet(isPresented: $isShowingCustomerPicker) {
                customerPickerSheet
            }
            .sheet(isPresented: $isShowingProductPicker) {
                productPickerSheet
            }
            .sheet(isPresented: $isShowingCustomizer) {
                customizationSheet
            }
            .navigationDestination(isPresented: $isShowingARView) {
                ARMenuView()
            }
            .alert("Error", isPresented: $isShowingErrorAlert, presenting: errorMessage) { _ in
                Button("OK") {}
            } message: { msg in
                Text(msg)
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Sections
    
    var arMenuSection: some View {
        Button(action: {
            HapticHelper.playImpact(style: .medium)
            isShowingARView = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arkit")
                    .font(.title2)
                    .foregroundColor(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open 3D AR Menu")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Point camera at table surface to view 3D coffee models & details in RealityKit.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
            }
            .padding()
            .background(ThemeGradients.orange)
            .cornerRadius(18)
            .shadow(color: Color.warmOrange.opacity(0.28), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var quickActionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK ORDER (ONE-TAP)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textPrimary.opacity(0.7))
                .tracking(1)
            
            VStack(spacing: 12) {
                // Recent Customers Shortcut
                if !quickCustomers.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recent Customers")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                        
                        HStack(spacing: 8) {
                            ForEach(quickCustomers) { customer in
                                Button(action: {
                                    HapticHelper.playImpact(style: .soft)
                                    withAnimation(.spring) {
                                        selectedCustomer = customer
                                    }
                                }) {
                                    Text(customer.name.components(separatedBy: " ").first ?? customer.name)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(selectedCustomer?.id == customer.id ? .white : .warmOrange)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(selectedCustomer?.id == customer.id ? Color.warmOrange.opacity(0.85) : Color.textPrimary.opacity(0.04))
                                        )
                                        .overlay(
                                            Capsule().stroke(selectedCustomer?.id == customer.id ? Color.warmOrange : Color.textPrimary.opacity(0.12), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }
                
                // Recent Items Shortcut
                if !quickProducts.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recent Selections")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickProducts) { product in
                                    Button(action: {
                                        HapticHelper.playImpact(style: .soft)
                                        triggerCustomizer(for: product)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 8))
                                            Text(product.name)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                        }
                                        .foregroundColor(.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(Color.textPrimary.opacity(0.04)))
                                        .overlay(Capsule().stroke(Color.textPrimary.opacity(0.15), lineWidth: 1))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .glassCard(cornerRadius: 16, accentColor: .warmOrange)
        }
    }
    
    var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SERVICE LOCATION")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(1)
            
            HStack(spacing: 12) {
                // Table Number input field
                HStack {
                    Image(systemName: "tableparts")
                        .foregroundColor(.warmOrange)
                    TextField("Table No (e.g. Table 2)", text: $tableNumber)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                }
                .padding()
                .glassCard(cornerRadius: 16, accentColor: .warmOrange)
                
                // Takeaway shortcut Button
                Button(action: {
                    HapticHelper.playImpact(style: .light)
                    tableNumber = "Takeaway"
                }) {
                    HStack {
                        Image(systemName: "bag.fill")
                        Text("Takeaway")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(tableNumber == "Takeaway" ? .white : .textPrimary)
                    .padding()
                    .glassCard(cornerRadius: 16, accentColor: tableNumber == "Takeaway" ? .warmOrange : .clear)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    var customerSection: some View {
        let activeColor = themeManager.currentTheme.accentColor
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("CUSTOMER PROFILE")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(1)
            
            if let customer = selectedCustomer {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(customer.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        if !customer.phone.isEmpty {
                            Text(customer.phone)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    Spacer()
                    Button("Change") {
                        isShowingCustomerPicker = true
                    }
                    .font(.subheadline)
                    .foregroundColor(activeColor)
                }
                .padding()
                .glassCard(cornerRadius: 16, accentColor: activeColor)
            } else {
                Button(action: {
                    isShowingCustomerPicker = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                        Text("Select Customer / Scan Loyalty")
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.textPrimary)
                    .padding()
                    .glassCard(cornerRadius: 16)
                }
            }
        }
    }
    
    var cartSection: some View {
        let activeColor = themeManager.currentTheme.accentColor
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ORDER CART")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(1)
                
                Spacer()
                
                Button(action: {
                    isShowingScanner = true
                }) {
                    Label("Scan QR", systemImage: "qrcode.viewfinder")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(activeColor)
                }
                .padding(.trailing, 8)
                
                Button(action: {
                    isShowingProductPicker = true
                }) {
                    Label("Sciascia Menu", systemImage: "plus.circle")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(activeColor)
                }
            }
            
            if cartItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer")
                        .font(.largeTitle)
                        .foregroundColor(.textPrimary.opacity(0.2))
                    Text("Order cart is empty")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .glassCard(cornerRadius: 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(cartItems) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.product.name)
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                
                                // Customize details summary text
                                Text("\(item.size) size • \(item.temperature) • \(item.milkType) • \(item.sweetness)\(item.toppings.isEmpty ? "" : " • " + item.toppings)")
                                    .font(.caption2)
                                    .foregroundColor(.warmOrange)
                                    .padding(.top, 1)
                            }
                            
                            Spacer()
                            
                            // Quantity adjustment stepper
                            HStack(spacing: 12) {
                                Button(action: {
                                    HapticHelper.playImpact(style: .light)
                                    decrementItem(item)
                                }) {
                                    Image(systemName: "minus.circle")
                                        .font(.title3)
                                        .foregroundColor(activeColor)
                                }
                                
                                Text("\(item.quantity)")
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                    .frame(minWidth: 20)
                                
                                Button(action: {
                                    HapticHelper.playImpact(style: .light)
                                    incrementItem(item)
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.title3)
                                        .foregroundColor(activeColor)
                                }
                            }
                            
                            Text("₺\(String(format: "%.2f", item.product.price * Double(item.quantity)))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding()
                        .transition(.scale.combined(with: .opacity))
                        
                        if item.id != cartItems.last?.id {
                            Divider()
                                .background(Color.textPrimary.opacity(0.08))
                        }
                    }
                }
                .glassCard(cornerRadius: 16, accentColor: activeColor)
            }
        }
    }
    
    var detailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DISCOUNTS & SPECIAL INSTRUCTIONS")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
                .tracking(1)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Extra Discount (₺)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    TextField("0.00", text: $discountText)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .frame(width: 100)
                }
                
                Divider()
                    .background(Color.textPrimary.opacity(0.08))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Order Notes")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    
                    TextField("Cocoa powder on top, extra cold brew ice, etc...", text: $notes)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                }
            }
            .padding()
            .glassCard(cornerRadius: 16)
        }
    }
    
    var summarySection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Subtotal")
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("₺\(String(format: "%.2f", subtotal))")
                    .foregroundColor(.textPrimary)
            }
            
            if discount > 0 {
                HStack {
                    Text("Discount")
                        .foregroundColor(.warmOrange)
                    Spacer()
                    Text("-₺\(String(format: "%.2f", discount))")
                        .foregroundColor(.warmOrange)
                }
            }
            
            Divider()
                .background(Color.textPrimary.opacity(0.12))
                .padding(.vertical, 4)
            
            HStack {
                Text("Total Amount")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("₺\(String(format: "%.2f", total))")
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .padding()
        .glassCard(cornerRadius: 16, accentColor: themeManager.currentTheme.accentColor)
    }
    
    var saveButton: some View {
        Button(action: createOrder) {
            Text("Send to Barista")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(themeManager.currentTheme.themeGradient)
                .cornerRadius(16)
                .shadow(color: themeManager.currentTheme.accentColor.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .disabled(cartItems.isEmpty)
        .opacity(cartItems.isEmpty ? 0.5 : 1.0)
    }
    
    // MARK: - Sheets
    
    var barcodeScannerSheet: some View {
        NavigationStack {
            BarcodeScannerView { barcode in
                isShowingScanner = false
                handleScannedBarcode(barcode)
            }
            .ignoresSafeArea()
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isShowingScanner = false }.foregroundColor(.white)
                }
            }
        }
    }
    
    var customerPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.textPrimary.opacity(0.5))
                            TextField("Find Customer...", text: $customerSearchText)
                                .foregroundColor(.textPrimary)
                        }
                        .padding(8)
                        .background(Color.themeCardBase.opacity(0.5))
                        .cornerRadius(10)
                        
                        Button(action: { isShowingQuickCustomerAdd.toggle() }) {
                            Image(systemName: "person.badge.plus.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(themeManager.currentTheme.themeGradient)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    
                    if isShowingQuickCustomerAdd {
                        quickCustomerAddView
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                    
                    let filtered = customers.filter {
                        customerSearchText.isEmpty || $0.name.localizedCaseInsensitiveContains(customerSearchText)
                    }
                    
                    List(filtered) { customer in
                        Button(action: {
                            withAnimation {
                                selectedCustomer = customer
                                isShowingCustomerPicker = false
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(customer.name)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                if !customer.phone.isEmpty {
                                    Text(customer.phone)
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                        .listRowBackground(Color.themeCardBase.opacity(0.4))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isShowingCustomerPicker = false }.foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    var quickCustomerAddView: some View {
        VStack(spacing: 10) {
            TextField("Customer Full Name", text: $newName)
                .padding(10)
                .background(Color.themeCardBase.opacity(0.8))
                .cornerRadius(8)
            TextField("Phone Number", text: $newCustPhone)
                .padding(10)
                .background(Color.themeCardBase.opacity(0.8))
                .cornerRadius(8)
                .keyboardType(.phonePad)
            
            HStack {
                Button("Cancel") {
                    isShowingQuickCustomerAdd = false
                    newName = ""
                    newCustPhone = ""
                }
                .foregroundColor(.textSecondary)
                
                Spacer()
                
                Button("Add") {
                    guard !newName.isEmpty else { return }
                    let newCust = Customer(name: newName, phone: newCustPhone)
                    modelContext.insert(newCust)
                    try? modelContext.save()
                    selectedCustomer = newCust
                    isShowingQuickCustomerAdd = false
                    isShowingCustomerPicker = false
                    
                    newName = ""
                    newCustPhone = ""
                }
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .padding()
        .background(Color.themeCardBase.opacity(0.95))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 1))
    }
    
    var productPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.textPrimary.opacity(0.5))
                        TextField("Find Product / Dessert...", text: $productSearchText)
                            .foregroundColor(.textPrimary)
                    }
                    .padding()
                    .background(Color.themeCardBase.opacity(0.4))
                    
                    let filtered = products.filter {
                        productSearchText.isEmpty ||
                        $0.name.localizedCaseInsensitiveContains(productSearchText) ||
                        $0.sku.localizedCaseInsensitiveContains(productSearchText)
                    }
                    
                    List(filtered) { product in
                        Button(action: {
                            HapticHelper.playImpact(style: .medium)
                            isShowingProductPicker = false
                            triggerCustomizer(for: product)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .fontWeight(.bold)
                                        .foregroundColor(.textPrimary)
                                    Text("SKU: \(product.sku)")
                                        .font(.caption2)
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("₺\(String(format: "%.2f", product.price))")
                                        .fontWeight(.bold)
                                        .foregroundColor(.textPrimary)
                                    Text("Stock: \(product.stockQuantity)")
                                        .font(.caption2)
                                        .foregroundColor(product.isLowStock ? .statusCancelled : .textSecondary)
                                }
                            }
                        }
                        .listRowBackground(Color.themeCardBase.opacity(0.4))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Sciascia Menu Selections")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isShowingProductPicker = false }.foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Customizable Sheet View
    
    var customizationSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                if let product = productToCustomize {
                    VStack(spacing: 20) {
                        VStack(spacing: 6) {
                            Text(product.name)
                                .font(.title2.bold())
                                .foregroundColor(.textPrimary)
                            Text("Unit Price: ₺\(String(format: "%.2f", product.price))")
                                .foregroundColor(.textSecondary)
                                .font(.subheadline)
                        }
                        .padding(.top)
                        
                        Form {
                            Section("Size Selection") {
                                Picker("Size", selection: $customSize) {
                                    Text("Single").tag("Single")
                                    Text("Double").tag("Double")
                                    Text("Medium").tag("Medium")
                                    Text("Large").tag("Large")
                                }
                                .pickerStyle(.segmented)
                            }
                            .listRowBackground(Color.themeCardBase.opacity(0.5))
                            
                            Section("Temperature") {
                                Picker("Temperature", selection: $customTemp) {
                                    Text("Hot").tag("Hot")
                                    Text("Iced").tag("Iced")
                                }
                                .pickerStyle(.segmented)
                            }
                            .listRowBackground(Color.themeCardBase.opacity(0.5))
                            
                            Section("Milk Alternative") {
                                Picker("Milk", selection: $customMilk) {
                                    Text("Normal").tag("Normal")
                                    Text("Oat Milk").tag("Oat Milk")
                                    Text("Almond Milk").tag("Almond Milk")
                                    Text("Soy Milk").tag("Soy Milk")
                                    Text("None").tag("None")
                                }
                                .adaptivePickerStyle()
                            }
                            .listRowBackground(Color.themeCardBase.opacity(0.5))
                            
                            Section("Sweetness Level") {
                                Picker("Sweetness", selection: $customSweetness) {
                                    Text("Sugar-Free").tag("Sugar-Free")
                                    Text("Less Sugar").tag("Less Sugar")
                                    Text("Regular").tag("Regular")
                                }
                                .pickerStyle(.segmented)
                            }
                            .listRowBackground(Color.themeCardBase.opacity(0.5))
                            
                            Section("Extras / Toppings") {
                                extraToggleRow(title: "Extra Espresso Shot", tag: "Extra Shot")
                                extraToggleRow(title: "Caramel Syrup", tag: "Caramel Syrup")
                                extraToggleRow(title: "Cocoa Powder (Sciascia Special)", tag: "Cocoa Powder")
                            }
                            .listRowBackground(Color.themeCardBase.opacity(0.5))
                            
                            Section("Quantity") {
                                Stepper("Count: \(customizeQuantity)", value: $customizeQuantity, in: 1...10)
                            }
                            .listRowBackground(Color.themeCardBase.opacity(0.5))
                        }
                        .scrollContentBackground(.hidden)
                        
                        Button(action: {
                            HapticHelper.playImpact(style: .heavy)
                            addCustomizedProductToCart()
                            isShowingCustomizer = false
                        }) {
                            Text("Add to Cart (₺\(String(format: "%.2f", product.price * Double(customizeQuantity))))")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.currentTheme.themeGradient)
                                .cornerRadius(12)
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle("Order Customization")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isShowingCustomizer = false }.foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    func extraToggleRow(title: String, tag: String) -> some View {
        Toggle(isOn: Binding(
            get: { selectedExtras.contains(tag) },
            set: { isAdding in
                if isAdding {
                    selectedExtras.insert(tag)
                } else {
                    selectedExtras.remove(tag)
                }
            }
        )) {
            Text(title)
                .foregroundColor(.textPrimary)
        }
    }
    
    // MARK: - Logic
    
    func triggerCustomizer(for product: Product) {
        productToCustomize = product
        customSize = "Medium"
        customMilk = "Normal"
        customSweetness = "Regular"
        customTemp = "Hot"
        selectedExtras = []
        customizeQuantity = 1
        isShowingCustomizer = true
    }
    
    func addCustomizedProductToCart() {
        guard let product = productToCustomize else { return }
        
        let toppingsString = selectedExtras.sorted().joined(separator: ", ")
        
        if let idx = cartItems.firstIndex(where: {
            $0.product.id == product.id &&
            $0.size == customSize &&
            $0.milkType == customMilk &&
            $0.sweetness == customSweetness &&
            $0.temperature == customTemp &&
            $0.toppings == toppingsString
        }) {
            cartItems[idx].quantity += customizeQuantity
        } else {
            cartItems.append(CartItem(
                product: product,
                quantity: customizeQuantity,
                size: customSize,
                milkType: customMilk,
                sweetness: customSweetness,
                temperature: customTemp,
                toppings: toppingsString
            ))
        }
    }
    
    func decrementItem(_ item: CartItem) {
        if let idx = cartItems.firstIndex(where: { $0.id == item.id }) {
            if cartItems[idx].quantity > 1 {
                cartItems[idx].quantity -= 1
            } else {
                cartItems.remove(at: idx)
            }
        }
    }
    
    func incrementItem(_ item: CartItem) {
        if let idx = cartItems.firstIndex(where: { $0.id == item.id }) {
            cartItems[idx].quantity += 1
        }
    }
    
    func handleScannedBarcode(_ barcode: String) {
        if let matchedCustomer = customers.first(where: { $0.phone == barcode || $0.email == barcode || $0.name.localizedCaseInsensitiveContains(barcode) }) {
            HapticHelper.playNotification(type: .success)
            selectedCustomer = matchedCustomer
            return
        }
        
        if let product = products.first(where: { $0.sku == barcode }) {
            HapticHelper.playImpact(style: .medium)
            triggerCustomizer(for: product)
        } else {
            HapticHelper.playNotification(type: .warning)
            errorMessage = "Scanned barcode or QR does not match any menu product or registered client."
            isShowingErrorAlert = true
        }
    }
    
    func generateOrderNumber() -> String {
        let numericOrders = allOrders.compactMap { order -> Int? in
            let clean = order.orderNumber.replacingOccurrences(of: "#", with: "")
            return Int(clean)
        }
        let maxNum = numericOrders.max() ?? 999
        return "#\(maxNum + 1)"
    }
    
    func createOrder() {
        for item in cartItems {
            if item.product.stockQuantity < item.quantity {
                errorMessage = "Insufficient stock inventory for \(item.product.name)!"
                isShowingErrorAlert = true
                return
            }
        }
        
        let orderNum = generateOrderNumber()
        let newOrder = Order(
            orderNumber: orderNum,
            date: Date(),
            status: .preparing,
            discount: discount,
            notes: notes.isEmpty ? nil : notes,
            customer: selectedCustomer,
            tableNumber: tableNumber.isEmpty ? "Takeaway" : tableNumber
        )
        
        modelContext.insert(newOrder)
        
        // Add items & decrease stock levels
        var totalStampsGained = 0
        for item in cartItems {
            let orderItem = OrderItem(
                product: item.product,
                quantity: item.quantity,
                priceAtPurchase: item.product.price,
                size: item.size,
                milkType: item.milkType,
                sweetness: item.sweetness,
                toppings: item.toppings
            )
            modelContext.insert(orderItem)
            orderItem.order = newOrder
            
            // Decrease stock
            item.product.stockQuantity -= item.quantity
            
            // Gained stamps check (if it's coffee/beverage)
            if item.product.category == "Espresso Classics" || item.product.category == "Cold Beverages" {
                totalStampsGained += item.quantity
            }
        }
        
        // Update Customer Loyalty Stamps
        if let customer = selectedCustomer {
            customer.loyaltyStamps += totalStampsGained
            if customer.loyaltyStamps >= 10 {
                // Free drink loop reset
                customer.loyaltyStamps = customer.loyaltyStamps % 10
            }
        }
        
        do {
            try modelContext.save()
            
            HapticHelper.playNotification(type: .success)
            isShowingConfetti = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                dismiss()
            }
        } catch {
            errorMessage = "Could not save order adisyon details: \(error.localizedDescription)"
            isShowingErrorAlert = true
        }
    }
}
