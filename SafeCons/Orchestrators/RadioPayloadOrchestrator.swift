//
//  RadioPayloadOrchestrator.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 04/04/26.
//

class RadioPayloadOrchestrator {
    
    private let userService: UserServiceProtocol
    private let cryptoService: CryptoServiceProtocol
    private let messageRepository: MessageRepositoryProtocol
    private let notificationManager: NotificationManagerProtocol
    private let presenceManager: PresenceManagerProtocol
    
    init(userService: UserServiceProtocol, cryptoService: CryptoServiceProtocol, messageRepository: MessageRepositoryProtocol, notificationManager: NotificationManagerProtocol, presenceManager: PresenceManagerProtocol) {
        self.userService = userService
        self.cryptoService = cryptoService
        self.messageRepository = messageRepository
        self.notificationManager = notificationManager
        self.presenceManager = presenceManager
    }
}
