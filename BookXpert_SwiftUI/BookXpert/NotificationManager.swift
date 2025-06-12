import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    
    private init() {
        requestNotificationPermission()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            print("Permission granted: \(granted)")
            
            // If permission denied, disable notifications
            if !granted {
                DispatchQueue.main.async {
                    self.notificationsEnabled = false
                }
            }
        }
    }
    
    func sendDeleteNotification(for product: Product) {
        guard notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Product Deleted"
        content.body = "Deleted product: \(product.name ?? "Unknown") (ID: \(product.id ?? "N/A"))"
        content.sound = .default
        
        // Add product details to notification
        if let data = product.data as? [String: Any] {
            content.userInfo = data
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
} 