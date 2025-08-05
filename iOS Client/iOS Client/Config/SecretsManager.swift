//
//  SecretsManager.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation

struct SecretsManager {
    private static let bundle = Bundle.main
    
    static var supabaseURL: String {
        guard let url = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !url.isEmpty,
              !url.contains("your-project-id") else {
            fatalError("SUPABASE_URL not found in Info.plist or still contains placeholder. Please update your Config.xcconfig file.")
        }
        return url
    }
    
    static var supabaseAnonKey: String {
        guard let key = bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty,
              !key.contains("your-anon-key") else {
            fatalError("SUPABASE_ANON_KEY not found in Info.plist or still contains placeholder. Please update your Config.xcconfig file.")
        }
        return key
    }
    
    static var backendURL: String {
        guard let url = bundle.object(forInfoDictionaryKey: "BACKEND_URL") as? String,
              !url.isEmpty else {
            return "http://localhost:8000" // Default fallback
        }
        return url
    }
    
    // Development helper to check if secrets are properly configured
    static var isConfigured: Bool {
        do {
            _ = supabaseURL
            _ = supabaseAnonKey
            return true
        }
    }
    
    static func validateConfiguration() {
        guard isConfigured else {
            print("⚠️ Supabase configuration not found!")
            print("📝 Please follow these steps:")
            print("1. Copy Config.xcconfig.template to Config.xcconfig")
            print("2. Add your actual Supabase URL and anon key")
            print("3. Make sure Config.xcconfig is added to your Xcode project")
            return
        }
        print("✅ Supabase configuration loaded successfully")
    }
}
