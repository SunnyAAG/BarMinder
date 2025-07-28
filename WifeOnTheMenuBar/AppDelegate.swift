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
    var statusItem: NSStatusItem!
    let popover = NSPopover()
    let settingsPopover = NSPopover()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            updateIconFromDefaults()
        }
        let contentView = PopoverView(appDelegate: self)
        popover.contentSize = NSSize(width: 250, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notifications allowed")
            }
        }
    }

    // MARK: - Popover Management

    @objc func togglePopover(_ sender: Any?) {
        if let button = statusItem.button {
            if settingsPopover.isShown {
                settingsPopover.performClose(nil)
            }

            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    @objc func openSettings() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            }

            settingsPopover.contentSize = NSSize(width: 300, height: 180)
            settingsPopover.behavior = .transient
            settingsPopover.contentViewController = NSHostingController(rootView: SettingsView())
            settingsPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(openSettings), name: NSNotification.Name("OpenSettings"), object: nil)
    }

    // MARK: - Menu Bar Icon

    func updateIconFromDefaults() {
        if let imageData = UserDefaults.standard.data(forKey: "SavedImageData"),
           let nsImage = NSImage(data: imageData) {
            setMenuBarImage(nsImage)
        } else {
            setDefaultImage()
        }
    }

    func setMenuBarImage(_ image: NSImage) {
        let resized = NSImage(size: NSSize(width: 22, height: 22))
        resized.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: 22, height: 22))
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
        var pngData: Data? = nil
        if let image = image,
           let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData) {
            pngData = bitmap.representation(using: .png, properties: [:])
        }
        DispatchQueue.global(qos: .utility).async {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default

            if let data = pngData {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("notifImage.png")
                do {
                    try data.write(to: tempURL)
                    if let attachment = try? UNNotificationAttachment(identifier: "notifImage",
                                                                      url: tempURL,
                                                                      options: nil) {
                        content.attachments = [attachment]
                    }
                } catch {
                    print("Could not save temp image: \(error)")
                }
            }

            let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                content: content,
                                                trigger: nil)

            UNUserNotificationCenter.current().add(request)
        }
    }


}
