//
//  CryptoService.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//
import Foundation
import CryptoKit

@MainActor
protocol CryptoServiceProtocol {
    func generateKeyPair() throws -> (Data, Data)
    func encryptMessage(text: String, recipientPublicKey: Data) throws -> Data
    func decryptMessage(encryptedData: Data, senderPublicKey: Data) throws -> String
    func hashPublicKey(_ key: Data) -> String
}

@MainActor
final class CryptoService: CryptoServiceProtocol {
    
    static let shared = CryptoService()
    
    init() {
        do {
            try loadKeyFromKeychain()
        } catch {
            print(error)
        }
    }
    
    private var myPrivateKey: SecureEnclave.P256.KeyAgreement.PrivateKey?
    
    func generateKeyPair() throws -> (Data, Data) {
        let newPrivateKey = try SecureEnclave.P256.KeyAgreement.PrivateKey()
        self.myPrivateKey = newPrivateKey
        
        try KeychainManager.save(keyTicket: newPrivateKey.dataRepresentation)
        return (newPrivateKey.publicKey.rawRepresentation, newPrivateKey.dataRepresentation)
    }
    
    func encryptMessage(text: String, recipientPublicKey: Data) throws -> Data {
        guard let myKey = self.myPrivateKey else {
            throw NSError(domain: "No private key", code: 1)
        }
        let friendPublicKey = try P256.KeyAgreement.PublicKey(rawRepresentation: recipientPublicKey)
        let sharedSecret = try myKey.sharedSecretFromKeyAgreement(with: friendPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data(), sharedInfo: Data(), outputByteCount: 32)
        
        guard let messageData = text.data(using: .utf8) else {
            throw NSError(domain: "Can't translate text to utf8", code: 2)
        }
        let sealedBox = try AES.GCM.seal(messageData, using: symmetricKey)
        guard let encryptedData = sealedBox.combined else {
            throw NSError(domain: "Can't combine sealedBox", code: 3)
        }
        return encryptedData
    }
    
    func decryptMessage(encryptedData: Data, senderPublicKey: Data) throws -> String {
        guard let myKey = self.myPrivateKey else {
            throw NSError(domain: "No private key", code: 1)
        }
        let friendPublicKey = try P256.KeyAgreement.PublicKey(rawRepresentation: senderPublicKey)
        let sharedSecret = try myKey.sharedSecretFromKeyAgreement(with: friendPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data(), sharedInfo: Data(), outputByteCount: 32)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        let text = String(data: decryptedData, encoding: .utf8) ?? "Can't decode data"
        
        return text
    }
    
    private func loadKeyFromKeychain() throws {
        guard let ticket = KeychainManager.load() else { return }
        self.myPrivateKey = try SecureEnclave.P256.KeyAgreement.PrivateKey(dataRepresentation: ticket)
    }
    
    func hashPublicKey(_ key: Data) -> String {
        let hash = SHA256.hash(data: key)
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16).description
    }
}
