    //
    //  ConnectionRequestManager.swift
    //  SafeCons
    //
    //  Created by Vicenzo Másera on 28/03/26.
    //


import Foundation
import SwiftUI

@Observable
@MainActor
final class ConnectionRequestManager {
    var pendingRequests: [ConnectionRequest] = []
    
    func receiveRequest(publicKey: Data, payload: Data, senderName: String) {
        let newRequest = ConnectionRequest(publicKey: publicKey, payload: payload, senderName: senderName)
        pendingRequests.append(newRequest)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func removeRequest(_ request: ConnectionRequest) {
        pendingRequests.removeAll { $0.id == request.id }
    }
}
