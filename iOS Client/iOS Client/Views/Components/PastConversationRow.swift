//
//  PastConversationRow.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

// Components/PastConversationRow.swift
import SwiftUI

struct PastConversationRow: View {
    let conversation: Conversation
    @State private var showingDetail = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.formattedDate)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(conversation.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(conversation.messages.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color.primary.opacity(0.3))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            ConversationDetailView(conversation: conversation)
        }
    }
}
