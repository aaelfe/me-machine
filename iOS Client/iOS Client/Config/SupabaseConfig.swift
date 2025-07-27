//
//  SupabaseConfig.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation

struct SupabaseConfig {
    // Configuration values loaded from xcconfig via Info.plist through SecretsManager
    static let url = SecretsManager.supabaseURL
    static let anonKey = SecretsManager.supabaseAnonKey
    static let backendURL = SecretsManager.backendURL
    
    // Validate configuration on app launch
    static func validateSetup() {
        SecretsManager.validateConfiguration()
        print("📡 Supabase URL: \(url)")
        print("🔑 Backend URL: \(backendURL)")
    }
}