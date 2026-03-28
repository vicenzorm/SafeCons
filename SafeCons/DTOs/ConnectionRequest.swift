//
//  ConnectionRequest.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 28/03/26.
//
import SwiftUI

struct ConnectionRequest: Identifiable {
    let id = UUID()
    let publicKey: Data
    let payload: Data
    let timeStamp = Date()
    let senderName: String
}
