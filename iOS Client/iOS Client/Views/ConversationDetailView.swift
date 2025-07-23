//
//  ConversationDetailView.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

struct ConversationDetailView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(conversation.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            .navigationTitle(conversation.formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
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
