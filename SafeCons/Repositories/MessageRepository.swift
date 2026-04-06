//
//  MessageRepository.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 04/04/26.
//

import Foundation
import SwiftData

protocol MessageRepositoryProtocol {
    func saveMessage(senderId: UUID, chatId: UUID, content: Data, isEncrypted: Bool) throws
}

final class MessageRepository: MessageRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveMessage(senderId: UUID, chatId: UUID, content: Data, isEncrypted: Bool) throws {
        enum RepositoryError: Error {
            case chatNotFound
            case senderNotFound
        }

        let senderDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == senderId })
        guard let sender = try modelContext.fetch(senderDescriptor).first else {
            throw RepositoryError.senderNotFound
        }

        let chatDescriptor = FetchDescriptor<Chat>(predicate: #Predicate { $0.id == chatId })
        guard let chat = try modelContext.fetch(chatDescriptor).first else {
            throw RepositoryError.chatNotFound
        }

        let message = Message(sender: sender, content: content, isEncrypted: isEncrypted)
        chat.messages.append(message)
        chat.updatedAt = Date.now
        try modelContext.save()
    }
}
