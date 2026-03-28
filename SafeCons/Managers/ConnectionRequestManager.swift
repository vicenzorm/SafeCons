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
    var isShowingRequest: Bool = false
    
    var pendingRequests: [ConnectionRequest] = []
    
    func receiveRequest(publicKey: Data, payload: Data) {
        let newRequest = ConnectionRequest(publicKey: publicKey, payload: payload)
        pendingRequests.append(newRequest)
        self.isShowingRequest = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func clear() {
        if !pendingRequests.isEmpty {
            pendingRequests.removeFirst()
        }
        self.isShowingRequest = !pendingRequests.isEmpty
    }
}

struct ConnectionRequest {
    let publicKey: Data
    let payload: Data
}
