//
//  SupabaseService.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let supabaseURL = SupabaseConfig.url
    private let supabaseKey = SupabaseConfig.anonKey
    
    private let client: SupabaseClient
    
    @Published var conversations: [Conversation] = []
    @Published var currentConversationMessages: [Message] = []
    
    private var currentUser: User?
    
    private var conversationSubscription: RealtimeChannelV2?
    private var messageSubscription: RealtimeChannelV2?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
        
        // SupabaseService now gets auth state from AuthService
    }
    
    // MARK: - Auth State Management
    
    func handleAuthStateChange(user: User?) {
        self.currentUser = user
        
        if user == nil {
            // User signed out - clear data
            conversations = []
            currentConversationMessages = []
            unsubscribeAll()
        }
    }
    
    // MARK: - Conversations CRUD
    
    nonisolated func fetchConversations() async throws -> [Conversation] {
        let user = await MainActor.run {
            return currentUser
        }
        
        guard user != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        // Use APIService for backend communication with proper auth
        let response = try await APIService.shared.fetchConversations()
        
        await MainActor.run {
            self.conversations = response
        }
        
        return response
    }
    
    nonisolated func createConversation() async throws -> Conversation {
        let user = await MainActor.run {
            return currentUser
        }
        
        guard user != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        // Use APIService for backend communication with proper auth
        let conversation = try await APIService.shared.createConversation()
        
        await MainActor.run {
            self.conversations.insert(conversation, at: 0)
        }
        
        return conversation
    }
    
    nonisolated func deleteConversation(_ conversationId: Int64) async throws {
        let user = await MainActor.run {
            return currentUser
        }
        
        guard user != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        // Use APIService for backend communication with proper auth
        try await APIService.shared.deleteConversation(conversationId: conversationId)
        
        await MainActor.run {
            self.conversations.removeAll { $0.id == conversationId }
        }
    }
    
    // MARK: - Messages CRUD
    
    nonisolated func fetchMessages(for conversationId: Int64) async throws -> [Message] {
        let user = await MainActor.run {
            return currentUser
        }
        
        guard user != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        // Use APIService for backend communication with proper auth
        let response = try await APIService.shared.fetchConversationMessages(conversationId: conversationId)
        
        await MainActor.run {
            self.currentConversationMessages = response
        }
        
        return response
    }
    
    nonisolated func sendMessage(content: String, conversationId: Int64) async throws -> Message {
        let user = await MainActor.run {
            return currentUser
        }
        
        guard user != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        // Use APIService for backend communication with proper auth
        // The backend handles both user message saving and AI response generation
        let chatResponse = try await APIService.shared.sendMessage(
            content: content,
            conversationId: conversationId
        )
        
        // Refresh messages to get the latest state from backend
        _ = try await fetchMessages(for: conversationId)
        
        // Return a mock message since the backend doesn't return the saved message directly
        // In a real implementation, you'd want the backend to return the saved user message
        let mockUserMessage = Message(
            id: Int64.random(in: 1000...9999),
            conversationId: conversationId,
            role: .user,
            content: content,
            createdAt: Date()
        )
        
        return mockUserMessage
    }
    
    // MARK: - Real-time Subscriptions
    
    func subscribeToConversations() async {
        guard let userId = currentUser?.id else { return }
        
        // For now, disable realtime subscriptions to avoid compilation errors
        // TODO: Implement proper RealtimeV2 subscriptions once the API is stable
        
        // Fallback to periodic refresh
        Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    try? await self.fetchConversations()
                }
            }
            .store(in: &cancellables)
    }
    
    func subscribeToMessages(conversationId: Int64) async {
        guard currentUser?.id != nil else { return }
        
        // For now, disable realtime subscriptions to avoid compilation errors
        // TODO: Implement proper RealtimeV2 subscriptions once the API is stable
        
        // Fallback to periodic refresh
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    try? await self.fetchMessages(for: conversationId)
                }
            }
            .store(in: &cancellables)
    }
    
    func unsubscribeAll() {
        Task {
            if let conversationSub = conversationSubscription {
                await conversationSub.unsubscribe()
                conversationSubscription = nil
            }
            
            if let messageSub = messageSubscription {
                await messageSub.unsubscribe()
                messageSubscription = nil
            }
        }
        
        cancellables.removeAll()
    }
}

// MARK: - Helper Models

struct ConversationInsert: Codable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

struct MessageInsert: Codable {
    let conversationId: Int64
    let role: MessageRole
    let content: String
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case role
        case content
    }
}

// MARK: - Custom Errors

enum SupabaseError: Error, LocalizedError {
    case notAuthenticated
    case unexpectedResponse
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .unexpectedResponse:
            return "Unexpected response from server"
        }
    }
}