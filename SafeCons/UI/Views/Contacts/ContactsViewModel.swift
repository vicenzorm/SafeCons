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
    
    init(userService: UserServiceProtocol, cryptoService: CryptoServiceProtocol, networkService: NetworkServiceProtocol, messageRepository: MessageRepositoryProtocol) {
        self.userService = userService
        self.cryptoService = cryptoService
        self.networkService = networkService
        self.messageRepository = messageRepository
    }
    
    func addContact(scannedCode: String) async throws {
        guard let data = scannedCode.data(using: .utf8) else { return }
        
        let payload = try JSONDecoder().decode(QRCodePayload.self, from: data)
        if let existingContact = try userService.fetchContact(publicKey: payload.publicKey) {
            self.errorMessage = "A connection with \(payload.name) already exists"
            self.showAlert = true
            return
        }
        let newContact = try await userService.createContact(name: payload.name, publicKey: payload.publicKey)
        AppContainer.shared.sendKnock(to: newContact)
        
    }
    
    func generateCardColors(name: String) -> [Color] {
        cryptoService.generateIdentityColors(from: name)
    }
    
    func isPeerConnected(publicKey: Data) -> Bool {
        _ = networkService.connectedPeers
        return AppContainer.shared.isContactOnline(publicKey: publicKey)
    }
    
    func refreshScan() {
        networkService.startScanning()
        AppContainer.shared.broadcastHeartbeat()
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
            chatId: chat.id,
            currentUserId: currentUser.id,
            currentUserName: currentUser.name,
            currentUserPublicKey: currentUser.publicKey,
            targetPublicKey: targetUser.publicKey
        )
    }
    
    func removeContact(contact: User) {
        do {
            try userService.deleteContact(publicKey: contact.publicKey)
            
            let hash = cryptoService.hashPublicKey(contact.publicKey)
            AppContainer.shared.activePublicKeys.removeValue(forKey: hash)
            
            networkService.disconnectAllPeers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
