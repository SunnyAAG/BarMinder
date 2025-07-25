//
//  SettingsView.swift
//  WifeOnTheMenuBar
//
//  Created by Artiom Gramatin on 25.07.2025.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("notificationHour") private var notificationHour = 9
    @AppStorage("notificationMinute") private var notificationMinute = 0
    @AppStorage("notificationMessage") private var notificationMessage = "Here’s a daily note from your WifeOnTheMenuBar."

    var body: some View {
        VStack(spacing: 15) {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)

            HStack {
                Text("Send Daily At:")
                DatePicker("", selection: Binding(
                    get: {
                        let cal = Calendar.current
                        return cal.date(from: DateComponents(hour: notificationHour, minute: notificationMinute)) ?? Date()
                    },
                    set: { newDate in
                        let cal = Calendar.current
                        notificationHour = cal.component(.hour, from: newDate)
                        notificationMinute = cal.component(.minute, from: newDate)
                        scheduleDailyNotification(hour: notificationHour, minute: notificationMinute)
                    }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Notification Message:")
                    .font(.headline)

                TextEditor(text: $notificationMessage)
                    .frame(height: 80)
                    .border(Color.gray.opacity(0.5), width: 1)
                    .cornerRadius(6)
            }
            .padding(.top, 8)
            
            Button("Send Preview Notification") {
                sendPreviewNotification()
            }
            .padding(.top, 8)


            Spacer()
        }
        .padding()
        .frame(width: 280, height: 270)
        .onChange(of: notificationMessage) {oldValue, newValue in
            scheduleDailyNotification(hour: notificationHour, minute: notificationMinute)
        }
        .onChange(of: notificationsEnabled) {oldValue, newValue in
            scheduleDailyNotification(hour: notificationHour, minute: notificationMinute)
        }
    }

    func scheduleDailyNotification(hour: Int, minute: Int) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        if notificationsEnabled {
            let content = UNMutableNotificationContent()
            content.title = "💕 Reminder"
            content.body = notificationMessage
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let request = UNNotificationRequest(identifier: "dailyNotification",
                                                content: content,
                                                trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }
    }
    func sendPreviewNotification() {
        let content = UNMutableNotificationContent()
        content.title = "💕 Preview Notification"
        content.body = notificationMessage
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil) // immediate trigger

        UNUserNotificationCenter.current().add(request)
    }

}



#Preview {
    SettingsView()
}
