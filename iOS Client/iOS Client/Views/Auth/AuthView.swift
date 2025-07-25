//
//  AuthView.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // App Logo/Header
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                    
                    Text("MeMachine")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Connect with your future self")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Auth Options
                VStack(spacing: 16) {
                    // Quick Start (Anonymous)
                    Button(action: signInAnonymously) {
                        HStack {
                            Image(systemName: "person.crop.circle.dashed")
                            Text("Quick Start")
                            Spacer()
                            if authService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                    }
                    .disabled(authService.isLoading)
                    
                    // Sign In / Sign Up
                    HStack(spacing: 12) {
                        Button("Sign In") {
                            showingSignUp = false
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        
                        Button("Sign Up") {
                            showingSignUp = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Social Auth (Future)
                    VStack(spacing: 12) {
                        Button(action: signInWithApple) {
                            HStack {
                                Image(systemName: "applelogo")
                                Text("Continue with Apple")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(true) // TODO: Implement
                        
                        Button(action: signInWithGoogle) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Continue with Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(true) // TODO: Implement
                    }
                }
                .padding(.horizontal)
                
                // Error Message
                if let error = authService.authError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Privacy Note
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignUp) {
            if showingSignUp {
                SignUpView()
            } else {
                SignInView()
            }
        }
    }
    
    private func signInAnonymously() {
        Task {
            try? await authService.signInAnonymously()
        }
    }
    
    private func signInWithApple() {
        // TODO: Implement Apple Sign In
    }
    
    private func signInWithGoogle() {
        // TODO: Implement Google Sign In
    }
}

#Preview {
    AuthView()
}