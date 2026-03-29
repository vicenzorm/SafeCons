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
    
    init(userService: UserServiceProtocol, cryptoService: CryptoServiceProtocol, networkService: NetworkServiceProtocol) {
        self.userService = userService
        self.cryptoService = cryptoService
        self.networkService = networkService
    }
    
    func addContact(scannedCode: String) async throws {
        guard let data = scannedCode.data(using: .utf8) else { return }
        
        let payload = try JSONDecoder().decode(QRCodePayload.self, from: data)
        if let existingContact = try userService.fetchContact(publicKey: payload.publicKey) {
            self.errorMessage = "A connection with \(payload.name) already exists"
            self.showAlert = true
            return
        }
        _ = try await userService.createContact(name: payload.name, publicKey: payload.publicKey)
        
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
}
