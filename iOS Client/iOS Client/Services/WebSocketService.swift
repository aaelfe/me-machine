//
//  WebSocketService.swift
//  MeMachine
//
//  Created by Allan Elfe on 8/3/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    
    private let baseURL = SupabaseConfig.backendURL
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession
    
    @Published var connectionState: WebSocketConnectionState = .disconnected
    @Published var streamingMessage: StreamingMessage?
    
    private var cancellables = Set<AnyCancellable>()
    private var messageCompletionHandler: (@Sendable (String, Int64) -> Void)?
    
    private init() {
        self.urlSession = URLSession(configuration: .default)
    }
    
    // MARK: - Connection Management
    
    private var connectionTask: Task<Void, Error>?
    
    func connect() async throws {
        // If already connected, return early
        guard connectionState != .connected else { return }
        
        // If already connecting, wait for existing connection
        if connectionState == .connecting, let existingTask = connectionTask {
            try await existingTask.value
            return
        }
        
        // Cancel any existing connection task
        connectionTask?.cancel()
        
        connectionTask = Task {
            connectionState = .connecting
            
            // Use wss:// for secure WebSocket connections
            let wsProtocol = baseURL.hasPrefix("localhost") || baseURL.hasPrefix("127.0.0.1") ? "ws" : "wss"
            guard let wsURL = URL(string: "\(wsProtocol)://\(baseURL)/api/v1/chat/ws") else {
                connectionState = .disconnected
                throw ServiceError.invalidURL
            }
            
            var request = URLRequest(url: wsURL)
            
            // Add auth header
            if let token = try? await getAuthToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            webSocketTask = urlSession.webSocketTask(with: request)
            webSocketTask?.resume()
            
            connectionState = .connected
            
            // Start listening for messages
            await startListening()
        }
        
        try await connectionTask?.value
    }
    
    func disconnect() {
        connectionTask?.cancel()
        connectionTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
        streamingMessage = nil
    }
    
    // MARK: - Message Streaming
    
    func sendMessageStreaming(
        content: String,
        conversationId: Int64?,
        onMessageComplete: @escaping @Sendable (String, Int64) -> Void
    ) async throws {
        // Ensure we're connected before sending
        try await connect()
        
        messageCompletionHandler = onMessageComplete
        
        let authToken = try? await getAuthToken()
        let chatRequest = WebSocketChatRequest(
            message: content,
            conversationId: conversationId,
            returnAudio: false,
            contextType: "check_in",
            authToken: authToken
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(chatRequest)
        let jsonString = String(data: data, encoding: .utf8)!
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        
        // Initialize streaming message
        streamingMessage = StreamingMessage(
            conversationId: conversationId ?? 0,
            content: "",
            isComplete: false
        )
        
        guard let webSocketTask = webSocketTask, connectionState == .connected else {
            throw ServiceError.notConnected
        }
        try await webSocketTask.send(message)
    }
    
    // MARK: - Private Methods
    
    private func startListening() async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let message = try await webSocketTask.receive()
            await handleMessage(message)
            
            // Continue listening if still connected
            if connectionState == .connected {
                await startListening()
            }
        } catch {
            print("WebSocket error: \(error)")
            connectionState = .disconnected
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .data(let data):
            await handleDataMessage(data)
        case .string(let text):
            await handleTextMessage(text)
        @unknown default:
            print("Unknown WebSocket message type")
        }
    }
    
    private func handleDataMessage(_ data: Data) async {
        do {
            let response = try JSONDecoder().decode(WebSocketResponse.self, from: data)
            await handleWebSocketResponse(response)
        } catch {
            print("Failed to decode WebSocket message: \(error)")
        }
    }
    
    private func handleTextMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else { return }
        await handleDataMessage(data)
    }
    
    private func handleWebSocketResponse(_ response: WebSocketResponse) async {
        switch response.type {
        case .messageChunk:
            if let chunk = response.chunk {
                appendToStreamingMessage(chunk)
            }
        case .messageComplete:
            if let finalMessage = response.message,
               let conversationId = response.conversationId {
                completeStreamingMessage(finalMessage, conversationId: conversationId)
            }
        case .error:
            if let error = response.error {
                print("WebSocket error from server: \(error)")
                connectionState = .disconnected
                // Clear any streaming message on error
                streamingMessage = nil
                // Could notify UI about the error here
            }
        }
    }
    
    private func appendToStreamingMessage(_ chunk: String) {
        guard var streaming = streamingMessage else { return }
        streaming.content += chunk
        streamingMessage = streaming
    }
    
    private func completeStreamingMessage(_ finalMessage: String, conversationId: Int64) {
        guard var streaming = streamingMessage else { return }
        streaming.content = finalMessage
        streaming.isComplete = true
        streamingMessage = streaming
        
        // Notify completion
        messageCompletionHandler?(finalMessage, conversationId)
        messageCompletionHandler = nil
        
        // Clear streaming message after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.streamingMessage = nil
        }
    }
    
    private func getAuthToken() async throws -> String? {
        do {
            return try await AuthService.shared.getAuthToken()
        } catch {
            throw ServiceError.notAuthenticated
        }
    }
}

// MARK: - Models

enum WebSocketConnectionState {
    case disconnected
    case connecting
    case connected
}

struct StreamingMessage {
    let conversationId: Int64
    var content: String
    var isComplete: Bool
}

struct WebSocketChatRequest: Codable {
    let message: String
    let conversationId: Int64?
    let returnAudio: Bool
    let contextType: String
    let authToken: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case conversationId = "conversation_id"
        case returnAudio = "return_audio"
        case contextType = "context_type"
        case authToken = "auth_token"
    }
}

struct WebSocketResponse: Codable {
    let type: WebSocketResponseType
    let chunk: String?
    let message: String?
    let conversationId: Int64?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case chunk
        case message
        case conversationId = "conversation_id"
        case error
    }
}

enum WebSocketResponseType: String, Codable {
    case messageChunk = "message_chunk"
    case messageComplete = "message_complete"
    case error = "error"
}


