    //
    //  Persistence.swift
    //  SwiftStoreApp
    //
    //  Created by Vicenzo Másera on 26/08/25.
    //

import SwiftUI
import SwiftData

@MainActor
class AppContainer {
    
    static var shared = AppContainer()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    let userService: UserServiceProtocol
    let cryptoService: CryptoServiceProtocol
    let networkService: NetworkServiceProtocol
    
    
    private init() {
        self.modelContainer = try! ModelContainer(for: User.self , Message.self , Chat.self)
        self.modelContext = modelContainer.mainContext
        let crypto = CryptoService()
        self.cryptoService = crypto
        
        let network = NetworkService()
        self.networkService = network
        
        self.userService = UserService(modelContext: modelContext, cryptoService: crypto)
        
        network.startListening { [weak self] payloadData in
            Task { @MainActor in
                self?.processIncomingGlobalMessage(payload: payloadData)
            }
        }
    }
    
    private func processIncomingGlobalMessage(payload: Data) {
        do {
            let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.isMe == false })
            let contacts = try modelContext.fetch(descriptor)
            
            var messageSaved = false
            for contact in contacts {
                do {
                    let decryptedText = try self.cryptoService.decryptMessage(encryptedData: payload, senderPublicKey: contact.publicKey)
                    if let chat = contact.chats.first {
                        let newMessage = Message(sender: contact, content: payload, isEncrypted: true)
                        chat.messages.append(newMessage)
                        chat.updatedAt = .now
                        try modelContext.save()
                        
                        messageSaved = true
                        
                            // UNUserNotificationCenter
                        
                        break
                    }
                } catch {
                    continue
                }
            }
            
            if !messageSaved {
                print("mensagem recebida, mas não pertence a nenhum contato conhecido.")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
}
