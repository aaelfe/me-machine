//
//  Conversation.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation

struct Conversation: Identifiable, Codable {
   let id = UUID()
   let date: Date
   let summary: String
   let messages: [Message]
   
   var isToday: Bool {
       Calendar.current.isDateInToday(date)
   }
   
   var formattedDate: String {
       let formatter = DateFormatter()
       if isToday {
           return "Today"
       } else if Calendar.current.isDateInYesterday(date) {
           return "Yesterday"
       } else {
           formatter.dateStyle = .medium
           return formatter.string(from: date)
       }
   }
}

let mockConversations = [
   Conversation(
       date: Date(),
       summary: "Discussed career goals and upcoming decisions",
       messages: [
           Message(content: "How are things going?", isFromFuture: false, timestamp: Date()),
           Message(content: "You're going to love what happens next month with your project.", isFromFuture: true, timestamp: Date())
       ]
   ),
   Conversation(
       date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
       summary: "Talked about relationships and personal growth",
       messages: [
           Message(content: "I'm feeling uncertain about my relationship", isFromFuture: false, timestamp: Date()),
           Message(content: "Trust me, the conversation you have this weekend changes everything.", isFromFuture: true, timestamp: Date())
       ]
   ),
   Conversation(
       date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
       summary: "Future self gave advice about health habits",
       messages: [
           Message(content: "Should I start working out more?", isFromFuture: false, timestamp: Date()),
           Message(content: "Yes! You start running in two weeks and it becomes your favorite part of the day.", isFromFuture: true, timestamp: Date())
       ]
   )
]
