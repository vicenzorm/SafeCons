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
    let connectionOrchestrator: ConnectionOrchestratorProtocol

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

        let radioOrchestrator = RadioPayloadOrchestrator(
            userService: users,
            cryptoService: crypto,
            messageRepository: repository,
            requestManager: requests,
            presenceManager: presence,
            notificationManager: notifications
        )
        self.radioPayloadOrchestrator = radioOrchestrator

        let connectionOrchestrator = ConnectionOrchestrator(
            userService: users,
            messageRepository: repository,
            requestManager: requests
        )
        self.connectionOrchestrator = connectionOrchestrator

        network.startListening { payload in
            Task { @MainActor in
                await radioOrchestrator.process(payload: payload)
            }
        }

        notifications.requestNotificationPermission()
    }
}
