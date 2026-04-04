//
//  ChatViewModel.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//
import Foundation

@MainActor
protocol ChatViewModelProtocol {
    var newMessage: String { get set }
    var isTunnelActive: Bool { get }

    func saveMessage()
    func decryptMessage(encryptedData: Data, isEncrypted: Bool) -> String
}

@Observable
@MainActor
final class ChatViewModel: ChatViewModelProtocol {

    var newMessage: String = ""

    private let networkService: NetworkServiceProtocol
    private let cryptoService: CryptoServiceProtocol
    private let messageRepository: MessageRepositoryProtocol

    private let chatId: UUID
    private let currentUserId: UUID
    private let currentUserName: String
    private let currentUserPublicKey: Data
    private let targetPublicKey: Data

    var isTunnelActive: Bool {
        _ = networkService.connectedPeers
        return AppContainer.shared.isContactOnline(publicKey: targetPublicKey)
    }

    init(
        cryptoService: CryptoServiceProtocol,
        networkService: NetworkServiceProtocol,
        messageRepository: MessageRepositoryProtocol,
        chatId: UUID,
        currentUserId: UUID,
        currentUserName: String,
        currentUserPublicKey: Data,
        targetPublicKey: Data
    ) {
        self.cryptoService = cryptoService
        self.networkService = networkService
        self.messageRepository = messageRepository
        self.chatId = chatId
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.currentUserPublicKey = currentUserPublicKey
        self.targetPublicKey = targetPublicKey
    }

    func saveMessage() {
        do {
            let timestamp = Int(Date().timeIntervalSince1970)
            let payloadToEncrypt = "\(timestamp)|\(currentUserName)|\(newMessage)"

            let encryptedData = try cryptoService.encryptMessage(
                text: payloadToEncrypt,
                recipientPublicKey: targetPublicKey
            )

            do {
                try messageRepository.saveMessage(
                    senderId: currentUserId,
                    chatId: chatId,
                    content: encryptedData,
                    isEncrypted: true
                )
            } catch {
                print(error)
            }

            let envelope = TransportEnvelope(
                senderPublicKey: currentUserPublicKey,
                encryptedPayload: encryptedData
            )

            if let envelopeData = try? JSONEncoder().encode(envelope) {
                networkService.send(payload: envelopeData)
            }

            newMessage = ""
        } catch {
            print(error)
        }
    }

    func decryptMessage(encryptedData: Data, isEncrypted: Bool) -> String {
        guard isEncrypted else {
            return String(data: encryptedData, encoding: .utf8) ?? "error at encoding message"
        }

        do {
            let decryptedMessage = try cryptoService.decryptMessage(
                encryptedData: encryptedData,
                senderPublicKey: targetPublicKey
            )
            return extractMessageFromPayload(decryptedMessage)
        } catch {
            print(error)
            return "error at decrypting"
        }
    }

    private func extractMessageFromPayload(_ payload: String) -> String {
        let parts = payload.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
        if parts.count == 3 {
            let messageContent = String(parts[2])
            if messageContent == "[SYS_KNOCK]" {
                return "Terminal handshake accepted. Secure channel established."
            }
            return messageContent
        }
        return parts.count > 1 ? String(parts[1]) : payload
    }
}
