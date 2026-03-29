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
    
    func saveMessage(user: User, chat: Chat)
    func decryptMessage(message: Message, chat: Chat) -> String
}

@Observable
@MainActor
final class ChatViewModel: ChatViewModelProtocol {
    
    var newMessage: String = ""
    
    private let networkService: NetworkServiceProtocol
    private let cryptoService: CryptoServiceProtocol
    
    private let currentChat: Chat
    
    var isTunnelActive: Bool {
        _ = networkService.connectedPeers
        
        guard let targetContact = currentChat.participants.first(where: { !$0.isMe }) else {
            return false
        }
        return AppContainer.shared.isContactOnline(publicKey: targetContact.publicKey)
    }
    
    init(cryptoService: CryptoServiceProtocol, networkService: NetworkServiceProtocol, chat: Chat) {
        self.cryptoService = cryptoService
        self.networkService = networkService
        self.currentChat = chat
    }
    
    func saveMessage(user: User, chat: Chat) {
        let otherUser = chat.participants.first(where: { !$0.isMe })
        if let otherUser {
            do {
                let timestamp = Int(Date().timeIntervalSince1970)
                let payloadToEncrypt = "\(timestamp)|\(user.name)|\(newMessage)"
                let encryptedData = try cryptoService.encryptMessage(text: payloadToEncrypt, recipientPublicKey: otherUser.publicKey)
                let message = Message(sender: user, content: encryptedData, isEncrypted: true)
                chat.messages.append(message)
                
                let envelope = TransportEnvelope(senderPublicKey: user.publicKey, encryptedPayload: encryptedData)
                if let envelopeData = try? JSONEncoder().encode(envelope) {
                    networkService.send(payload:envelopeData)
                }
            } catch {
                print(error)
            }
        }
        chat.updatedAt = .now
        newMessage = ""
    }
    
    func decryptMessage(message: Message, chat: Chat) -> String {
        guard message.isEncrypted else {
            return String(data: message.content, encoding: .utf8) ?? "Erro de codificação"
        }
        if let otherPublicKey = chat.participants.first(where: { !$0.isMe })?.publicKey {
            do {
                let decryptedMessage = try cryptoService.decryptMessage(encryptedData: message.content, senderPublicKey: otherPublicKey)
                return extractMessageFromPayload(decryptedMessage)
            } catch {
                print(error)
            }
        }
        return "error at decrypting"
    }
    
    private func extractMessageFromPayload(_ payload: String) -> String {
        let parts = payload.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
        if parts.count == 3 {
            return String(parts[2])
        }
        return String(parts[1])
    }
}
