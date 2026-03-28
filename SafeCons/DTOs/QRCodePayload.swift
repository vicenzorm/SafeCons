//
//  QRCodePayload.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//


import Foundation

struct QRCodePayload: Codable {
    let name: String
    let publicKey: Data
}
