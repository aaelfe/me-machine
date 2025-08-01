//
//  iOS_ClientApp.swift
//  iOS Client
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI
import GoogleSignIn

@main
struct iOS_ClientApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var authService = AuthService.shared
    
    init() {
        // Validate Supabase configuration on app launch
        SupabaseConfig.validateSetup()
        
        // Configure Google Sign-In with iOS client ID
        guard let path = Bundle.main.path(forResource: "MeMachine-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientID = plist["GIDClientID"] as? String else {
            print("Warning: Could not find GIDClientID in MeMachine-Info.plist")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
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
