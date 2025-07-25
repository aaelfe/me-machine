//
//  AuthUser.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation
import Supabase

struct AuthUser: Identifiable, Codable {
    let id: UUID
    let email: String?
    let phone: String?
    let createdAt: Date
    let lastSignInAt: Date?
    let isAnonymous: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case createdAt = "created_at"
        case lastSignInAt = "last_sign_in_at"
        case isAnonymous = "is_anonymous"
    }
    
    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.phone = user.phone
        self.createdAt = user.createdAt
        self.lastSignInAt = user.lastSignInAt
        self.isAnonymous = user.isAnonymous
    }
}

struct UserProfile: Identifiable, Codable {
    let id: UUID
    let email: String?
    let displayName: String?
    let avatarUrl: String?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}