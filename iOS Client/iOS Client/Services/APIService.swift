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
    private let webSocketService = WebSocketService.shared
    private let supabaseService = SupabaseService.shared
    
    @Published var streamingMessage: StreamingMessage?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Subscribe to WebSocket streaming messages
        webSocketService.$streamingMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$streamingMessage)
    }
    
    // MARK: - Auth Helper
    
    private func getAuthToken() async throws -> String? {
        do {
            return try await AuthService.shared.getAuthToken()
        } catch {
            throw ServiceError.notAuthenticated
        }
    }
    
    
    // MARK: - Chat
    
    func sendMessage(content: String, conversationId: Int64?) async throws -> ChatResponse {
        guard let url = URL(string: "http://\(baseURL)/api/v1/chat/message") else {
            throw ServiceError.invalidURL
        }
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
    
    // MARK: - Message Management
    
    func sendMessageWithStreaming(content: String, conversationId: Int64) async throws -> Message {
        // Try WebSocket streaming first, fallback to HTTP
        do {
            try await webSocketService.sendMessageStreaming(
                content: content,
                conversationId: conversationId,
                onMessageComplete: { @Sendable [weak self] finalMessage, responseConversationId in
                    Task { @MainActor in
                        // Refresh messages when streaming is complete
                        try? await self?.supabaseService.fetchConversationMessages(conversationId: responseConversationId)
                    }
                }
            )
        } catch {
            print("WebSocket failed, falling back to HTTP: \(error)")
            
            // Fallback to HTTP API
            let chatResponse = try await sendMessage(
                content: content,
                conversationId: conversationId
            )
            
            // Refresh messages to get the latest state from backend
            _ = try await supabaseService.fetchConversationMessages(conversationId: conversationId)
        }
        
        // Return a mock message since the backend doesn't return the saved message directly
        let mockUserMessage = Message(
            id: Int64.random(in: 1000...9999),
            conversationId: conversationId,
            role: .user,
            content: content,
            createdAt: Date()
        )
        
        return mockUserMessage
    }
    
    // MARK: - Auth State Management
    
    func handleAuthStateChange(user: User?) {
        // Auth state changes are now handled by SupabaseService
        // APIService only handles streaming messages
    }
}

// MARK: - Shared Service Errors

enum ServiceError: Error, LocalizedError {
    case notAuthenticated
    case notImplemented
    case invalidCredentials
    case userNotFound
    case invalidResponse
    case networkError
    case invalidURL
    case connectionFailed
    case messageEncodingFailed
    case unexpectedResponse
    case notConnected
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .notImplemented:
            return "Feature not implemented yet"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError:
            return "Network error occurred"
        case .invalidURL:
            return "Invalid URL"
        case .connectionFailed:
            return "Connection failed"
        case .messageEncodingFailed:
            return "Failed to encode message"
        case .unexpectedResponse:
            return "Unexpected response from server"
        case .notConnected:
            return "WebSocket not connected"
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

