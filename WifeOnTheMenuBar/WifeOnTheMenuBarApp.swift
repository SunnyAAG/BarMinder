//
//  WifeOnTheMenuBarApp.swift
//  WifeOnTheMenuBar
//
//  Created by Artiom Gramatin on 25.07.2025.
//

import SwiftUI

@main
struct WifeOnTheMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // No system settings
        }
    }
}
