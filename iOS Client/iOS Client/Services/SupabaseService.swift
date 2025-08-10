//
//  SupabaseService.swift
//  MeMachine
//
//  Created by Allan Elfe on 8/9/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    @Published var conversations: [Conversation] = []
    @Published var currentConversationMessages: [Message] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        // Listen for auth state changes
        AuthService.shared.$currentUser
            .sink { [weak self] user in
                if user == nil {
                    self?.conversations = []
                    self?.currentConversationMessages = []
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Conversations
    
    func fetchConversations() async throws -> [Conversation] {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw ServiceError.notAuthenticated
        }
        
        let conversations: [Conversation] = try await client
            .from("conversations")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        self.conversations = conversations
        return conversations
    }
    
    func createConversation() async throws -> Conversation {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw ServiceError.notAuthenticated
        }
        
        let newConversation = [
            "user_id": userId.uuidString
        ]
        
        let conversation: Conversation = try await client
            .from("conversations")
            .insert(newConversation)
            .select()
            .single()
            .execute()
            .value
        
        self.conversations.insert(conversation, at: 0)
        return conversation
    }
    
    func deleteConversation(conversationId: Int64) async throws {
        guard AuthService.shared.currentUser != nil else {
            throw ServiceError.notAuthenticated
        }
        
        try await client
            .from("conversations")
            .delete()
            .eq("id", value: String(conversationId))
            .execute()
        
        self.conversations.removeAll { $0.id == conversationId }
    }
    
    // MARK: - Messages
    
    func fetchConversationMessages(conversationId: Int64) async throws -> [Message] {
        guard AuthService.shared.currentUser != nil else {
            throw ServiceError.notAuthenticated
        }
        
        let messages: [Message] = try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: String(conversationId))
            .order("created_at", ascending: true)
            .execute()
            .value
        
        self.currentConversationMessages = messages
        return messages
    }
    
    // MARK: - Real-time Subscriptions (Future Enhancement)
    
    func subscribeToConversationMessages(conversationId: Int64) {
        // TODO: Implement real-time subscriptions when RealtimeV2 is working
        // For now, we'll rely on polling/manual refresh
    }
    
    func unsubscribeFromMessages() {
        // TODO: Implement unsubscribe logic
    }
}