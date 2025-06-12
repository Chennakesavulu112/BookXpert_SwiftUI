import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject private var authState: AuthState
    @State private var errorMessage: String?
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // App Logo
                AppLogoView(size: 120)
                    .padding(.bottom, 20)
                
                Text("BookXpert")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 30)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                GoogleSignInButton(action: handleSignIn)
                    .frame(width: 250, height: 50)
                    .padding()
                
                Spacer()
            }
            .padding()
        }
    }

    private func handleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase configuration error: Missing client ID"
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to get root view controller"
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
            if let error = error {
                errorMessage = "Google Sign-In error: \(error.localizedDescription)"
                print("Detailed Google Sign-In error: \(error)")
                return
            }

            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                errorMessage = "Missing authentication information"
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    errorMessage = "Firebase Sign-In error: \(error.localizedDescription)"
                    print("Detailed Firebase Sign-In error: \(error)")
                } else {
                    Task { @MainActor in
                        guard let user = result?.user else {
                            errorMessage = "Firebase user data not found"
                            return
                        }

                        // Save user data to Core Data
                        UserManager.shared.saveUser(
                            email: user.email,
                            name: user.displayName,
                            photoURL: user.photoURL?.absoluteString,
                            uid: user.uid
                        )
                        
                        authState.isSignedIn = true
                        errorMessage = nil
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthState())
}
