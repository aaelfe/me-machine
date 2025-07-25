//
//  ProfileView.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var displayName = ""
    @State private var isEditing = false
    @State private var showingSignOut = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                Section {
                    HStack(spacing: 16) {
                        // Avatar
                        AsyncImage(url: URL(string: authService.userProfile?.avatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.userDisplayName)
                                .font(.headline)
                            
                            if let email = authService.currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if authService.isAnonymous {
                                Text("Anonymous User")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            isEditing = true
                            displayName = authService.userProfile?.displayName ?? ""
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                }
                
                // Settings
                Section("Settings") {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(isDarkMode ? .purple : .orange)
                        
                        Text("Dark Mode")
                        
                        Spacer()
                        
                        Toggle("", isOn: $isDarkMode)
                    }
                    
                    if authService.isAnonymous {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(.blue)
                                Text("Create Account")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                // Account Actions
                Section("Account") {
                    if !authService.isAnonymous {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "key")
                                    .foregroundColor(.orange)
                                Text("Change Password")
                            }
                        }
                    }
                    
                    Button(action: { showingSignOut = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // App Info
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("Privacy Policy")
                        }
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("Terms of Service")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditProfileView(displayName: $displayName)
        }
        .confirmationDialog("Sign Out", isPresented: $showingSignOut) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private func signOut() {
        Task {
            try? await authService.signOut()
            dismiss()
        }
    }
}

struct EditProfileView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var displayName: String
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    TextField("Display Name", text: $displayName)
                        .disabled(authService.isLoading)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(authService.isLoading)
                }
            }
        }
    }
    
    private func saveProfile() {
        Task {
            do {
                try await authService.updateProfile(
                    displayName: displayName.isEmpty ? nil : displayName,
                    avatarUrl: nil
                )
                dismiss()
            } catch {
                // Error is handled by AuthService
            }
        }
    }
}

#Preview {
    ProfileView()
}