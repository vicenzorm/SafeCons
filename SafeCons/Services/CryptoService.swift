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
    func generateKeyPair() -> Data
    func encryptMessage(text: String, recipientPublicKey: Data) throws -> Data
    func decryptMessage(encryptedData: Data, senderPublicKey: Data) throws -> String
}

@MainActor
final class CryptoService: CryptoServiceProtocol {
    
    static let shared = CryptoService()
    
    private var myPrivateKey: P256.KeyAgreement.PrivateKey?
    
    func generateKeyPair() -> Data {
        let newPrivateKey = P256.KeyAgreement.PrivateKey()
        self.myPrivateKey = newPrivateKey
        return newPrivateKey.publicKey.rawRepresentation
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
    
    
}
