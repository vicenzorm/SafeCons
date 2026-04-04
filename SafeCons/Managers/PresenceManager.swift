//
//  PresenceManager.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 04/04/26.
//

import Foundation
import Observation

@MainActor
protocol PresenceManagerProtocol {
    var activePublicKeys: [String: Date] { get set }

    func isContactOnline(publicKeyHash: String) -> Bool
    func markSeen(publicKeyHash: String)
    func clearSeen(publicKeyHash: String)
    func pruneInactivePublicKeys()
}

@Observable
@MainActor
final class PresenceManager: PresenceManagerProtocol {
    var activePublicKeys: [String: Date] = [:]

    private var cleanupTimer: Timer?

    init() {
        startCleanupTimer()
    }

    func markSeen(publicKeyHash: String) {
        activePublicKeys[publicKeyHash] = Date()
    }

    func isContactOnline(publicKeyHash: String) -> Bool {
        guard let lastSeen = activePublicKeys[publicKeyHash] else { return false }
        return lastSeen.timeIntervalSinceNow > -60
    }

    func clearSeen(publicKeyHash: String) {
        activePublicKeys.removeValue(forKey: publicKeyHash)
    }

    func pruneInactivePublicKeys() {
        activePublicKeys = activePublicKeys.filter { $0.value.timeIntervalSinceNow >= -120 }
    }

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pruneInactivePublicKeys()
            }
        }
    }
}
