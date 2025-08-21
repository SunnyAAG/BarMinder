//
//  AppDelegate.swift
//  WifeOnTheMenuBar
//
//  Created by Artiom Gramatin on 25.07.2025.
//


import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let settingsPopover = NSPopover()

    // MARK: - App Launch
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopovers()
        setupNotifications()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.action = #selector(togglePopover(_:))
        updateIconFromDefaults()
    }

    private func setupPopovers() {
        let contentView = PopoverView(appDelegate: self)
        popover.contentSize = NSSize(width: 250, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self   // ✅ VERY IMPORTANT
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print(granted ? "✅ Notifications allowed" : "❌ Notifications denied")
            }
        }
    }

    // MARK: - Popover Management
    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if settingsPopover.isShown { settingsPopover.performClose(nil) }
        popover.isShown ? popover.performClose(sender)
                        : popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func openSettings() {
        guard let button = statusItem.button else { return }
        if popover.isShown { popover.performClose(nil) }

        settingsPopover.contentSize = NSSize(width: 300, height: 360)
        settingsPopover.behavior = .semitransient
        settingsPopover.contentViewController = NSHostingController(rootView: SettingsView())
        settingsPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func openPopoverView() {
        guard let button = statusItem.button else { return }
        if settingsPopover.isShown { settingsPopover.performClose(nil) }

        popover.contentSize = NSSize(width: 250, height: 350)
        popover.behavior = .semitransient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(appDelegate: self)
        )

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
            selector: #selector(openSettings),
            name: NSNotification.Name("OpenSettings"),
            object: nil
        )
        NotificationCenter.default.addObserver(self,
            selector: #selector(openPopoverView),
            name: NSNotification.Name("openPopoverView"),
            object: nil
        )
    }

    // MARK: - Menu Bar Icon
    func updateIconFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: "SavedImageData"),
           let nsImage = NSImage(data: data) {
            setMenuBarImage(nsImage)
        } else {
            setDefaultImage()
        }
    }

    func setMenuBarImage(_ image: NSImage) {
        let targetSize = NSSize(width: 22, height: 22)
        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: .zero,
                   operation: .sourceOver,
                   fraction: 1.0)
        resized.unlockFocus()
        resized.isTemplate = false
        statusItem.button?.image = resized
    }

    func setDefaultImage() {
        if let image = NSImage(named: "wifeIcon") {
            setMenuBarImage(image)
        }
    }

    // MARK: - Notifications
    func sendNotification(title: String, body: String, image: NSImage? = nil) {
        Task {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            if let attachment = await makeImageAttachment(from: image) {
                content.attachments = [attachment]
            }

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )

            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    private func makeImageAttachment(from image: NSImage?) async -> UNNotificationAttachment? {
        guard let image = image,
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notifImage.png")
        do {
            try pngData.write(to: tempURL)
            return try UNNotificationAttachment(identifier: "notifImage", url: tempURL)
        } catch {
            print("Could not create notification attachment: \(error)")
            return nil
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list]) // ✅ show when app is open
    }
}
