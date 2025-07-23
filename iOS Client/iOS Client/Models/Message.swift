//
//  Message.swift
//  MeMachine
//
//  Created by Allan Elfe on 7/22/25.
//

import Foundation

struct Message: Identifiable, Codable {
   let id = UUID()
   let content: String
   let isFromFuture: Bool
   let timestamp: Date
}
