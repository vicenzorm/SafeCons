    //
    //  Persistence.swift
    //  SwiftStoreApp
    //
    //  Created by Vicenzo Másera on 26/08/25.
    //

import SwiftUI
import SwiftData
import UserNotifications

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
    var requestManager: ConnectionRequestManager
    
    var activePublicKeys: [String: Date] = [:]
    
    private var cleanupTimer: Timer?
    
    private init() {
        self.modelContainer = try! ModelContainer(for: User.self , Message.self , Chat.self)
        self.modelContext = modelContainer.mainContext
        let crypto = CryptoService()
        self.cryptoService = crypto
        
        let network = NetworkService()
        self.networkService = network
        
        let requestManager = ConnectionRequestManager()
        self.requestManager = requestManager

        self.messageRepository = MessageRepository(modelContext: modelContext)
        self.userService = UserService(modelContext: modelContext, cryptoService: crypto)
        
        network.startListening { [weak self] payloadData in
            Task { @MainActor in
                await self?.processIncomingGlobalMessage(payload: payloadData)
            }
        }
        
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func processIncomingGlobalMessage(payload: Data) async {
        do {
            let envelope = try JSONDecoder().decode(TransportEnvelope.self, from: payload)
            
            let decryptedPayload = try self.cryptoService.decryptMessage(encryptedData: envelope.encryptedPayload, senderPublicKey: envelope.senderPublicKey)
            
            guard let parsedData = parseTimestampedPayload(decryptedPayload) else {
                return
            }
            
            let senderKeyHash = cryptoService.hashPublicKey(envelope.senderPublicKey)
            activePublicKeys[senderKeyHash] = Date()
            
            let currentTimestamp = Int(Date().timeIntervalSince1970)
            if currentTimestamp - parsedData.timestamp > 60 {
                return
            }
            if parsedData.message == "[SYS_PING]" {
                return
            }
            
            if parsedData.message == "[SYS_KNOCK]" {
                if try self.userService.fetchContact(publicKey: envelope.senderPublicKey) == nil {
                    self.requestManager.receiveRequest(publicKey: envelope.senderPublicKey, payload: envelope.encryptedPayload, senderName: parsedData.senderName)
                    triggerPrivateNotification()
                }
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
                    triggerPrivateNotification()
                }
                
            } else {
                self.requestManager.receiveRequest(publicKey: envelope.senderPublicKey, payload: envelope.encryptedPayload, senderName: parsedData.senderName)
                triggerPrivateNotification()
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
    
    func isContactOnline(publicKey: Data) -> Bool {
        let hash = cryptoService.hashPublicKey(publicKey)
        
        if let lastSeen = activePublicKeys[hash], lastSeen.timeIntervalSinceNow > -60 {
            return true
        }
        return false
    }
    
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pruneInactivePublicKeys()
            }
        }
    }

    private func pruneInactivePublicKeys() {
        activePublicKeys = activePublicKeys.filter { $0.value.timeIntervalSinceNow >= -120 }
    }
    
    func triggerPrivateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "SafeCons"
        content.body = "Você tem uma nova mensagem."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func broadcastHeartbeat() {
        Task { @MainActor in
            let meDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.isMe })
            let contactsDescriptor = FetchDescriptor<User>(predicate: #Predicate { !$0.isMe  })
            
            guard let me = try? self.modelContext.fetch(meDescriptor).first,
                  let contacts = try? self.modelContext.fetch(contactsDescriptor) else { return }
            
            for contact in contacts {
                let payload = "\(Int(Date().timeIntervalSince1970))|\(me.name)|[SYS_PING]"
                
                guard let encrypted = try? self.cryptoService.encryptMessage(text: payload, recipientPublicKey: contact.publicKey) else { continue }
                
                let envelope = TransportEnvelope(senderPublicKey: me.publicKey, encryptedPayload: encrypted)
                if let data = try? JSONEncoder().encode(envelope) {
                    self.networkService.send(payload: data)
                }
            }
        }
    }
    
    func sendKnock(to contact: User) {
        Task { @MainActor in
            guard let me = try? self.userService.fetchOwnUserData() else { return }
            
            let payload = "\(Int(Date().timeIntervalSince1970))|\(me.name)|[SYS_KNOCK]"
            
            guard let encrypted = try? self.cryptoService.encryptMessage(text: payload, recipientPublicKey: contact.publicKey) else { return }
            
            let envelope = TransportEnvelope(senderPublicKey: me.publicKey, encryptedPayload: encrypted)
            if let data = try? JSONEncoder().encode(envelope) {
                self.networkService.send(payload: data)
            }
        }
    }
    
}
