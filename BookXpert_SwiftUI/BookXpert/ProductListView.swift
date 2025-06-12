import SwiftUI
import CoreData

struct ProductListView: View {
    @ObservedObject private var productManager = ProductManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingEditSheet = false
    @State private var selectedProduct: Product?
    @State private var showingDeleteAlert = false
    @State private var showingAddSheet = false
    @State private var deletedProductName: String?
    @State private var showDeleteBanner = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Products")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        Task {
                            await productManager.fetchFromAPI()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reload")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if productManager.isLoading {
                    Spacer()
                    ProgressView("Loading products...")
                    Spacer()
                } else if productManager.products.isEmpty {
                    Spacer()
                    Text("No products available")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    List {
                        ForEach(productManager.products) { product in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(product.name ?? "Unknown")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if let data = product.value(forKey: "data") as? NSDictionary {
                                    ForEach(Array(data.allKeys.compactMap { $0 as? String }.sorted().prefix(3)), id: \.self) { key in
                                        if let value = data[key] {
                                            HStack {
                                                Text(key)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                                Spacer()
                                                Text("\(value)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                            .cornerRadius(10)
                            .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedProduct = product
                                showingEditSheet = true
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    selectedProduct = product
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            
            // Delete Banner - only show if notifications are enabled
            if showDeleteBanner, let productName = deletedProductName, notificationManager.notificationsEnabled {
                VStack {
                    DeleteBannerView(productName: productName) {
                        withAnimation {
                            showDeleteBanner = false
                        }
                    }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("Error", isPresented: .constant(productManager.error != nil)) {
            Button("OK") {
                productManager.error = nil
            }
        } message: {
            Text(productManager.error ?? "")
        }
        .alert("Delete Product", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let product = selectedProduct {
                    deletedProductName = product.name
                    productManager.deleteProduct(product)
                    if notificationManager.notificationsEnabled {
                        withAnimation {
                            showDeleteBanner = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showDeleteBanner = false
                            }
                        }
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this product?")
        }
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            selectedProduct = nil
        }) {
            if let product = selectedProduct {
                ProductEditView(product: product)
            } else {
                ProgressView("Loading...")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ProductAddView()
        }
    }
}

struct ProductRow: View {
    @State var product: Product
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.name ?? "Unknown")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let data = product.value(forKey: "data") as? NSDictionary {
                ForEach(Array(data.allKeys.compactMap { $0 as? String }.sorted().prefix(3)), id: \.self) { key in
                    if let value = data[key] {
                        HStack {
                            Text(key)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(value)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(10)
        .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

struct ProductAddView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var productManager = ProductManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var name: String = ""
    @State private var data: [String: String] = [:]
    @State private var newKey: String = ""
    @State private var newValue: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Product Details")) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Additional Data")) {
                    ForEach(Array(data.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                            TextField("Value", text: Binding(
                                get: { data[key] ?? "" },
                                set: { data[key] = $0 }
                            ))
                        }
                    }
                    
                    HStack {
                        TextField("Key", text: $newKey)
                        TextField("Value", text: $newValue)
                        Button("Add") {
                            if !newKey.isEmpty {
                                data[newKey] = newValue
                                newKey = ""
                                newValue = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Product")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let convertedData = data.mapValues { $0 as Any }
                    productManager.addProduct(name: name, data: convertedData)
                    dismiss()
                }
                .disabled(name.isEmpty)
            )
        }
    }
}

struct ProductEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var productManager = ProductManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    let product: Product
    @State private var name: String
    @State private var data: [String: String]
    @State private var newKey: String = ""
    @State private var newValue: String = ""
    
    init(product: Product) {
        self.product = product
        let initialName = product.name ?? ""
        let initialData: [String: String]
        if let productData = product.value(forKey: "data") as? NSDictionary {
            initialData = Dictionary(uniqueKeysWithValues: productData.map {
                ($0.key as? String ?? "", "\($0.value)")
            })
        } else {
            initialData = [:]
        }
        _name = State(initialValue: initialName)
        _data = State(initialValue: initialData)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Product Details")) {
                    TextField("Name", text: $name)
                }
                
                Section(header: Text("Additional Data")) {
                    ForEach(Array(data.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                            TextField("Value", text: Binding(
                                get: { data[key] ?? "" },
                                set: { data[key] = $0 }
                            ))
                        }
                    }
                    
                    HStack {
                        TextField("Key", text: $newKey)
                        TextField("Value", text: $newValue)
                        Button("Add") {
                            if !newKey.isEmpty {
                                data[newKey] = newValue
                                newKey = ""
                                newValue = ""
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let convertedData = data.mapValues { $0 as Any }
                    productManager.updateProduct(product, name: name, data: convertedData)
                    dismiss()
                }
                    .disabled(name.isEmpty)
            )
        }
    }
}

#Preview {
    ProductListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
