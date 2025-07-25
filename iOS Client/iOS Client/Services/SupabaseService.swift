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
        let userId = await MainActor.run { currentUser?.id }
        guard let userId = userId else {
            throw SupabaseError.notAuthenticated
        }
        
        let response: [Conversation] = try await client
            .from("conversations")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        await MainActor.run {
            self.conversations = response
        }
        
        return response
    }
    
    nonisolated func createConversation() async throws -> Conversation {
        let userId = await MainActor.run { currentUser?.id }
        guard let userId = userId else {
            throw SupabaseError.notAuthenticated
        }
        
        let newConversation = ConversationInsert(userId: userId.uuidString)
        
        let response: [Conversation] = try await client
            .from("conversations")
            .insert(newConversation)
            .select()
            .execute()
            .value
        
        guard let conversation = response.first else {
            throw SupabaseError.unexpectedResponse
        }
        
        await MainActor.run {
            self.conversations.insert(conversation, at: 0)
        }
        
        return conversation
    }
    
    nonisolated func deleteConversation(_ conversationId: Int) async throws {
        let userId = await MainActor.run { currentUser?.id }
        guard userId != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        try await client
            .from("conversations")
            .delete()
            .eq("id", value: conversationId)
            .execute()
        
        await MainActor.run {
            self.conversations.removeAll { $0.id == conversationId }
        }
    }
    
    // MARK: - Messages CRUD
    
    nonisolated func fetchMessages(for conversationId: Int) async throws -> [Message] {
        let userId = await MainActor.run { currentUser?.id }
        guard userId != nil else {
            throw SupabaseError.notAuthenticated
        }
        
        let response: [Message] = try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        await MainActor.run {
            self.currentConversationMessages = response
        }
        
        return response
    }
    
    nonisolated func sendMessage(content: String, conversationId: Int) async throws -> Message {
        let userId = await MainActor.run { currentUser?.id }
        guard let userId = userId else {
            throw SupabaseError.notAuthenticated
        }
        
        // Insert user message
        let userMessage = MessageInsert(
            conversationId: conversationId,
            role: .user,
            content: content
        )
        
        let userResponse: [Message] = try await client
            .from("messages")
            .insert(userMessage)
            .select()
            .execute()
            .value
        
        guard let savedUserMessage = userResponse.first else {
            throw SupabaseError.unexpectedResponse
        }
        
        // Update local messages immediately for better UX
        await MainActor.run {
            self.currentConversationMessages.append(savedUserMessage)
        }
        
        // Send to AI backend for processing
        do {
            let aiResponse = try await APIService.shared.sendMessage(
                content: content,
                conversationId: conversationId,
                userId: userId.uuidString
            )
            
            // Insert AI response
            let aiMessage = MessageInsert(
                conversationId: conversationId,
                role: .ai,
                content: aiResponse.message
            )
            
            let aiMessageResponse: [Message] = try await client
                .from("messages")
                .insert(aiMessage)
                .select()
                .execute()
                .value
            
            if let savedAiMessage = aiMessageResponse.first {
                await MainActor.run {
                    self.currentConversationMessages.append(savedAiMessage)
                }
            }
        } catch {
            print("Error getting AI response: \(error)")
            // AI response failed, but user message was saved
        }
        
        return savedUserMessage
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
    
    func subscribeToMessages(conversationId: Int) async {
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
    let conversationId: Int
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