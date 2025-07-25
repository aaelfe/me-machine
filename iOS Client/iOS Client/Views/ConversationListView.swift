//
//  ConversationListView.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import SwiftUI

struct ConversationListView: View {
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var showingNewConversation = false
    @State private var showingProfile = false
    
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var authService = AuthService.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // New conversation button
                    Button(action: createNewConversation) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Start New Conversation")
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(isLoading)
                    
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
                    
                    if conversations.isEmpty && !isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No conversations yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Start your first conversation with your future self")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Future Self")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { isDarkMode.toggle() }) {
                            Label(isDarkMode ? "Light Mode" : "Dark Mode", 
                                  systemImage: isDarkMode ? "sun.max" : "moon")
                        }
                        
                        Button("Refresh") {
                            loadConversations()
                        }
                        
                        Divider()
                        
                        Button("Profile") {
                            showingProfile = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                loadConversations()
            }
        }
        .onAppear {
            loadConversations()
            Task {
                await supabaseService.subscribeToConversations()
            }
        }
        .onReceive(supabaseService.$conversations) { newConversations in
            conversations = newConversations
        }
        .sheet(isPresented: $showingNewConversation) {
            if let newConversation = conversations.first(where: { $0.isToday }) {
                ConversationDetailView(conversation: newConversation)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }
    
    private func loadConversations() {
        isLoading = true
        
        Task {
            do {
                _ = try await supabaseService.fetchConversations()
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Fall back to mock data on error
                    conversations = mockConversations
                    print("Error loading conversations: \(error)")
                }
            }
        }
    }
    
    private func createNewConversation() {
        isLoading = true
        
        Task {
            do {
                _ = try await supabaseService.createConversation()
                
                await MainActor.run {
                    isLoading = false
                    showingNewConversation = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Fall back to creating a mock conversation on error
                    let mockConversation = Conversation(
                        id: Int64.random(in: 1000...9999),
                        userId: authService.currentUser?.id ?? UUID(),
                        createdAt: Date(),
                        messages: []
                    )
                    conversations.insert(mockConversation, at: 0)
                    showingNewConversation = true
                    print("Error creating conversation: \(error)")
                }
            }
        }
    }
}

#Preview {
    ConversationListView()
}
