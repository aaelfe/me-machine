//
//  iOS_ClientApp.swift
//  iOS Client
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

@main
struct iOS_ClientApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var authService = AuthService.shared
    
    init() {
        // Validate Supabase configuration on app launch
        SupabaseConfig.validateSetup()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                } else {
                    AuthView()
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
