//
//  ConversationListView.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

struct ConversationListView: View {
    @State private var conversations: [Conversation] = mockConversations
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let todayConvo = conversations.first(where: { $0.isToday }) {
                        TodayConversationCard(conversation: todayConvo)
                            .padding(.horizontal)
                    }
                    
                    // Past conversations section
                    if !conversations.filter({ !$0.isToday }).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Past Conversations")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(conversations.filter { !$0.isToday }) { conversation in
                                    PastConversationRow(conversation: conversation)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Future Self")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ConversationListView()
}
