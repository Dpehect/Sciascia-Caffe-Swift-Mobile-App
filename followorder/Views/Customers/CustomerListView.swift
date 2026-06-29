import SwiftUI
import SwiftData

struct CustomerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Customer.name) private var customers: [Customer]
    
    @State private var searchText = ""
    
    // Detailed profile drawer/modal
    @State private var selectedCustomer: Customer? = nil
    
    // Add customer sheet
    @State private var isShowingAddCustomer = false
    @State private var newName = ""
    @State private var newPhone = ""
    @State private var newEmail = ""
    @State private var newAddress = ""
    
    @State private var themeManager = ThemeManager.shared
    
    var filteredCustomers: [Customer] {
        customers.filter { cust in
            if searchText.isEmpty {
                return true
            } else {
                let nameMatch = cust.name.localizedCaseInsensitiveContains(searchText)
                let phoneMatch = cust.phone.localizedCaseInsensitiveContains(searchText)
                let emailMatch = cust.email.localizedCaseInsensitiveContains(searchText)
                let addrMatch = cust.address.localizedCaseInsensitiveContains(searchText)
                return nameMatch || phoneMatch || emailMatch || addrMatch
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Customer List
                if filteredCustomers.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredCustomers) { customer in
                            customerRow(customer: customer)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteCustomer(customer)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.top, 4)
                    .padding(.bottom, 75) // Tab bar clearance
                }
            }
            
            // Add Customer FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isShowingAddCustomer = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .padding(15)
                            .background(themeManager.currentTheme.themeGradient)
                            .clipShape(Circle())
                            .shadow(color: themeManager.currentTheme.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 95)
                }
            }
        }
        .navigationTitle("Customers")
        .sheet(isPresented: $isShowingAddCustomer) {
            addCustomerSheet
        }
        .sheet(item: $selectedCustomer) { customer in
            customerDetailSheet(customer: customer)
        }
    }
    
    // MARK: - Subviews
    
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textPrimary.opacity(0.4))
            TextField("Search customer name, phone, or email...", text: $searchText)
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
    }
    
    func customerRow(customer: Customer) -> some View {
        let activeColor = themeManager.currentTheme.accentColor
        let orders = customer.orders
        let totalSpent = orders.reduce(0.0) { $0 + $1.totalAmount }
        
        return Button(action: {
            selectedCustomer = customer
        }) {
            GlassCard(accentColor: activeColor) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(customer.name)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        if !customer.phone.isEmpty {
                            Label(customer.phone, systemImage: "phone")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("₺\(String(format: "%.2f", totalSpent))")
                            .font(.subheadline)
                            .fontWeight(.black)
                            .foregroundColor(themeManager.currentTheme.accentColor)
                        
                        Text("\(orders.count) Order\(orders.count > 1 ? "s" : "")")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
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
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.textPrimary.opacity(0.2))
            
            Text("No Customers Found")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text(searchText.isEmpty ? "No customers registered in database. Tap the '+' icon in the bottom right corner to add one." : "No customers matched your search criteria.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
    
    var addCustomerSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                Form {
                    Section("Personal Information") {
                        TextField("Full Name", text: $newName)
                            .foregroundColor(.textPrimary)
                        TextField("Phone Number", text: $newPhone)
                            .keyboardType(.phonePad)
                            .foregroundColor(.textPrimary)
                        TextField("Email Address", text: $newEmail)
                            .keyboardType(.emailAddress)
                            .foregroundColor(.textPrimary)
                    }
                    .listRowBackground(Color.themeCardBase.opacity(0.5))
                    
                    Section("Address Information") {
                        TextField("Billing / Shipping Address", text: $newAddress)
                            .foregroundColor(.textPrimary)
                    }
                    .listRowBackground(Color.themeCardBase.opacity(0.5))
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Add New Customer")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingAddCustomer = false
                            clearFields()
                        }
                        .foregroundColor(.textSecondary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveCustomer()
                        }
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    func customerDetailSheet(customer: Customer) -> some View {
        let orders = customer.orders
        let totalSpent = orders.reduce(0.0) { $0 + $1.totalAmount }
        
        return NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Profile Summary Card
                        GlassCard(accentColor: themeManager.currentTheme.accentColor) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(customer.name)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.textPrimary)
                                        Text("Registered Customer")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(themeManager.currentTheme.accentColor)
                                }
                                
                                Divider().background(Color.textPrimary.opacity(0.08))
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    if !customer.phone.isEmpty {
                                        Label(customer.phone, systemImage: "phone.fill")
                                            .font(.subheadline)
                                            .foregroundColor(.textPrimary.opacity(0.85))
                                    }
                                    if !customer.email.isEmpty {
                                        Label(customer.email, systemImage: "envelope.fill")
                                            .font(.subheadline)
                                            .foregroundColor(.textPrimary.opacity(0.85))
                                    }
                                    if !customer.address.isEmpty {
                                        Label(customer.address, systemImage: "mappin.and.ellipse")
                                            .font(.subheadline)
                                            .foregroundColor(.textPrimary.opacity(0.85))
                                    }
                                }
                            }
                            .padding(16)
                        }
                        
                        // 2. Financial Metrics Row
                        HStack(spacing: 12) {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Total Spend")
                                        .font(.caption2)
                                        .foregroundColor(.textSecondary)
                                    Text("₺\(String(format: "%.2f", totalSpent))")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.textPrimary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            GlassCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Total Orders")
                                        .font(.caption2)
                                        .foregroundColor(.textSecondary)
                                    Text("\(orders.count) Order\(orders.count > 1 ? "s" : "")")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.textPrimary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // 3. Purchase History List
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ORDER HISTORY")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.textSecondary)
                                .padding(.leading, 4)
                            
                            if orders.isEmpty {
                                Text("No order history records found for this client.")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .glassCard(cornerRadius: 16)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(orders.sorted(by: { $0.date > $1.date })) { order in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(order.orderNumber)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.textPrimary)
                                                Text(order.date.formatted(date: .numeric, time: .omitted))
                                                    .font(.caption2)
                                                    .foregroundColor(.textSecondary)
                                            }
                                            Spacer()
                                            StatusBadge(status: order.status)
                                                .scaleEffect(0.85)
                                            Text("₺\(String(format: "%.2f", order.totalAmount))")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.textPrimary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                    }
                                }
                                .glassCard(cornerRadius: 16)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Customer Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { selectedCustomer = nil }.foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Logic Helpers
    
    func saveCustomer() {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let customer = Customer(
            name: newName,
            email: newEmail,
            phone: newPhone,
            address: newAddress
        )
        modelContext.insert(customer)
        try? modelContext.save()
        
        isShowingAddCustomer = false
        clearFields()
    }
    
    func deleteCustomer(_ customer: Customer) {
        withAnimation {
            modelContext.delete(customer)
            try? modelContext.save()
        }
    }
    
    func clearFields() {
        newName = ""
        newPhone = ""
        newEmail = ""
        newAddress = ""
    }
}
