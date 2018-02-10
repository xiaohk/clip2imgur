//
//  CommandLineInterface.swift
//  clip2imgur
//
//  Created by Jay Wong on 2/7/18.
//

import Foundation
import Cocoa
import Rainbow

// A class managing the commmand line interface for this project
public class CommandLineInterface{
    public let argc: Int32
    public let argv: [String]
    
    public init(){
        self.argc = CommandLine.argc
        self.argv = CommandLine.arguments
    }
    
    // The main logic is implemented here
    public func run(){
        let cliImage = ClipboardImage()
        let api = ImgurAPI()
        let url = api.postImage(from: cliImage.getClipboardImageBase64())
        copyToClipboard(from: url)
        print("The image url is coppied to your clipboard.".bold)
    }
}

// Print the error message to stderr
public func printError(_ errorMessage: String){
    fputs("Error: \(errorMessage)\n".red.bold, stderr)
}

// Copy the string to user's clipboard
private func copyToClipboard(from str: String){
    let clipboard = NSPasteboard.general
    clipboard.declareTypes([.string], owner: nil)
    clipboard.setString(str, forType: .string)
}

