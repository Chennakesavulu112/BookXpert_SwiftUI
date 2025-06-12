//
//  BookXpertApp.swift
//  BookXpert
//
//  Created by peoplelink on 10/06/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

@main
struct BookXpertApp: App {
    @StateObject private var authState = AuthState()
    @StateObject private var themeManager = ThemeManager()
    let persistenceController = PersistenceController.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authState.isSignedIn {
                    HomeView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else {
                    LoginView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }
            .environmentObject(authState)
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}

class AuthState: ObservableObject {
    @Published var isSignedIn: Bool = false
    
    init() {
        // Check if user is already signed in
        isSignedIn = Auth.auth().currentUser != nil
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isSignedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
