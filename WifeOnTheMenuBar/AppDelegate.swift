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
                   print("✅ Notifications allowed")
               }
           }
    }

    @objc func togglePopover(_ sender: Any?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    func updateIconFromDefaults() {
        if let imageData = UserDefaults.standard.data(forKey: "SavedImageData"),
           let nsImage = NSImage(data: imageData) {
            setMenuBarImage(nsImage)
        } else {
            setDefaultImage()
        }
    }


    func setMenuBarImage(_ image: NSImage) {
        image.size = NSSize(width: 22, height: 22)
        image.isTemplate = false
        statusItem.button?.image = image
    }

    func setDefaultImage() {
        if let image = NSImage(named: "wifeIcon") {
            setMenuBarImage(image)
        }
    }
    
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil) // send immediately
        UNUserNotificationCenter.current().add(request)
    }
    
    let settingsPopover = NSPopover()

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(openSettings), name: NSNotification.Name("OpenSettings"), object: nil)
    }

    @objc func openSettings() {
        if let button = statusItem.button {
            settingsPopover.contentSize = NSSize(width: 300, height: 180)
            settingsPopover.behavior = .transient
            settingsPopover.contentViewController = NSHostingController(rootView: SettingsView())
            settingsPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    
}
