//
//  NotificationModifier.swift
//  EventTapper
//
//  Created by Phil Zakharchenko on 12/14/24.
//

import Foundation
import SwiftUICore

extension View {
    func onNotification(
        named name: Notification.Name,
        notificationCallback: @escaping () -> Void
    ) -> some View {
        modifier(
            NotificationModifier<Any>(name: name) { _ in
                notificationCallback()
            }
        )
    }
    
    func onNotification<T>(
        named name: Notification.Name,
        objectType: T.Type,
        _ notificationCallback: @escaping (T?) -> Void
    ) -> some View {
        modifier(
            NotificationModifier(name: name, notificationCallback: notificationCallback)
        )
    }
}

fileprivate struct NotificationModifier<T>: ViewModifier {
    let name: Notification.Name
    let notificationCallback: (T?) -> Void
    
    func body(content: Content) -> some View {
        content
            .task {
                for await info in NotificationCenter.default.sendableNotifications(
                    T.self, named: name
                ) {
                    notificationCallback(info.object)
                }
            }
    }
}

fileprivate extension NotificationCenter {
    func sendableNotifications<T>(
        _ type: T.Type,
        named name: Notification.Name
    ) -> AsyncStream<SendableNotification<T>> {
        AsyncStream { continuation in
            let task = Task {
                for await notification in NotificationCenter.default.notifications(named: name) {
                    continuation.yield(SendableNotification(notification))
                }
            }
            
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

final fileprivate class SendableNotification<T> {
    var name: Notification.Name { notification.name }
    var object: T? { notification.object as? T }
    var userInfo: [AnyHashable: Any]? { notification.userInfo }
    
    private let notification: Notification
    
    init(_ notification: Notification) {
        self.notification = notification
    }
}
