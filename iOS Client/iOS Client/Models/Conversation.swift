//
//  Conversation.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation

struct Conversation: Identifiable, Codable {
    let id: Int
    let userId: String  // Keep as String for compatibility with Supabase UUID
    let createdAt: Date
    var messages: [Message] = []
    var messageCount: Int = 0
    
    // Computed properties for UI
    var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        if isToday {
            return "Today"
        } else if Calendar.current.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: createdAt)
        }
    }
    
    var summary: String {
        if let lastMessage = messages.last {
            return String(lastMessage.content.prefix(50)) + (lastMessage.content.count > 50 ? "..." : "")
        }
        return "New conversation"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case messageCount = "message_count"
    }
}

// Mock data for development
let mockConversations = [
    Conversation(
        id: 1,
        userId: "mock-user-id",
        createdAt: Date(),
        messages: [
            Message(id: 1, conversationId: 1, role: .user, content: "How are things going?", createdAt: Date()),
            Message(id: 2, conversationId: 1, role: .ai, content: "You're going to love what happens next month with your project.", createdAt: Date())
        ],
        messageCount: 2
    ),
    Conversation(
        id: 2,
        userId: "mock-user-id",
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        messages: [
            Message(id: 3, conversationId: 2, role: .user, content: "I'm feeling uncertain about my relationship", createdAt: Date()),
            Message(id: 4, conversationId: 2, role: .ai, content: "Trust me, the conversation you have this weekend changes everything.", createdAt: Date())
        ],
        messageCount: 2
    ),
    Conversation(
        id: 3,
        userId: "mock-user-id",
        createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        messages: [
            Message(id: 5, conversationId: 3, role: .user, content: "Should I start working out more?", createdAt: Date()),
            Message(id: 6, conversationId: 3, role: .ai, content: "Yes! You start running in two weeks and it becomes your favorite part of the day.", createdAt: Date())
        ],
        messageCount: 2
    )
]
