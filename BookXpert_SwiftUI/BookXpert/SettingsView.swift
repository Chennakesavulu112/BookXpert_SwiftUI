import SwiftUI

struct SettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject private var authState: AuthState
    
    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $notificationManager.notificationsEnabled)
                    .onChange(of: notificationManager.notificationsEnabled) { newValue in
                        if newValue {
                            notificationManager.requestNotificationPermission()
                        }
                    }
                
                if notificationManager.notificationsEnabled {
                    Text("You will receive notifications when products are deleted")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("Notifications are disabled. You won't receive notifications for deleted products")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Section {
                Button(action: {
                    authState.signOut()
                }) {
                    HStack {
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                        Image(systemName: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
} 