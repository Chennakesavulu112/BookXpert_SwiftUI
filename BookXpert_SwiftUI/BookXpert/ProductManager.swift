import Foundation
import CoreData
import Combine

class ProductManager: ObservableObject {
    static let shared = ProductManager()
    
    @Published var products: [Product] = []
    @Published var error: String?
    @Published var isLoading = false
    
    private let viewContext: NSManagedObjectContext
    
    private init() {
        self.viewContext = PersistenceController.shared.container.viewContext
        Task {
            await fetchFromAPI()
        }
    }
    
    func fetchFromAPI() async {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        guard let url = URL(string: "https://api.restful-api.dev/objects") else {
            await MainActor.run {
                self.error = "Invalid URL"
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            let productResponses = try decoder.decode([ProductResponse].self, from: data)
            
            await MainActor.run {
                self.viewContext.performAndWait {
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Product.fetchRequest()
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    try? self.viewContext.execute(deleteRequest)
                    
                    for productResponse in productResponses {
                        let product = Product(context: self.viewContext)
                        product.id = productResponse.id
                        product.name = productResponse.name
                        if let data = productResponse.data {
                            let nsData = NSDictionary(dictionary: data)
                            product.setValue(nsData, forKey: "data")
                        }
                        product.timestamp = Date()
                    }
                    
                    try? self.viewContext.save()
                    self.loadProducts()
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func loadProducts() {
        viewContext.performAndWait {
            let request: NSFetchRequest<Product> = Product.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.timestamp, ascending: false)]
            
            do {
                let fetchedProducts = try viewContext.fetch(request)
                DispatchQueue.main.async {
                    self.products = fetchedProducts
                    
                }
            } catch {
                self.error = "Failed to load products: \(error.localizedDescription)"
            }
        }
    }
    
    func addProduct(name: String, data: [String: Any]?) {
        viewContext.performAndWait {
            let product = Product(context: viewContext)
            product.id = UUID().uuidString
            product.name = name
            if let data = data {
                let nsData = NSDictionary(dictionary: data)
                product.setValue(nsData, forKey: "data")
            }
            product.timestamp = Date()
            
            try? viewContext.save()
            loadProducts()
        }
    }
    
    func updateProduct(_ product: Product, name: String, data: [String: Any]) {
        viewContext.performAndWait {
            product.name = name
            let nsData = NSDictionary(dictionary: data)
            product.setValue(nsData, forKey: "data")
            product.timestamp = Date()
            
            do {
                try viewContext.save()
                // Force UI update on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    // Reload all products to ensure UI is in sync
                    
                    self.loadProducts()
                }
            } catch {
                self.error = "Failed to update product: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteProduct(_ product: Product) {
        viewContext.performAndWait {
            // Send notification before deleting
            NotificationManager.shared.sendDeleteNotification(for: product)
            
            viewContext.delete(product)
            try? viewContext.save()
            loadProducts()
        }
    }
}

// MARK: - Product Response
struct ProductResponse: Codable {
    let id: String
    let name: String
    let data: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Handle data which can be null or a dictionary
        if let dataDict = try? container.decode([String: JSONValue].self, forKey: .data) {
            data = dataDict.mapValues { $0.value }
        } else {
            data = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        if let data = data {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let jsonValue = try JSONDecoder().decode([String: JSONValue].self, from: jsonData)
            try container.encode(jsonValue, forKey: .data)
        } else {
            try container.encodeNil(forKey: .data)
        }
    }
}

// MARK: - JSON Value Type
enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case object([String: JSONValue])
    case array([JSONValue])
    
    var value: Any {
        switch self {
        case .string(let value): return value
        case .number(let value): return value
        case .bool(let value): return value
        case .null: return NSNull()
        case .object(let value): return value.mapValues { $0.value }
        case .array(let value): return value.map { $0.value }
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid JSON value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
} 
