//
//  ClipboardImage.swift
//  clip2imgur
//
//  Created by Jay Wong on 2/8/18.
//

import Foundation
import AppKit

public class ClipboardImage{
    private let images = pasteClipboardImage()!
    
    public func getClipboardImageBase64() -> String{
        return self.images[0].getBase64String()
    }
    
    public func saveClipboardImage(to path:String) -> Bool{
        let saveURL = URL(fileURLWithPath: path)
        return self.images[0].saveAsPNG(url: saveURL)
    }
}

// Paste the image from clipboard to the cache directory
public func pasteClipboardImage() -> [NSImage]?{
    let board = NSPasteboard.general;
    
    guard board.canReadObject(forClasses: [NSImage.self], options: nil) else {
        printError("There is no image file detected in your clipboard")
        exit(-1)
    }
    
    guard let images = board.readObjects(forClasses: [NSImage.self], options: nil) else {
        printError("Failed to paste image from the clipboard")
        exit(-1)
    }
    return images as? [NSImage]
}

// Convert NSImage to png file, and save to url path
extension NSImage{
    @discardableResult
    func saveAsPNG(url: URL) -> Bool {
        guard let tiffData = self.tiffRepresentation else {
            printError("Failed to get tiffRepresentation")
            exit(-1)
        }
        let imageRep = NSBitmapImageRep(data: tiffData)
        guard let imageData = imageRep?.representation(using: .png, properties: [:]) else {
            printError("Failed to get PNG representation")
            exit(-1)
        }
        do {
            try imageData.write(to: url)
            return true
        } catch let error as NSError{
            print("Failed to write to rwrite the PNG file, with error:" +
                    "\(error.localizedDescription)")
            exit(-1)
        }
    }
}

// Convert NSImage to base64 string
extension NSImage{
    // Convert NSImage self to a string of base64 encoding
    func getBase64String() -> String{
        guard let tiffData = self.tiffRepresentation else {
            printError("Failed to get tiffRepresentation")
            exit(-1)
        }
        guard let bitmap: NSBitmapImageRep = NSBitmapImageRep(data: tiffData) else {
            printError("Failed to get Bitmap representation from tiffRepresentation")
            exit(-1)
        }
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            printError("Failed to make image data with PNG type")
            exit(-1)
        }
        let bitmap_base64 = data.base64EncodedString()
        return bitmap_base64
    }
}
