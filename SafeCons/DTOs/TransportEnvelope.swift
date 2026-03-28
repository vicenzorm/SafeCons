//
//  TransportEnvelope.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//


import Foundation

struct TransportEnvelope: Codable {
    let senderPublicKey: Data
    let encryptedPayload: Data
}
