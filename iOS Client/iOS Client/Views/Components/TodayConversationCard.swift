//
//  TodayConversationCard.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

struct TodayConversationCard: View {
    let conversation: Conversation
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(conversation.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            
            // Message preview
            if let lastMessage = conversation.messages.last {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(lastMessage.isFromFuture ? "Future You" : "You")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(lastMessage.isFromFuture ? .purple : .blue)
                        Spacer()
                        Text(lastMessage.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(lastMessage.content)
                        .font(.body)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture {
            // Navigate to full conversation
            isExpanded = true
        }
        .sheet(isPresented: $isExpanded) {
            ConversationDetailView(conversation: conversation)
        }
    }
}
