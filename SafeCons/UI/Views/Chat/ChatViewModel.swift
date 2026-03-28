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
    
    private let cryptoService: CryptoServiceProtocol
    
    init(cryptoService: CryptoServiceProtocol) {
        self.cryptoService = cryptoService
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
}
