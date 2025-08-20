import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var appState: AppState?
    
    init() {
        setupAuthStateListener()
    }
    
    func setAppState(_ appState: AppState) {
        self.appState = appState
    }
    
    private func setupAuthStateListener() {
        print("AuthService: Setting up auth state listener")
        auth.addStateDidChangeListener { [weak self] _, user in
            print("AuthService: Auth state changed, user: \(user?.uid ?? "nil")")
            DispatchQueue.main.async {
                if let user = user {
                    let appUser = User(
                        uid: user.uid,
                        isAnonymous: user.isAnonymous,
                        createdAt: user.metadata.creationDate ?? Date()
                    )
                    print("AuthService: Setting currentUser to \(appUser.uid)")
                    self?.currentUser = appUser
                    self?.isAuthenticated = true
                    // Also update AppState
                    print("AuthService: Updating AppState currentUser to \(appUser.uid)")
                    self?.appState?.currentUser = appUser
                } else {
                    print("AuthService: Clearing currentUser")
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                    // Also update AppState
                    print("AuthService: Clearing AppState currentUser")
                    self?.appState?.currentUser = nil
                }
            }
        }
    }
    
    func signInAnonymously() async throws {
        print("AuthService: Starting anonymous sign in")
        do {
            let result = try await auth.signInAnonymously()
            let user = result.user
            print("AuthService: Anonymous sign in successful, user: \(user.uid)")
            
            // Create user document in Firestore
            try await createUserDocument(uid: user.uid)
            
            DispatchQueue.main.async {
                let appUser = User(
                    uid: user.uid,
                    isAnonymous: user.isAnonymous,
                    createdAt: user.metadata.creationDate ?? Date()
                )
                print("AuthService: Setting currentUser to \(appUser.uid)")
                self.currentUser = appUser
                self.isAuthenticated = true
                // Also update AppState
                print("AuthService: Updating AppState currentUser to \(appUser.uid)")
                self.appState?.currentUser = appUser
            }
        } catch {
            print("Error signing in anonymously: \(error)")
            throw error
        }
    }
    
    private func createUserDocument(uid: String) async throws {
        let userRef = db.collection("users").document(uid)
        
        // Check if user document already exists
        let document = try await userRef.getDocument()
        
        if !document.exists {
            // Create new user document with default settings
            let userData: [String: Any] = [
                "uid": uid,
                "createdAt": Timestamp(date: Date()),
                "isAnonymous": true
            ]
            
            try await userRef.setData(userData)
            
            // Create default settings document
            let settingsRef = userRef.collection("settings").document("default")
            let defaultSettings: [String: Any] = [
                "focusDuration": 25,
                "shortBreak": 5,
                "longBreak": 15,
                "autoStart": false,
                "theme": "system",
                "sound": "default",
                "haptics": true,
                "dailyGoal": 120
            ]
            
            try await settingsRef.setData(defaultSettings)
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
}
