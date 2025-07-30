//
//  SignUpView.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var acceptedTerms = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Join MeMachine to connect with your future self")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(authService.isLoading)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                        
                        SecureField("Create a password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .disabled(authService.isLoading)
                        
                        // Password requirements
                        VStack(alignment: .leading, spacing: 4) {
                            PasswordRequirement(
                                text: "At least 8 characters",
                                isMet: password.count >= 8
                            )
                            PasswordRequirement(
                                text: "Contains a number",
                                isMet: password.rangeOfCharacter(from: .decimalDigits) != nil
                            )
                        }
                        .font(.caption)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.headline)
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .disabled(authService.isLoading)
                        
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("Passwords don't match")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    // Terms and Conditions
                    HStack(alignment: .top, spacing: 8) {
                        Button(action: { acceptedTerms.toggle() }) {
                            Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(acceptedTerms ? .blue : .gray)
                        }
                        
                        Text("I agree to the Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Sign Up Button
                Button(action: signUp) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Create Account")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || authService.isLoading)
                .padding(.horizontal)
                
                // Error Message
                if let error = authService.authError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword &&
        acceptedTerms
    }
    
    private func signUp() {
        Task {
            do {
                try await authService.signUpWithEmail(email, password: password)
                // Don't dismiss here - let the onChange observer handle it when auth state changes
            } catch {
                // Error is handled by AuthService
            }
        }
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
                .font(.caption)
            
            Text(text)
                .foregroundColor(isMet ? .green : .secondary)
        }
    }
}

#Preview {
    SignUpView()
}