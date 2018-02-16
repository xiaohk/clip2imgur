//
//  CommandLineInterface.swift
//  clip2imgur
//
//  Created by Jay Wong on 2/7/18.
//

import Foundation
import Cocoa
import Rainbow
import Utility
import Basic

private enum copyFormat{
    case markdown
    case html
    case plain
}

// A class managing the commmand line interface for this project
public class CommandLineInterface{
    public let argc = CommandLine.argc
    public let argv = CommandLine.arguments
    private let api = ImgurAPI()
    
    private let parser: ArgumentParser
    private let useMDFormat: OptionArgument<Bool>
    private let useHTMLFormat: OptionArgument<Bool>
    private let doNotCopy: OptionArgument<Bool>
    
    public init(){
        // Init the argument parser and register flags
        let overview = "clip2imgur is a simple CLI that uploads your image in clipboard " +
            "to Imgur."
        self.parser = ArgumentParser(usage: "<flags>",
                                     overview: overview)
        self.useMDFormat = self.parser.add(
            option: "--markdown",
            shortName: "-m",
            kind: Bool.self,
            usage: "Copy the image url in Markdown format"
        )
        
        self.useHTMLFormat = self.parser.add(
            option: "--html",
            shortName: "-t",
            kind: Bool.self,
            usage: "Copy the image url in HTML format"
        )
        
        self.doNotCopy  = self.parser.add(
            option: "--nocopy",
            shortName: "-n",
            kind: Bool.self,
            usage: "Do not copy the image url after submitting"
        )
    }
    
    // The app main logic is implemented here
    public func run(){
        do {
            // Parse the arguments
            let parsedArguments = try parser.parse(Array(self.argv.dropFirst()))
            
            // Post the user's image
            let cliImage = ClipboardImage()
            let url = self.postImage(from: cliImage.getClipboardImageBase64())
            
            // Decide how to copy the returned url
            if (parsedArguments.get(self.doNotCopy) == true){
                return
            } else if (parsedArguments.get(self.useHTMLFormat) == true){
                copyToClipboard(from: url, using: .html)
            } else if (parsedArguments.get(self.useMDFormat) == true){
                copyToClipboard(from: url, using: .markdown)
            } else {
                copyToClipboard(from: url, using: .plain)
            }
        } catch let error {
            printError(error.localizedDescription)
            self.parser.printUsage(on: stdoutStream)
        }
        print("The image url is coppied to your clipboard.".blue.bold)
    }
    
    // Post image to Imgur, image should be a base64 encoded string
    private func postImage(from image: String) -> String{
        if (!self.api.isAuthorized()){
            // A loop to get user input
            print("In order to upload image to your colloection, you need to authorize this app. " +
                "Otherwise, you will be posting your image anonymously. " +
                "Do you want to authorize this app now?\n")
            var response: String?
            while(true) {
                print("[Enter 'yes' to start authorization, enter 'no' to post anonymously]")
                print("> ".bold, terminator: "")
                response = readLine()
                let legalResponses = ["yes", "no", "\'yes\'", "\'no\'", "y", "n"]
                if (response != nil && legalResponses.contains(response!)){
                    break
                }
            }
            
            // Start authorization
            if (response! == "yes" || response! == "\'yes\'" || response! == "y"){
                self.api.authorizeUser()
                return self.api.postImage(from: image, anony: false)
            } else {
                return self.api.postImage(from: image, anony: true)
            }
        } else {
            // The user has already been authorized
            // Check if the user's access is expired
            if (self.api.isExpire()){
                if ((self.api as Imgurable).refreshToken != nil){
                    // refreshToken is implemented (binary file)
                    (self.api as Imgurable).refreshToken!()
                } else {
                    // Did not implement refreshToken (compiled from source by user)
                    self.api.authorizeUser()
                }
            }
            return self.api.postImage(from: image, anony: false)
        }
    }
}

// Print the error message to stderr
public func printError(_ errorMessage: String){
    fputs("Error: \(errorMessage)\n".red, stderr)
}

// Copy the url to user's clipboard
private func copyToClipboard(from url: String, using format: copyFormat){
    let clipboard = NSPasteboard.general
    clipboard.declareTypes([.string], owner: nil)
    var formatedURL: String
    // Copy the url in the specified format
    switch format {
    case .html:
        formatedURL = "<img src=\"\(url)\">"
    case .markdown:
        formatedURL = "![](\(url))"
    case .plain:
        formatedURL = url
    }
    clipboard.setString(formatedURL, forType: .string)
}
