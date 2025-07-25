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
    let createdAt: Date
    let isAnonymous: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case isAnonymous = "is_anonymous"
    }
    
    init(from user: User) {
        self.id = user.id
        self.email = user.email
        self.createdAt = user.createdAt
        self.isAnonymous = user.isAnonymous
    }
}

struct UserProfile: Identifiable, Codable {
    let id: UUID
    let email: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}
