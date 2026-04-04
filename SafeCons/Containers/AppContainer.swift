//
//  AppContainer.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 26/08/25.
//

import SwiftData
import SwiftUI

@Observable
@MainActor
class AppContainer {
    static var shared = AppContainer()

    let modelContainer: ModelContainer
    let modelContext: ModelContext

    let userService: UserServiceProtocol
    let cryptoService: CryptoServiceProtocol
    let networkService: NetworkServiceProtocol
    let messageRepository: MessageRepositoryProtocol

    let requestManager: ConnectionRequestManager
    let presenceManager: PresenceManagerProtocol
    let notificationManager: NotificationManagerProtocol
    let radioPayloadOrchestrator: RadioPayloadOrchestratorProtocol

    private init() {
        self.modelContainer = try! ModelContainer(for: User.self, Message.self, Chat.self)
        self.modelContext = modelContainer.mainContext

        let crypto = CryptoService()
        self.cryptoService = crypto

        let network = NetworkService()
        self.networkService = network

        let requests = ConnectionRequestManager()
        self.requestManager = requests

        let presence = PresenceManager()
        self.presenceManager = presence

        let notifications = NotificationManager()
        self.notificationManager = notifications

        let repository = MessageRepository(modelContext: modelContext)
        self.messageRepository = repository

        let users = UserService(modelContext: modelContext, cryptoService: crypto)
        self.userService = users

        let orchestrator = RadioPayloadOrchestrator(
            userService: users,
            cryptoService: crypto,
            messageRepository: repository,
            requestManager: requests,
            presenceManager: presence,
            notificationManager: notifications
        )
        self.radioPayloadOrchestrator = orchestrator

        network.startListening { payload in
            Task { @MainActor in
                await orchestrator.process(payload: payload)
            }
        }

        notifications.requestNotificationPermission()
    }

    func acceptConnection(_ request: ConnectionRequest) async {
        do {
            let newContact = try await userService.createContact(name: request.senderName, publicKey: request.publicKey)
            if let newChat = newContact.chats.first {
                try messageRepository.saveMessage(
                    senderId: newContact.id,
                    chatId: newChat.id,
                    content: request.payload,
                    isEncrypted: true
                )
                newChat.updatedAt = .now
                try modelContext.save()
            }
        } catch {
            print(error.localizedDescription)
        }
        requestManager.removeRequest(request)
    }

    func rejectConnection(_ request: ConnectionRequest) {
        requestManager.removeRequest(request)
    }
}
