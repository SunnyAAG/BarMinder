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
    @AppStorage("popoverTitle") private var popoverTitle = "Your MenuBar Photo"

    var body: some View {
        VStack(spacing: 15) {
            VStack{
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }
            .padding(.top, 20)

            HStack {
                Text("Send Daily At:")
                DatePicker("", selection: Binding(
                    get: {
                        Calendar.current.date(from: DateComponents(hour: notificationHour, minute: notificationMinute)) ?? Date()
                    },
                    set: { newDate in
                        let cal = Calendar.current
                        notificationHour = cal.component(.hour, from: newDate)
                        notificationMinute = cal.component(.minute, from: newDate)
                        scheduleDailyNotification()
                    }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Notification Message:")
                    .font(.headline)

                NotificationMessageEditor(text: $notificationMessage)
            }
            .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 6) {
                            Text("Popover Title:")
                                .font(.headline)

                            TextField("Enter a title", text: $popoverTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.trailing, 2)
                        }

            Button("Send Preview Notification") {
                sendPreviewNotification()
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .frame(width: 300, height: 360)
        .onChange(of: notificationMessage) { _, _ in scheduleDailyNotification() }
        .onChange(of: notificationsEnabled) { _, _ in scheduleDailyNotification() }
    }

    private func loadSavedImage() -> NSImage? {
        guard let data = UserDefaults.standard.data(forKey: "SavedImageData") else { return nil }
        return NSImage(data: data)
    }

    private func scheduleDailyNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = notificationMessage
        content.sound = .default

        if let image = loadSavedImage(),
           let attachment = createImageAttachment(from: image) {
            content.attachments = [attachment]
        }

        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func sendPreviewNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Preview Notification"
        content.body = notificationMessage
        content.sound = .default

        if let image = loadSavedImage(),
           let attachment = createImageAttachment(from: image) {
            content.attachments = [attachment]
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func createImageAttachment(from image: NSImage) -> UNNotificationAttachment? {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else { return nil }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notifImage.png")

        do {
            try pngData.write(to: tempURL)
            return try UNNotificationAttachment(identifier: "notifImage", url: tempURL)
        } catch {
            print("Could not save or attach image: \(error)")
            return nil
        }
    }
}

#Preview {
    SettingsView()
}
