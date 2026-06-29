import SwiftUI
import SwiftData
#if os(iOS)
import ARKit
import RealityKit
#endif

// Detailed AR item configuration model
struct ARMenuItem: Identifiable, Hashable {
    let id = UUID()
    let sku: String
    let name: String
    let price: Double
    let category: String
    let calories: String
    let caffeine: String
    let allergens: String
    let ingredients: String
    let imageName: String // System icon representation
}

struct ARMenuView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Customer.name) private var customers: [Customer]
    
    @State private var themeManager = ThemeManager.shared
    
    // AR menu database
    let menuItems = [
        ARMenuItem(sku: "SC-01", name: "Caffè Sciascia 1919", price: 65.0, category: "Espresso Classics", calories: "5 kcal", caffeine: "80 mg", allergens: "Gluten-Free", ingredients: "Single shot premium Arabica blend, dust of cocoa powder sprinkles.", imageName: "cup.and.saucer.fill"),
        ARMenuItem(sku: "SC-03", name: "Cappuccino Sciascia", price: 80.0, category: "Espresso Classics", calories: "120 kcal", caffeine: "80 mg", allergens: "Contains Dairy", ingredients: "Double shot espresso, steamed whole milk, microfoam, chocolate flakes.", imageName: "cup.and.saucer.fill"),
        ARMenuItem(sku: "SC-04", name: "Caffè Macchiato", price: 60.0, category: "Espresso Classics", calories: "35 kcal", caffeine: "80 mg", allergens: "Contains Dairy", ingredients: "Single shot espresso, dash of foamed milk.", imageName: "cup.and.saucer.fill"),
        ARMenuItem(sku: "SC-08", name: "Cornetto al Pistacchio", price: 85.0, category: "Italian Pastries", calories: "340 kcal", caffeine: "0 mg", allergens: "Contains Gluten, Nuts, Eggs", ingredients: "Freshly baked flaky cornetto pastry, premium Sicilian pistachio cream filling.", imageName: "birthday.cake.fill"),
        ARMenuItem(sku: "SC-07", name: "Tiramisù Classico", price: 120.0, category: "Classic Desserts", calories: "290 kcal", caffeine: "40 mg", allergens: "Contains Gluten, Dairy, Eggs", ingredients: "Savoiardi ladyfingers soaked in espresso, sweet mascarpone cheese cream, unsweetened cocoa.", imageName: "birthday.cake.fill")
    ]
    
    @State private var selectedItemIndex = 0
    @State private var modelRotation: Double = 0.0
    @State private var modelScale: Double = 1.0
    @State private var isIngredientsExpanded = false
    @State private var addedCount = 0
    
    // Order creation state directly from AR view
    @State private var isShowingARCheckout = false
    @State private var arTableNumber = "Table 1"
    @State private var arSelectedCustomer: Customer? = nil
    @State private var isShowingConfetti = false
    
    var selectedItem: ARMenuItem {
        menuItems[selectedItemIndex]
    }
    
    var body: some View {
        ZStack {
            // Background camera stream (iOS) or Simulated 3D space (macOS)
            #if os(iOS)
            ARViewContainer()
                .ignoresSafeArea()
            #else
            simulatedARBackground
            #endif
            
            // Visual Guidance Overlay
            visualScanGuidance
            
            VStack(spacing: 0) {
                // Navigation top bar
                topNavigationBar
                
                // Top horizontal Carousel selection
                productSelectorCarousel
                    .padding(.top, 10)
                
                Spacer()
                
                // Interactive floating name and price
                floatingDetailsCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Nutritional overlays
                nutritionalOverviewRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Expandable ingredients details
                ingredientsDisclosureCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // AR Checkout controls
                checkoutActionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
            
            // Confetti Overlay
            ConfettiView(isPresented: $isShowingConfetti)
        }
        .preferredColorScheme(.light)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isShowingARCheckout) {
            arDirectCheckoutSheet
        }
    }
    
    // MARK: - Sections
    
    var topNavigationBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundColor(.textPrimary)
                    .padding(12)
                    .background(Color.themeCardBase.opacity(0.85))
                    .clipShape(Circle())
            }
            .padding(.leading)
            
            Spacer()
            
            Text("INTERACTIVE AR MENU")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.textPrimary)
                .tracking(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.themeCardBase.opacity(0.85))
                .cornerRadius(12)
                .padding(.trailing)
        }
        .padding(.top, 8)
    }
    
    var productSelectorCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<menuItems.count, id: \.self) { idx in
                    let item = menuItems[idx]
                    let isSelected = selectedItemIndex == idx
                    
                    Button(action: {
                        HapticHelper.playImpact(style: .soft)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedItemIndex = idx
                            addedCount = 0
                            isIngredientsExpanded = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: item.imageName)
                                .font(.system(size: 14))
                                .foregroundColor(isSelected ? .white : .textPrimary)
                            
                            Text(item.name)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? .white : .textPrimary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(isSelected ? AnyShapeStyle(themeManager.currentTheme.themeGradient) : AnyShapeStyle(Color.themeCardBase.opacity(0.85)))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.warmOrange : Color.textPrimary.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var floatingDetailsCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedItem.category.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.goldenYellow)
                    .tracking(1)
                
                Text(selectedItem.name)
                    .font(.title3)
                    .fontWeight(.black)
                    .foregroundColor(.textPrimary)
            }
            
            Spacer()
            
            Text("₺\(String(format: "%.2f", selectedItem.price))")
                .font(.headline)
                .fontWeight(.black)
                .foregroundColor(.warmOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.warmOrange.opacity(0.1))
                .cornerRadius(10)
        }
        .padding()
        .glassCard(accentColor: .goldenYellow)
    }
    
    var nutritionalOverviewRow: some View {
        HStack(spacing: 12) {
            nutriCard(title: "CALORIES", value: selectedItem.calories, icon: "flame.fill", color: .warmOrange)
            nutriCard(title: "CAFFEINE", value: selectedItem.caffeine, icon: "bolt.fill", color: .goldenYellow)
            nutriCard(title: "ALLERGENS", value: selectedItem.allergens, icon: "exclamationmark.shield.fill", color: .statusCancelled)
        }
    }
    
    func nutriCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.textSecondary)
            }
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
    
    var ingredientsDisclosureCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isIngredientsExpanded.toggle()
                }
            }) {
                HStack {
                    Label("Ingredients & Recipe details", systemImage: "book.pages")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                        .rotationEffect(.degrees(isIngredientsExpanded ? 90 : 0))
                }
            }
            
            if isIngredientsExpanded {
                Text(selectedItem.ingredients)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .glassCard()
    }
    
    var checkoutActionButtons: some View {
        HStack(spacing: 12) {
            // Interactive 3D Model rotation triggers
            Button(action: {
                withAnimation(.easeInOut) {
                    modelRotation -= 45.0
                }
            }) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title)
                    .foregroundColor(.textPrimary)
            }
            
            Button(action: {
                withAnimation(.easeInOut) {
                    modelRotation += 45.0
                }
            }) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.title)
                    .foregroundColor(.textPrimary)
            }
            
            // Add to Order button
            Button(action: {
                HapticHelper.playImpact(style: .medium)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    addedCount += 1
                }
            }) {
                HStack {
                    Image(systemName: "cart.badge.plus")
                    Text("Add to Order")
                        .fontWeight(.bold)
                    
                    if addedCount > 0 {
                        Text("(\(addedCount))")
                            .font(.caption)
                            .fontWeight(.black)
                            .padding(4)
                            .background(Color.white)
                            .foregroundColor(.warmOrange)
                            .clipShape(Circle())
                    }
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(themeManager.currentTheme.themeGradient)
                .cornerRadius(12)
            }
            
            if addedCount > 0 {
                // Checkout / Place Order button
                Button(action: {
                    isShowingARCheckout = true
                }) {
                    Text("Checkout")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.statusReady)
                        .cornerRadius(12)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    var visualScanGuidance: some View {
        VStack {
            Spacer()
            if addedCount == 0 {
                HStack(spacing: 6) {
                    Image(systemName: "camera.metering.matrix")
                        .foregroundColor(.goldenYellow)
                    Text("Keep camera pointed at flat surface for optimal scale")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.themeCardBase.opacity(0.8))
                .cornerRadius(10)
                .padding(.bottom, 290)
            }
        }
    }
    
    // MARK: - Direct Checkout Sheet
    
    var arDirectCheckoutSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Confirm AR Order")
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(.textPrimary)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Product:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(selectedItem.name)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                        }
                        HStack {
                            Text("Quantity:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text("\(addedCount) units")
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                        }
                        HStack {
                            Text("Total Tutar:")
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text("₺\(String(format: "%.2f", selectedItem.price * Double(addedCount)))")
                                .fontWeight(.black)
                                .foregroundColor(.warmOrange)
                        }
                    }
                    .padding()
                    .glassCard()
                    
                    Form {
                        Section("Delivery Details") {
                            TextField("Table Number (e.g. Table 3)", text: $arTableNumber)
                                .foregroundColor(.textPrimary)
                            
                            Picker("Customer Profile", selection: $arSelectedCustomer) {
                                Text("Guest / Walk-In").tag(nil as Customer?)
                                ForEach(customers) { customer in
                                    Text(customer.name).tag(customer as Customer?)
                                }
                            }
                        }
                        .listRowBackground(Color.themeCardBase.opacity(0.5))
                    }
                    .scrollContentBackground(.hidden)
                    
                    Button(action: processARCheckout) {
                        Text("Place Order Directly")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ThemeGradients.orange)
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .padding(.top)
            }
            .navigationTitle("AR Direct Checkout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { isShowingARCheckout = false }.foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Simulated 3D scene (macOS)
    
    var simulatedARBackground: some View {
        ZStack {
            // Warm Cream background color representing a table
            Color.creamyLatte.opacity(0.7)
                .ignoresSafeArea()
            
            // Rotating simulated coffee cup/shape representation
            VStack {
                Spacer()
                
                ZStack {
                    // Outer golden ring
                    Circle()
                        .stroke(Color.goldenYellow.opacity(0.3), lineWidth: 8)
                        .frame(width: 220, height: 220)
                    
                    // Rotating mock coffee cup mesh (Coffee saucer shape)
                    Circle()
                        .fill(Color.themeCardBase)
                        .frame(width: 170, height: 170)
                        .shadow(color: Color.espressoBrown.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // Cup body (Golden ring)
                    Circle()
                        .strokeBorder(Color.goldenYellow, lineWidth: 4)
                        .background(Circle().fill(Color.espressoBrown))
                        .frame(width: 110, height: 110)
                        .overlay(
                            // Latte art simulated text/shape inside cup
                            Image(systemName: selectedItem.imageName)
                                .font(.system(size: 34))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(modelRotation))
                        )
                }
                .scaleEffect(modelScale)
                .rotation3DEffect(.degrees(35), axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(.degrees(modelRotation), axis: (x: 0, y: 1, z: 0))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "macbook.and.iphone")
                    Text("macOS 3D Simulation Mode")
                        .font(.caption.bold())
                }
                .foregroundColor(.textSecondary)
                .padding(8)
                .background(Color.themeCardBase.opacity(0.7))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Logic Helpers
    
    func processARCheckout() {
        let orderNum = "#AR-\(Int.random(in: 1000...9999))"
        let newOrder = Order(
            orderNumber: orderNum,
            date: Date(),
            status: .preparing,
            discount: 0.0,
            notes: "Direct adisyon from Interactive AR Menu",
            customer: arSelectedCustomer,
            tableNumber: arTableNumber.isEmpty ? "Table 1" : arTableNumber
        )
        modelContext.insert(newOrder)
        
        // Find product SKU in DB or add new
        let productSku = selectedItem.sku
        let descriptor = FetchDescriptor<Product>()
        let productsList = (try? modelContext.fetch(descriptor)) ?? []
        
        let targetProduct: Product
        if let match = productsList.first(where: { $0.sku == productSku }) {
            targetProduct = match
        } else {
            targetProduct = Product(
                sku: productSku,
                name: selectedItem.name,
                price: selectedItem.price,
                cost: selectedItem.price * 0.25,
                stockQuantity: 50,
                minStockLevel: 5,
                category: selectedItem.category
            )
            modelContext.insert(targetProduct)
        }
        
        let orderItem = OrderItem(
            product: targetProduct,
            quantity: addedCount,
            priceAtPurchase: targetProduct.price,
            size: "Medium",
            milkType: "Normal",
            sweetness: "Regular"
        )
        modelContext.insert(orderItem)
        orderItem.order = newOrder
        
        // Decrease stock
        targetProduct.stockQuantity = max(0, targetProduct.stockQuantity - addedCount)
        
        // Loyalty stamp additions
        if let customer = arSelectedCustomer {
            customer.loyaltyStamps += addedCount
            if customer.loyaltyStamps >= 10 {
                customer.loyaltyStamps = customer.loyaltyStamps % 10
            }
        }
        
        do {
            try modelContext.save()
            isShowingARCheckout = false
            HapticHelper.playNotification(type: .success)
            isShowingConfetti = true
            
            // Auto dismiss the AR screen after ordering
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                dismiss()
            }
        } catch {
            print("Failed to save AR adisyon checkout: \(error)")
        }
    }
}

#if os(iOS)
struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        let anchor = AnchorEntity(plane: .horizontal)
        
        let textMesh = MeshResource.generateText(
            "Caffè Sciascia 1919",
            extrusionDepth: 0.015,
            font: .systemFont(ofSize: 0.05, weight: .bold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        
        let textMaterial = SimpleMaterial(color: .orange, isMetallic: true)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position = [0, 0.05, -0.4]
        anchor.addChild(textEntity)
        
        let cupMesh = MeshResource.generateSphere(radius: 0.04)
        let cupMaterial = SimpleMaterial(color: UIColor(Color.goldenYellow), isMetallic: false)
        let cupEntity = ModelEntity(mesh: cupMesh, materials: [cupMaterial])
        cupEntity.position = [-0.15, 0.05, -0.4]
        anchor.addChild(cupEntity)
        
        arView.scene.addAnchor(anchor)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
#endif
