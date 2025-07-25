//
//  SupabaseConfig.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation

struct SupabaseConfig {
    // Direct configuration values - update these with your actual Supabase credentials
    static let url = "https://dxogqqifehtebqekauxj.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR4b2dxcWlmZWh0ZWJxZWthdXhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwOTQ1MjEsImV4cCI6MjA2ODY3MDUyMX0.qbpeG5uJ4P1r9XZbredSBfvINQ0BUnH36t8-CSpT0yE"
    static let backendURL = "http://localhost:8000"
    
    // Validate configuration on app launch
    static func validateSetup() {
        guard !url.isEmpty && !anonKey.isEmpty else {
            fatalError("Supabase configuration is missing. Please update SupabaseConfig.swift with your credentials.")
        }
        print("✅ Supabase configuration loaded successfully")
        print("📡 Supabase URL: \(url)")
        print("🔑 Backend URL: \(backendURL)")
    }
}