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
    private let api = ImgurAPI()
    
    public init(){
        self.argc = CommandLine.argc
        self.argv = CommandLine.arguments
    }
    
    // The main logic is implemented here
    public func run(){
        let cliImage = ClipboardImage()
        let url = self.postImage(from: cliImage.getClipboardImageBase64())
        copyToClipboard(from: url)
        print("The image url is coppied to your clipboard.".bold)
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
                print("Enter 'yes' to start authorization, enter 'no' to post anonymously")
                print("> ".bold.blink, terminator: "")
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
    fputs("Error: \(errorMessage)\n".red.bold, stderr)
}

// Copy the string to user's clipboard
private func copyToClipboard(from str: String){
    let clipboard = NSPasteboard.general
    clipboard.declareTypes([.string], owner: nil)
    clipboard.setString(str, forType: .string)
}

