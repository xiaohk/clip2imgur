//
//  Cli.swift
//  clip2imgur
//
//  Created by Jay Wong on 2/7/18.
//

import Foundation
import Cocoa

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
        api.postImage(from: cliImage.getClipboardImageBase64())
        // api.authorizeUser()
        //print(api.parseURL("https://imgur.com/?state=copy-url#access_token=bb8f26b8a688671f436b91e666b7553a1b36ec4c&expires_in=315360000&token_type=bearer&refresh_token=6f79169408cd0206cd8ff17ba7f73472a59f03a3&account_username=xiaohk&account_id=33452659"))
    }
}

// Print the error message to stderr
public func printError(_ errorMessage: String){
    fputs("Error: \(errorMessage)\n", stderr)
}
/*
public func run(){
    if let url = URL(string: "https://www.google.com"), NSWorkspace.shared.open(url) {
        print("default browser was successfully opened")
    }
}
*/
