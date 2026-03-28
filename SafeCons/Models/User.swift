//
//  User.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 26/03/26.
//

import Foundation
import SwiftData

@Model
final class User: Identifiable {
    var id: UUID
    var name: String
    
    @Attribute(.unique)
    var publicKey: Data
    
    var isMe: Bool
    
    @Relationship(inverse: \Chat.participants)
    var chats: [Chat]
    
    init(name: String, publicKey: Data, isMe: Bool) {
        self.id = UUID()
        self.name = name
        self.publicKey = publicKey
        self.isMe = isMe
        self.chats = []
    }
}
