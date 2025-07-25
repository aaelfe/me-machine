//
//  APIService.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = SupabaseConfig.backendURL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Auth Helper
    
    private func getAuthToken() async throws -> String? {
        let authService = AuthService.shared
        let user = await MainActor.run {
            return authService.currentUser
        }
        
        guard user != nil else {
            throw APIError.notAuthenticated
        }
        
        // Get the current session token from Supabase
        let client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        let session = try await client.auth.session
        return session.accessToken
    }
    
    // MARK: - Conversations
    
    func fetchConversations() async throws -> [Conversation] {
        let url = URL(string: "\(baseURL)/api/v1/conversations/")!
        var request = URLRequest(url: url)
        
        // Add auth header
        if let token = try? await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await session.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([Conversation].self, from: data)
    }
    
    func createConversation() async throws -> Conversation {
        let url = URL(string: "\(baseURL)/api/v1/conversations/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header
        if let token = try? await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await session.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Conversation.self, from: data)
    }
    
    func fetchConversationMessages(conversationId: Int64) async throws -> [Message] {
        let url = URL(string: "\(baseURL)/api/v1/conversations/\(conversationId)/messages")!
        var request = URLRequest(url: url)
        
        // Add auth header
        if let token = try? await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await session.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(ConversationMessagesResponse.self, from: data)
        return response.messages
    }
    
    func deleteConversation(conversationId: Int64) async throws {
        let url = URL(string: "\(baseURL)/api/v1/conversations/\(conversationId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Add auth header
        if let token = try? await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode != 200 {
            throw APIError.networkError
        }
    }
    
    // MARK: - Chat
    
    func sendMessage(content: String, conversationId: Int64?) async throws -> ChatResponse {
        let url = URL(string: "\(baseURL)/api/v1/chat/message")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header
        if let token = try? await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let chatRequest = ChatRequest(
            message: content,
            conversationId: conversationId,
            returnAudio: false,
            contextType: "check_in"
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(chatRequest)
        
        let (data, _) = try await session.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ChatResponse.self, from: data)
    }
}

// MARK: - Custom Errors

enum APIError: Error, LocalizedError {
    case notAuthenticated
    case invalidResponse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - Request/Response Models

struct ChatRequest: Codable {
    let message: String
    let conversationId: Int64?
    let returnAudio: Bool
    let contextType: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case conversationId = "conversation_id"
        case returnAudio = "return_audio"
        case contextType = "context_type"
    }
}

struct ChatResponse: Codable {
    let message: String
    let conversationId: Int64
    let audioUrl: String?
    let suggestions: [String]?
    
    enum CodingKeys: String, CodingKey {
        case message
        case conversationId = "conversation_id"
        case audioUrl = "audio_url"
        case suggestions
    }
}

struct ConversationMessagesResponse: Codable {
    let conversationId: Int64
    let messages: [Message]
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case messages
    }
}