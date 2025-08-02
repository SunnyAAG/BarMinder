//
//  PopoverView.swift
//  WifeOnTheMenuBar
//
//  Created by Artiom Gramatin on 25.07.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct PopoverView: View {
    @State private var image: NSImage?
    @AppStorage("popoverTitle") private var popoverTitle = "Your MenuBar Photo"
    var appDelegate: AppDelegate
    var body: some View {
        VStack(spacing: 12) {
            Text(popoverTitle.isEmpty ? "Your MenuBar Photo" : popoverTitle)
                .font(.headline)
                .padding(.top, 20)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .shadow(radius: 2)
                
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text("Drop an image here")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
            
            VStack(spacing: 8) {
                Button {
                    selectNewImage()
                } label: {
                    Label("Change Photo", systemImage: "photo.on.rectangle")
                }

                Button {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("Exit", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }

            }
            .padding(.top, 4)
            
            Spacer()
        }
        .padding()
        .frame(width: 250, height: 350)
        .onAppear(perform: loadSavedImage)
    }
    
    private func loadSavedImage() {
        guard image == nil else { return }
        if let data = UserDefaults.standard.data(forKey: "SavedImageData"),
           let savedImage = NSImage(data: data) {
            image = savedImage
        } else {
            image = NSImage(named: "wifeIcon")
        }
    }
    
    private func saveImage(_ image: NSImage) {
        guard
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else { return }
        
        DispatchQueue.global(qos: .utility).async {
            UserDefaults.standard.set(pngData, forKey: "SavedImageData")
        }
    }
    
    private func selectNewImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .heif]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Select a new photo"
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadImage(from: url)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if
                let data = item as? Data,
                let url = URL(dataRepresentation: data, relativeTo: nil)
            {
                DispatchQueue.main.async {
                    loadImage(from: url)
                }
            }
        }
        return true
    }
    
    private func loadImage(from url: URL) {
        guard
            let newImage = NSImage(contentsOf: url),
            let cropped = cropToSquare(newImage)
        else { return }
        
        image = cropped
        appDelegate.setMenuBarImage(cropped)
        saveImage(cropped)
    }
    
    private func cropToSquare(_ image: NSImage) -> NSImage? {
        let size = min(image.size.width, image.size.height)
        let rect = NSRect(
            x: (image.size.width - size) / 2,
            y: (image.size.height - size) / 2,
            width: size,
            height: size
        )
        
        guard
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
            let croppedCG = cgImage.cropping(to: rect)
        else { return nil }
        
        return NSImage(cgImage: croppedCG, size: NSSize(width: size, height: size))
    }
}

#Preview {
    PopoverView(appDelegate: AppDelegate())
}
