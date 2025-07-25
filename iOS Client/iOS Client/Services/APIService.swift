//
//  APIService.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation
import Combine

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = SupabaseConfig.backendURL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Conversations
    
    func fetchConversations(userId: String) async throws -> [Conversation] {
        let url = URL(string: "\(baseURL)/conversations/?user_id=\(userId)")!
        let (data, _) = try await session.data(from: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([Conversation].self, from: data)
    }
    
    func createConversation(userId: String) async throws -> Conversation {
        let url = URL(string: "\(baseURL)/conversations/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["user_id": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await session.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Conversation.self, from: data)
    }
    
    func fetchConversationMessages(conversationId: Int, userId: String) async throws -> [Message] {
        let url = URL(string: "\(baseURL)/conversations/\(conversationId)/messages?user_id=\(userId)")!
        let (data, _) = try await session.data(from: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(ConversationMessagesResponse.self, from: data)
        return response.messages
    }
    
    // MARK: - Chat
    
    func sendMessage(content: String, conversationId: Int?, userId: String) async throws -> ChatResponse {
        let url = URL(string: "\(baseURL)/chat/message")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatRequest = ChatRequest(
            message: content,
            conversationId: conversationId,
            returnAudio: false,
            contextType: "check_in"
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(chatRequest)
        
        // Add user_id as query parameter for now (until auth is implemented)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        request.url = components.url
        
        let (data, _) = try await session.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ChatResponse.self, from: data)
    }
}

// MARK: - Request/Response Models

struct ChatRequest: Codable {
    let message: String
    let conversationId: Int?
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
    let conversationId: Int
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
    let conversationId: Int
    let messages: [Message]
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case messages
    }
}