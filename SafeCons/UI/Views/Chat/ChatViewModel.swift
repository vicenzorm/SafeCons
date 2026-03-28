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
    
    init(cryptoService: CryptoServiceProtocol, networkService: NetworkServiceProtocol, chat: Chat) {
        self.cryptoService = cryptoService
        self.networkService = networkService
        self.currentChat = chat
        
        self.networkService.startListening { [weak self] payloadData in
            Task { @MainActor in
                self?.handleIncoming(payload: payloadData)
            }
        }
    }
    
    func saveMessage(user: User, chat: Chat) {
        let otherUser = chat.participants.first(where: { !$0.isMe})
        if let otherUser {
            do {
                let encryptedData = try cryptoService.encryptMessage(text: newMessage, recipientPublicKey: otherUser.publicKey)
                let message = Message(sender: user, content: encryptedData, isEncrypted: true)
                chat.messages.append(message)
            } catch {
                print(error)
            }
        }
        chat.updatedAt = .now
        newMessage = ""
    }
    
    func decryptMessage(message: Message, chat: Chat) -> String {
        guard message.isEncrypted else {
            return String(data: message.content, encoding: .utf8) ?? "[Erro de codificação]"
        }
        if let otherPublicKey = chat.participants.first(where: { !$0.isMe })?.publicKey {
            do {
                let decryptedMessage = try cryptoService.decryptMessage(encryptedData: message.content, senderPublicKey: otherPublicKey)
                return decryptedMessage
            } catch {
                print(error)
            }
        }
        return "error at decrypting"
    }
    
    private func handleIncoming(payload: Data) {
        do {
            guard let otherUser = currentChat.participants.first(where: { !$0.isMe }) else {
                return
            }
            let decryptedMessage = try cryptoService.decryptMessage(encryptedData: payload, senderPublicKey: otherUser.publicKey)
            let newMessage = Message(sender: otherUser, content: payload, isEncrypted: true)
            currentChat.messages.append(newMessage)
            currentChat.updatedAt = .now
        
        } catch {
            
        }
    }
}
