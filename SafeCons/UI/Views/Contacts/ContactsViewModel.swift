//
//  ContactsViewModel.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//
import Foundation
import SwiftUI

@MainActor
protocol ContactsViewModelProtocol {
    var errorMessage: String? { get }
    var showAlert: Bool { get set }
    var isShowingCamera: Bool { get set }
    
    func addContact(scannedCode: String) async throws
    func removeContact(contact: User)
}

@Observable
@MainActor
final class ContactsViewModel: ContactsViewModelProtocol {
    var errorMessage: String?
    var showAlert: Bool = false
    var isShowingCamera: Bool = false
    
    private let userService: UserServiceProtocol
    private let cryptoService: CryptoServiceProtocol
    private let networkService: NetworkServiceProtocol
    private let messageRepository: MessageRepositoryProtocol
    private let presenceManager: PresenceManagerProtocol
    
    init(userService: UserServiceProtocol, cryptoService: CryptoServiceProtocol, networkService: NetworkServiceProtocol, messageRepository: MessageRepositoryProtocol, presenceManager: PresenceManagerProtocol) {
        self.userService = userService
        self.cryptoService = cryptoService
        self.networkService = networkService
        self.messageRepository = messageRepository
        self.presenceManager = presenceManager
    }
    
    func addContact(scannedCode: String) async throws {
        guard let data = scannedCode.data(using: .utf8) else { return }
        
        let payload = try JSONDecoder().decode(QRCodePayload.self, from: data)
        if (try userService.fetchContact(publicKey: payload.publicKey)) != nil {
            self.errorMessage = "A connection with \(payload.name) already exists"
            self.showAlert = true
            return
        }
        let newContact = try await userService.createContact(name: payload.name, publicKey: payload.publicKey)
        sendKnock(to: newContact)
        
    }
    
    func generateCardColors(name: String) -> [Color] {
        cryptoService
            .generateIdentityColors(from: name)
            .map { color(fromHex: $0) }
    }

    private func color(fromHex hex: String) -> Color {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard sanitized.count == 6, let rgb = UInt64(sanitized, radix: 16) else {
            return .gray
        }

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
    
    func isPeerConnected(publicKey: Data) -> Bool {
        _ = networkService.connectedPeers
        let hash = cryptoService.hashPublicKey(publicKey)
        return presenceManager.isContactOnline(publicKeyHash: hash)
    }
    
    func refreshScan() {
        networkService.startScanning()
        broadcastHeartbeat()
    }
    
    func makeChatViewModel(chat: Chat) -> ChatViewModel {
        guard let currentUser = chat.participants.first(where: { $0.isMe }),
              let targetUser = chat.participants.first(where: { !$0.isMe }) else {
            preconditionFailure("Chat participants are inconsistent")
        }

        return ChatViewModel(
            cryptoService: self.cryptoService,
            networkService: self.networkService,
            messageRepository: self.messageRepository,
            presenceManager: self.presenceManager,
            chatId: chat.id,
            currentUserId: currentUser.id,
            currentUserName: currentUser.name,
            currentUserPublicKey: currentUser.publicKey,
            targetPublicKey: targetUser.publicKey
        )
    }
    
    private func broadcastHeartbeat() {
        guard let me = try? userService.fetchOwnUserData() else { return }

        let pingPayload = "\(Int(Date().timeIntervalSince1970))|\(me.name)|[SYS_PING]"

        guard let encrypted = try? cryptoService.encryptMessage(text: pingPayload, recipientPublicKey: me.publicKey) else {
            return
        }

        let envelope = TransportEnvelope(senderPublicKey: me.publicKey, encryptedPayload: encrypted)
        if let data = try? JSONEncoder().encode(envelope) {
            networkService.send(payload: data)
        }
    }

    private func sendKnock(to contact: User) {
        guard let me = try? userService.fetchOwnUserData() else { return }

        let knockPayload = "\(Int(Date().timeIntervalSince1970))|\(me.name)|[SYS_KNOCK]"

        guard let encrypted = try? cryptoService.encryptMessage(text: knockPayload, recipientPublicKey: contact.publicKey) else {
            return
        }

        let envelope = TransportEnvelope(senderPublicKey: me.publicKey, encryptedPayload: encrypted)
        if let data = try? JSONEncoder().encode(envelope) {
            networkService.send(payload: data)
        }
    }

    func removeContact(contact: User) {
        do {
            try userService.deleteContact(publicKey: contact.publicKey)
            
            let hash = cryptoService.hashPublicKey(contact.publicKey)
            presenceManager.clearSeen(publicKeyHash: hash)
            
            networkService.disconnectAllPeers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
