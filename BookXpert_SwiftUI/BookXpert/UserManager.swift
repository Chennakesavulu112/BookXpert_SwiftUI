import Foundation
import CoreData

class UserManager {
    static let shared = UserManager()
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    func saveUser(email: String?, name: String?, photoURL: String?, uid: String) {
        // Check if user already exists
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uid == %@", uid)
        
        do {
            let existingUsers = try context.fetch(fetchRequest)
            let user: User
            
            if let existingUser = existingUsers.first {
                // Update existing user
                user = existingUser
            } else {
                // Create new user
                user = User(context: context)
            }
            
            // Update user properties
            user.email = email
            user.name = name
            user.photoURL = photoURL
            user.uid = uid
            user.timestamp = Date()
            
            // Save context
            try context.save()
            print("User saved successfully")
        } catch {
            print("Error saving user: \(error)")
        }
    }
    
    func getUser(uid: String) -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "uid == %@", uid)
        
        do {
            let users = try context.fetch(fetchRequest)
            return users.first
        } catch {
            print("Error fetching user: \(error)")
            return nil
        }
    }
} 