    //
    //  Persistence.swift
    //  SwiftStoreApp
    //
    //  Created by Vicenzo Másera on 26/08/25.
    //

import SwiftUI
import SwiftData

@Observable
@MainActor
class AppContainer {
    
    static var shared = AppContainer()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    let userService: UserServiceProtocol
    let cryptoService: CryptoServiceProtocol
    let networkService: NetworkServiceProtocol
    var requestManager: ConnectionRequestManager
    
    private init() {
        self.modelContainer = try! ModelContainer(for: User.self , Message.self , Chat.self)
        self.modelContext = modelContainer.mainContext
        let crypto = CryptoService()
        self.cryptoService = crypto
        
        let network = NetworkService()
        self.networkService = network
        
        let requestManager = ConnectionRequestManager()
        self.requestManager = requestManager
        
        self.userService = UserService(modelContext: modelContext, cryptoService: crypto)
        
        network.startListening { [weak self] payloadData in
            Task { @MainActor in
                await self?.processIncomingGlobalMessage(payload: payloadData)
            }
        }
    }
    
    private func processIncomingGlobalMessage(payload: Data) async {
        do {
            let envelope = try JSONDecoder().decode(TransportEnvelope.self, from: payload)
            
            let decryptedPayload = try self.cryptoService.decryptMessage(encryptedData: envelope.encryptedPayload, senderPublicKey: envelope.senderPublicKey)
            
            guard let parsedData = parseTimestampedPayload(decryptedPayload) else {
                return
            }
            
            let currentTimestamp = Int(Date().timeIntervalSince1970)
            if currentTimestamp - parsedData.timestamp > 60 {
                return
            }
            
            if let existingContact = try self.userService.fetchContact(publicKey: envelope.senderPublicKey) {
                
                if let chat = existingContact.chats.first(where: { sala in
                    sala.participants.contains(where: { $0.isMe }) && sala.participants.count == 2
                }) {
                    let newMessage = Message(sender: existingContact, content: envelope.encryptedPayload, isEncrypted: true)
                    chat.messages.append(newMessage)
                    chat.updatedAt = .now
                    try self.modelContext.save()
                        // UNUserNotificationCenter de mensagem enviada para você
                }
                
            } else {
                    // UNUserNotificationCenter de novo contato tentando te adicionar
                self.requestManager.receiveRequest(publicKey: envelope.senderPublicKey, payload: envelope.encryptedPayload, senderName: parsedData.senderName)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func acceptConnection(_ request: ConnectionRequest) async {
        do {
            let newContact = try await userService.createContact(name: request.senderName, publicKey: request.publicKey)
            if let newChat = newContact.chats.first {
                let newMessage = Message(sender: newContact, content: request.payload, isEncrypted: true)
                newChat.messages.append(newMessage)
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
    
    private func parseTimestampedPayload(_ payload: String) -> (timestamp: Int, senderName: String, message: String)? {
        let parts = payload.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3, let timestamp = Int(parts[0]) else {
            return nil
        }
        return (timestamp: timestamp, senderName:String(parts[1]), message: String(parts[2]))
    }
}
