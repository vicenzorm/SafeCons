//
//  ConnectionOrchestrator.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 04/04/26.
//

import Foundation

@MainActor
protocol ConnectionOrchestratorProtocol {
    func acceptConnection(_ request: ConnectionRequest) async
    func rejectConnection(_ request: ConnectionRequest)
}

@MainActor
final class ConnectionOrchestrator: ConnectionOrchestratorProtocol {
    private let userService: UserServiceProtocol
    private let messageRepository: MessageRepositoryProtocol
    private let requestManager: ConnectionRequestManager

    init(
        userService: UserServiceProtocol,
        messageRepository: MessageRepositoryProtocol,
        requestManager: ConnectionRequestManager
    ) {
        self.userService = userService
        self.messageRepository = messageRepository
        self.requestManager = requestManager
    }

    func acceptConnection(_ request: ConnectionRequest) async {
        do {
            let newContact = try await userService.createContact(name: request.senderName, publicKey: request.publicKey)
            guard let chatId = newContact.chats.first?.id else {
                requestManager.removeRequest(request)
                return
            }

            try messageRepository.saveMessage(
                senderId: newContact.id,
                chatId: chatId,
                content: request.payload,
                isEncrypted: true
            )
        } catch {
            print(error.localizedDescription)
        }

        requestManager.removeRequest(request)
    }

    func rejectConnection(_ request: ConnectionRequest) {
        requestManager.removeRequest(request)
    }
}
