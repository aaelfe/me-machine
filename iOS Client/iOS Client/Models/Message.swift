//
//  Message.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation

struct Message: Identifiable, Codable {
    let id: Int
    let conversationId: Int
    let role: MessageRole
    let content: String
    let createdAt: Date
    
    // Computed properties for UI compatibility
    var isFromFuture: Bool {
        role == .ai
    }
    
    var timestamp: Date {
        createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case role
        case content
        case createdAt = "created_at"
    }
}

enum MessageRole: String, Codable, CaseIterable {
    case user = "user"
    case ai = "ai"
}
