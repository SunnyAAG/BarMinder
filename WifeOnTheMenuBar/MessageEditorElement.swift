//
//  MessageEditorElement.swift
//  WifeOnTheMenuBar
//
//  Created by Artiom Gramatin on 02.08.2025.
//

import SwiftUI

struct NotificationMessageEditor: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 14))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .frame(height: 110)
            .disableAutocorrection(true)
    }
}

