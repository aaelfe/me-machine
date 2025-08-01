//
//  AuthView.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showingSignIn = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // App Logo/Header
                        VStack(spacing: 24) {
                            // Logo with gradient background
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.2), .blue.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 60, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(spacing: 8) {
                                Text("MeMachine")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                
                                Text("Connect with your future self")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 60)
                        .padding(.bottom, 60)
                        
                        // Auth Options Card
                        VStack(spacing: 24) {
                            // Primary Auth Buttons
                            VStack(spacing: 16) {
                                // Sign In / Sign Up
                                HStack(spacing: 16) {
                                    Button("Sign In") {
                                        showingSignIn = true
                                    }
                                    .buttonStyle(PrimaryButtonStyle())
                                    .frame(maxWidth: .infinity)
                                    
                                    Button("Sign Up") {
                                        showingSignUp = true
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                    .frame(maxWidth: .infinity)
                                }
                                
                                // Divider
                                HStack {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(height: 1)
                                    
                                    Text("or")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                    
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(height: 1)
                                }
                                .padding(.vertical, 8)
                            }
                            
                            // Social Auth Buttons
                            VStack(spacing: 12) {
                                Button(action: signInWithApple) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "applelogo")
                                            .font(.system(size: 18, weight: .medium))
                                        Text("Continue with Apple")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(true)
                                .opacity(0.6)
                                
                                Button(action: signInWithGoogle) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "globe")
                                            .font(.system(size: 18, weight: .medium))
                                        Text("Continue with Google")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 24)
                        
                        // Error Message
                        if let error = authService.authError {
                            Text(error)
                                .font(.callout)
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Privacy Note
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.05),
                        Color.blue.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView()
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }
    
    private func signInWithApple() {
        // TODO: Implement Apple Sign In
    }
    
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        Task {
            try await authService.signInWithGoogle(presentingViewController: rootViewController)
        }
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundColor(.blue)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    AuthView()
}
