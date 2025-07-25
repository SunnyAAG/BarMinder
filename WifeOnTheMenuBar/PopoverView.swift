//
//  PopoverView.swift
//  WifeOnTheMenuBar
//
//  Created by Artiom Gramatin on 25.07.2025.
//

import SwiftUI

struct PopoverView: View {
    @State private var image: NSImage? = nil
    var appDelegate: AppDelegate

    var body: some View {
        VStack(spacing: 5) {
            if let nsImage = image ?? loadCurrentImage() {
                Image(nsImage: nsImage)
                    .resizable()
                    .clipped()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top,10)
            } else {
                Text("No image selected.")
            }

            Button("Change Photo") {
                selectNewImage()
            }
            .padding(.top, 5)
            
            Button("Exit") {
                NSApp.terminate(nil)
            }
            .padding(.top, 5)
            .foregroundColor(.red)
            
            Button("Settings ⚙️") {
                NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
            }
            .padding(.top, 5)

            Spacer()
        }
        .padding()
        .frame(width: 250, height: 310)
    }

    func loadCurrentImage() -> NSImage? {
        if let imageData = UserDefaults.standard.data(forKey: "SavedImageData"),
           let nsImage = NSImage(data: imageData) {
            return nsImage
        }
        return NSImage(named: "wifeIcon") // fallback image
    }


    func selectNewImage() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png", "jpg", "jpeg"]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Select a new photo"

        if panel.runModal() == .OK, let url = panel.url {
            if let newImage = NSImage(contentsOf: url) {
                
                // ✅ Auto-crop any image to square
                if let croppedImage = cropToSquare(image: newImage) {
                    image = croppedImage
                    appDelegate.setMenuBarImage(croppedImage)

                    // ✅ Save cropped image data
                    if let tiff = croppedImage.tiffRepresentation,
                       let bitmap = NSBitmapImageRep(data: tiff),
                       let pngData = bitmap.representation(using: .png, properties: [:]) {
                        UserDefaults.standard.set(pngData, forKey: "SavedImageData")
                    }
                }
            }
        }
    }

    
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
