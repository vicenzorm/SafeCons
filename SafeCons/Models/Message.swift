//
//  Item.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 26/03/26.
//

import Foundation
import SwiftData

@Model
final class Message: Identifiable {
    var id: UUID
    var timestamp: Date
    var content: Data
    var isEncrypted: Bool
    
    var sender: User?
    var chat: Chat?
    
    init(sender: User, content: Data, isEncrypted: Bool) {
        self.id = UUID()
        self.timestamp = Date.now
        self.sender = sender
        self.content = content
        self.isEncrypted = isEncrypted
    }
}
