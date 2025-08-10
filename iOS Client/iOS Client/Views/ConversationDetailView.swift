//
//  ConversationDetailView.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

struct ConversationDetailView: View {
    @State private var conversation: Conversation
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var messages: [Message] = []
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = APIService.shared
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var webSocketService = WebSocketService.shared
    
    init(conversation: Conversation) {
        self._conversation = State(initialValue: conversation)
        self._messages = State(initialValue: conversation.messages)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            // Show streaming message if active
                            if let streamingMessage = apiService.streamingMessage,
                               streamingMessage.conversationId == conversation.id {
                                StreamingMessageBubble(streamingMessage: streamingMessage)
                                    .id("streaming")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) {
                        if let lastMessage = messages.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: apiService.streamingMessage?.content) {
                        // Auto-scroll when streaming message updates
                        if apiService.streamingMessage != nil {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo("streaming", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message Input
                MessageInputView(
                    messageText: $messageText,
                    onSend: sendMessage,
                    isLoading: isLoading
                )
            }
            .navigationTitle(conversation.formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Toggle Dark Mode") {
                            toggleDarkMode()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            Task {
                // Load messages for this conversation
                try? await supabaseService.fetchConversationMessages(conversationId: conversation.id)
                
                // Connect to WebSocket for this conversation
                try? await webSocketService.connect()
            }
        }
        .onDisappear {
            // Disconnect WebSocket when leaving conversation
            webSocketService.disconnect()
        }
        .onReceive(supabaseService.$currentConversationMessages) { newMessages in
            messages = newMessages
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty && !isLoading else { return }
        
        isLoading = true
        let messageToSend = trimmedMessage
        messageText = ""
        
        Task {
            do {
                _ = try await apiService.sendMessageWithStreaming(
                    content: messageToSend,
                    conversationId: conversation.id
                )
                
                await MainActor.run {
                    isLoading = false
                    // Messages will be updated via streaming completion handler
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    messageText = messageToSend // Restore message on error
                    print("Error sending message: \(error)")
                }
            }
        }
    }
    
    private func toggleDarkMode() {
        @AppStorage("isDarkMode") var isDarkMode = false
        isDarkMode.toggle()
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if !message.isFromFuture {
                Spacer()
            }
            
            VStack(alignment: message.isFromFuture ? .leading : .trailing, spacing: 4) {
                Text(message.content)
                    .padding()
                    .background(message.isFromFuture ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if message.isFromFuture {
                Spacer()
            }
        }
    }
}

struct StreamingMessageBubble: View {
    let streamingMessage: StreamingMessage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(streamingMessage.content + (streamingMessage.isComplete ? "" : "▊"))
                    .padding()
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(16)
                    .animation(.easeInOut(duration: 0.1), value: streamingMessage.content)
                
                if streamingMessage.isComplete {
                    Text(Date(), style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Text("AI is typing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Typing indicator
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.secondary)
                                    .frame(width: 4, height: 4)
                                    .scaleEffect(typingScale)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                        value: typingScale
                                    )
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            typingScale = 1.2
        }
    }
    
    @State private var typingScale: CGFloat = 1.0
}

#Preview {
    ConversationDetailView(conversation: mockConversations[0])
}
