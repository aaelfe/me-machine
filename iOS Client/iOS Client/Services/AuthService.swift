//
//  AuthService.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation
import Combine
import Supabase
@preconcurrency import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let client: SupabaseClient
    
    @Published var currentUser: AuthUser?
    @Published var userProfile: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var authError: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        // Listen for auth state changes
        setupAuthStateListener()
        
        // Check initial auth state
        Task {
            await checkInitialAuthState()
        }
    }
    
    // MARK: - Auth State Management
    
    private func setupAuthStateListener() {
        Task {
            for await (event, session) in client.auth.authStateChanges {
                print("Auth state change: \(event), session user: \(session?.user.id.uuidString ?? "nil")")
                _ = await MainActor.run {
                    Task {
                        switch event {
                        case .signedIn:
                            print("Handling signed in event")
                            if let session = session {
                                await self.handleUserSignedIn(session.user)
                            }
                        case .signedOut:
                            print("Handling signed out event")
                            await self.handleUserSignedOut()
                        case .tokenRefreshed:
                            print("Handling token refresh event")
                            if let session = session {
                                await self.handleUserSignedIn(session.user)
                            }
                        default:
                            print("Other auth event: \(event)")
                            break
                        }
                    }
                }
            }
        }
    }
    
    private func checkInitialAuthState() async {
        do {
            let session = try await client.auth.session
            await handleUserSignedIn(session.user)
        } catch {
            await handleUserSignedOut()
        }
    }
    
    private func handleUserSignedIn(_ user: User) async {
        print("handleUserSignedIn called for user: \(user.id)")
        self.currentUser = AuthUser(from: user)
        self.isAuthenticated = true
        self.authError = nil
        print("Set isAuthenticated to true")
        
        // Load user profile
        await loadUserProfile()
        
        // Notify SupabaseService of auth change
        SupabaseService.shared.handleAuthStateChange(user: user)
    }
    
    private func handleUserSignedOut() async {
        self.currentUser = nil
        self.userProfile = nil
        self.isAuthenticated = false
        self.authError = nil
        
        // Notify SupabaseService of auth change
        SupabaseService.shared.handleAuthStateChange(user: nil)
    }
    
    // MARK: - Authentication Methods
    
    func signUpWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        defer {
            isLoading = false
        }
        
        do {
            _ = try await client.auth.signUp(email: email, password: password)
            // Auth state listener will handle the rest
        } catch {
            authError = error.localizedDescription
            throw error
        }
    }
    
    func signInWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        defer {
            isLoading = false
        }
        
        do {
            _ = try await client.auth.signIn(email: email, password: password)
            // Auth state listener will handle the rest
        } catch {
            authError = error.localizedDescription
            throw error
        }
    }
    
    func signInWithApple() async throws {
        // TODO: Implement Apple Sign In
        // This would use Supabase's Apple OAuth integration
        throw AuthError.notImplemented
    }
    
    func signInWithGoogle(presentingViewController: UIViewController) async throws {
        isLoading = true
        authError = nil
        
        defer {
            isLoading = false
        }
        
        do {
            print("Starting Google Sign-In...")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            print("Google Sign-In successful, got result")
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("No idToken found.")
                authError = "Failed to get ID token from Google"
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            print("Got tokens, signing in with Supabase...")
            
            let response = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken,
                    nonce: nil
                )
            )
            
            print("Supabase sign-in successful, session: \(response.user.id.uuidString)")
            // Auth state listener should handle the rest automatically
            
        } catch {
            print("Google Sign-In error: \(error)")
            authError = error.localizedDescription
            throw error
        }
    }
    
    func signOut() async throws {
        isLoading = true
        authError = nil
        
        defer {
            isLoading = false
        }
        
        do {
            try await client.auth.signOut()
            // Auth state listener will handle the rest
        } catch {
            authError = error.localizedDescription
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        authError = nil
        
        defer {
            isLoading = false
        }
        
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            authError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Profile Management
    
    private func loadUserProfile() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let profile: UserProfile = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            self.userProfile = profile
        } catch {
            print("Error loading user profile: \(error)")
            // Create profile if it doesn't exist
            await createUserProfile()
        }
    }
    
    private func createUserProfile() async {
        guard let user = currentUser else { return }
        
        let newProfile = UserProfile(
            id: user.id,
            email: user.email,
            createdAt: Date()
        )
        
        do {
            let profile: UserProfile = try await client
                .from("profiles")
                .insert(newProfile)
                .select()
                .single()
                .execute()
                .value
            
            self.userProfile = profile
        } catch {
            print("Error creating user profile: \(error)")
        }
    }
    
    func updateProfile(email: String?) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        do {
            let updatedProfile: UserProfile = try await client
                .from("profiles")
                .update([
                    "email": email
                ])
                .eq("id", value: userId)
                .select()
                .single()
                .execute()
                .value
            
            self.userProfile = updatedProfile
        } catch {
            authError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Utility Methods
    
    func refreshSession() async throws {
        try await client.auth.refreshSession()
    }
    
    var userDisplayName: String {
        if let email = currentUser?.email {
            return email
        }
        return "User"
    }
}

// MARK: - Custom Errors

enum AuthError: Error, LocalizedError {
    case notAuthenticated
    case notImplemented
    case invalidCredentials
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .notImplemented:
            return "Feature not implemented yet"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        }
    }
}
