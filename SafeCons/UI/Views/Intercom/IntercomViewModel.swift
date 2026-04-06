//
//  IntercomViewModel.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 04/04/26.
//

import Foundation

@MainActor
protocol IntercomViewModelProtocol {
    var requestManager: ConnectionRequestManager { get }

    func accept(_ request: ConnectionRequest) async
    func reject(_ request: ConnectionRequest)
}

@Observable
@MainActor
final class IntercomViewModel: IntercomViewModelProtocol {
    let requestManager: ConnectionRequestManager
    private let connectionOrchestrator: ConnectionOrchestratorProtocol

    init(
        requestManager: ConnectionRequestManager,
        connectionOrchestrator: ConnectionOrchestratorProtocol
    ) {
        self.requestManager = requestManager
        self.connectionOrchestrator = connectionOrchestrator
    }

    func accept(_ request: ConnectionRequest) async {
        await connectionOrchestrator.acceptConnection(request)
    }

    func reject(_ request: ConnectionRequest) {
        connectionOrchestrator.rejectConnection(request)
    }
}
