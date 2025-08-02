//
//  AppDelegate.swift
//  WifeOnTheMenuBar
//
//  Created by Artiom Gramatin on 25.07.2025.
//

import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let settingsPopover = NSPopover()

    
    // MARK: - App Launch
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopovers()
        requestNotificationPermission()
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

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                if granted { print("Notifications allowed") }
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

        settingsPopover.contentSize = NSSize(width: 300, height: 180)
        settingsPopover.behavior = .semitransient
        settingsPopover.contentViewController = NSHostingController(rootView: SettingsView())
        settingsPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: NSNotification.Name("OpenSettings"),
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
        // 🎯 Resize icon to fit menu bar perfectly
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

    // MARK: - Notifications (Swift Concurrency)
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
}
