//
//  PopoverView.swift
//  WifeOnTheMenuBar
//
//  Created by Artiom Gramatin on 25.07.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct PopoverView: View {
    @State private var image: NSImage? = nil
    var appDelegate: AppDelegate

    var body: some View {
        VStack(spacing: 5) {
            // ✅ Show current image or fallback
            if let nsImage = image {
                Image(nsImage: nsImage)
                    .resizable()
                    .clipped()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 10)
            } else {
                Text("No image selected.")
            }

            // ✅ Change photo button
            Button("Change Photo") {
                selectNewImage()
            }
            .padding(.top, 5)

            // ✅ Exit button
            Button("Exit") {
                NSApp.terminate(nil)
            }
            .padding(.top, 5)
            .foregroundColor(.red)

            // ✅ Settings button
            Button("Settings ⚙️") {
                NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
            }
            .padding(.top, 5)

            Spacer()
        }
        .padding()
        .frame(width: 250, height: 310)
        .onAppear {
            // ✅ Only load once, not on every re-render
            if image == nil {
                image = loadCurrentImage()
            }
        }
    }

    // ✅ Load once from UserDefaults
    private func loadCurrentImage() -> NSImage? {
        if let imageData = UserDefaults.standard.data(forKey: "SavedImageData"),
           let nsImage = NSImage(data: imageData) {
            return nsImage
        }
        return NSImage(named: "wifeIcon") // fallback image
    }

    // ✅ Run PNG saving in background
    private func saveImageToDefaults(_ image: NSImage) {
        // Convert NSImage to PNG Data *before* going async
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }

        DispatchQueue.global(qos: .utility).async {
            // Now only safe 'Data' is captured inside the closure
            UserDefaults.standard.set(pngData, forKey: "SavedImageData")
        }
    }


    func selectNewImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .heif]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Select a new photo"

        if panel.runModal() == .OK, let url = panel.url {
            guard let newImage = NSImage(contentsOf: url) else { return }
            guard let croppedImage = cropToSquare(image: newImage) else { return }

            // Prepare PNG data before async closure
            guard let tiff = croppedImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                return
            }

            // Update UI on main thread
            self.image = croppedImage
            self.appDelegate.setMenuBarImage(croppedImage)

            // Save PNG data asynchronously — pngData is Sendable
            DispatchQueue.global(qos: .utility).async {
                UserDefaults.standard.set(pngData, forKey: "SavedImageData")
            }
        }
    }



    // ✅ Crops any image to square, safe for large images
    func cropToSquare(image: NSImage) -> NSImage? {
        let size = min(image.size.width, image.size.height)
        let x = (image.size.width - size) / 2
        let y = (image.size.height - size) / 2
        let cropRect = NSRect(x: x, y: y, width: size, height: size)

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let croppedCG = cgImage.cropping(to: cropRect) else { return nil }

        return NSImage(cgImage: croppedCG, size: NSSize(width: size, height: size))
    }
}

#Preview {
    PopoverView(appDelegate: AppDelegate())
}
