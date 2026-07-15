#!/usr/bin/env swift
import SwiftUI
import AppKit

// Usage: swift make_squircle_icon.swift <input.png> <output.png> [size]
// Clips a square source image to a macOS-style continuous-corner squircle
// (~22.37% corner radius, matching Apple's Big Sur+ app icon shape).

let size: CGFloat = CommandLine.arguments.count > 3 ? (CGFloat(Double(CommandLine.arguments[3]) ?? 1024)) : 1024
let cornerRadius: CGFloat = size * 0.2237

guard CommandLine.arguments.count > 2 else {
    print("Usage: swift make_squircle_icon.swift <input.png> <output.png> [size]")
    exit(1)
}

let sourcePath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let nsImage = NSImage(contentsOfFile: sourcePath) else {
    print("Failed to load \(sourcePath)")
    exit(1)
}

struct IconView: View {
    let image: NSImage
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

MainActor.assumeIsolated {
    let view = IconView(image: nsImage, size: size, cornerRadius: cornerRadius)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0

    guard let cgImage = renderer.cgImage else {
        print("Failed to render")
        exit(1)
    }

    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        exit(1)
    }

    try! pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Saved squircle icon to \(outputPath)")
}
