//
//  NotificationManager.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 04/04/26.
//

import Foundation
import UserNotifications
import Observation

@MainActor
protocol NotificationManagerProtocol {
    func requestNotificationPermission()
    func triggerPrivateNotification()
}

@Observable
@MainActor
final class NotificationManager: NotificationManagerProtocol {
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func triggerPrivateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "SafeCons"
        content.body = "You have a new message."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
