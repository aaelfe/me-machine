//
//  AuthService.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation
import Combine
import Supabase

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
                await MainActor.run {
                    Task {
                        switch event {
                        case .signedIn:
                            if let session = session {
                                await self.handleUserSignedIn(session.user)
                            }
                        case .signedOut:
                            await self.handleUserSignedOut()
                        case .tokenRefreshed:
                            if let session = session {
                                await self.handleUserSignedIn(session.user)
                            }
                        default:
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
        self.currentUser = AuthUser(from: user)
        self.isAuthenticated = true
        self.authError = nil
        
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
    
    func signInAnonymously() async throws {
        isLoading = true
        authError = nil
        
        do {
            _ = try await client.auth.signInAnonymously()
            // Auth state listener will handle the rest
        } catch {
            authError = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signUpWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            _ = try await client.auth.signUp(email: email, password: password)
            // Auth state listener will handle the rest
        } catch {
            authError = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signInWithEmail(_ email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            _ = try await client.auth.signIn(email: email, password: password)
            // Auth state listener will handle the rest
        } catch {
            authError = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signInWithApple() async throws {
        // TODO: Implement Apple Sign In
        // This would use Supabase's Apple OAuth integration
        throw AuthError.notImplemented
    }
    
    func signInWithGoogle() async throws {
        // TODO: Implement Google Sign In
        // This would use Supabase's Google OAuth integration
        throw AuthError.notImplemented
    }
    
    func signOut() async throws {
        isLoading = true
        authError = nil
        
        do {
            try await client.auth.signOut()
            // Auth state listener will handle the rest
        } catch {
            authError = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            authError = error.localizedDescription
            throw error
        }
        
        isLoading = false
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
            displayName: nil,
            avatarUrl: nil,
            createdAt: Date(),
            updatedAt: nil
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
    
    func updateProfile(displayName: String?, avatarUrl: String?) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        isLoading = true
        
        do {
            let updatedProfile: UserProfile = try await client
                .from("profiles")
                .update([
                    "display_name": displayName,
                    "avatar_url": avatarUrl,
                    "updated_at": Date().ISO8601Format()
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
        
        isLoading = false
    }
    
    // MARK: - Utility Methods
    
    func refreshSession() async throws {
        try await client.auth.refreshSession()
    }
    
    var isAnonymous: Bool {
        currentUser?.isAnonymous ?? false
    }
    
    var userDisplayName: String {
        if let displayName = userProfile?.displayName, !displayName.isEmpty {
            return displayName
        }
        if let email = currentUser?.email {
            return email
        }
        if isAnonymous {
            return "Anonymous User"
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