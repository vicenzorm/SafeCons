//
//  User.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 26/03/26.
//

import Foundation
import SwiftData

@Model
final class Chat: Identifiable {
    var id: UUID
    
    var participants: [User]
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Message.chat)
    var messages: [Message]
    
    init() {
        self.id = UUID()
        self.participants = []
        self.messages = []
        self.updatedAt = Date.now
    }
}
