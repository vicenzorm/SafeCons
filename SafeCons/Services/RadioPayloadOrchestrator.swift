//
//  RadioPayloadOrchestrator.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 04/04/26.
//

import Foundation

@MainActor
protocol RadioPayloadOrchestratorProtocol {
    func process(payload: Data) async
}

@MainActor
final class RadioPayloadOrchestrator: RadioPayloadOrchestratorProtocol {
    private let userService: UserServiceProtocol
    private let cryptoService: CryptoServiceProtocol
    private let messageRepository: MessageRepositoryProtocol
    private let requestManager: ConnectionRequestManager
    private let presenceManager: PresenceManagerProtocol
    private let notificationManager: NotificationManagerProtocol

    init(
        userService: UserServiceProtocol,
        cryptoService: CryptoServiceProtocol,
        messageRepository: MessageRepositoryProtocol,
        requestManager: ConnectionRequestManager,
        presenceManager: PresenceManagerProtocol,
        notificationManager: NotificationManagerProtocol
    ) {
        self.userService = userService
        self.cryptoService = cryptoService
        self.messageRepository = messageRepository
        self.requestManager = requestManager
        self.presenceManager = presenceManager
        self.notificationManager = notificationManager
    }

    func process(payload: Data) async {
        do {
            let envelope = try JSONDecoder().decode(TransportEnvelope.self, from: payload)

            let decryptedPayload = try cryptoService.decryptMessage(
                encryptedData: envelope.encryptedPayload,
                senderPublicKey: envelope.senderPublicKey
            )

            guard let parsedData = parseTimestampedPayload(decryptedPayload) else {
                return
            }

            let senderKeyHash = cryptoService.hashPublicKey(envelope.senderPublicKey)
            presenceManager.markSeen(publicKeyHash: senderKeyHash)

            let currentTimestamp = Int(Date().timeIntervalSince1970)
            if currentTimestamp - parsedData.timestamp > 60 {
                return
            }

            if parsedData.message == "[SYS_PING]" {
                return
            }

            if parsedData.message == "[SYS_KNOCK]" {
                if try userService.fetchContact(publicKey: envelope.senderPublicKey) == nil {
                    requestManager.receiveRequest(
                        publicKey: envelope.senderPublicKey,
                        payload: envelope.encryptedPayload,
                        senderName: parsedData.senderName
                    )
                    notificationManager.triggerPrivateNotification()
                }
                return
            }

            if let existingContact = try userService.fetchContact(publicKey: envelope.senderPublicKey) {
                if let chat = existingContact.chats.first(where: { room in
                    room.participants.contains(where: { $0.isMe }) && room.participants.count == 2
                }) {
                    try messageRepository.saveMessage(
                        senderId: existingContact.id,
                        chatId: chat.id,
                        content: envelope.encryptedPayload,
                        isEncrypted: true
                    )
                    chat.updatedAt = .now
                    notificationManager.triggerPrivateNotification()
                }
            } else {
                requestManager.receiveRequest(
                    publicKey: envelope.senderPublicKey,
                    payload: envelope.encryptedPayload,
                    senderName: parsedData.senderName
                )
                notificationManager.triggerPrivateNotification()
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    private func parseTimestampedPayload(_ payload: String) -> (timestamp: Int, senderName: String, message: String)? {
        let parts = payload.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, let timestamp = Int(parts[0]) else {
            return nil
        }
        return (timestamp: timestamp, senderName: String(parts[1]), message: String(parts[2]))
    }
}
