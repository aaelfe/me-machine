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
    @StateObject private var supabaseService = SupabaseService.shared
    
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
                try? await supabaseService.fetchMessages(for: conversation.id)
                // Subscribe to realtime updates for this conversation
                await supabaseService.subscribeToMessages(conversationId: conversation.id)
            }
        }
        .onDisappear {
            supabaseService.unsubscribeAll()
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
                _ = try await supabaseService.sendMessage(
                    content: messageToSend,
                    conversationId: conversation.id
                )
                
                await MainActor.run {
                    isLoading = false
                    // Messages will be updated via realtime subscription
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

#Preview {
    ConversationDetailView(conversation: mockConversations[0])
}
