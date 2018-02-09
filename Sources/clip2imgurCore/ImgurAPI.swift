//
//  ImgurAPI.swift
//  clip2imgur
//
//  Created by Jay Wong on 2/7/18.
//

import Foundation
import Cocoa

public class ImgurAPI{
    
    private let authoURL = URL(string: "https://api.imgur.com/oauth2/authorize?client_id=95b05e2e3ac5624&response_type=token&state=copy-url")
    private let uploadURL = URL(string: "https://api.imgur.com/3/image")
    private let response = "https://imgur.com/?state=copy-url#access_token=bb8f26b8a688671f436b91e666b7553a1b36ec4c&expires_in=315360000&token_type=bearer&refresh_token=6f79169408cd0206cd8ff17ba7f73472a59f03a3&account_username=xiaohk&account_id=33452659"
    private let configPath: String
    private var configDict: [String: String]
    private let userKeys =  ["access_token", "refresh_token", "account_username",
                             "account_id", "expires_in"]
    private let fm = FileManager()
    
    init(){
        self.configPath = Bundle.main.bundleURL.appendingPathComponent("config.plist").path
        if (self.fm.fileExists(atPath: self.configPath)){
            // If file exist, we just read it
            self.configDict = NSDictionary(contentsOfFile: self.configPath) as!
                [String:String]
        } else {
            // Init the config file if it does not exist
            self.configDict = ["client_id": "95b05e2e3ac5624"]
            let plistData = try! PropertyListSerialization.data(
                fromPropertyList: self.configDict,
                format: .xml, options: 0)
            self.fm.createFile(atPath: self.configPath, contents: plistData)
        }
    }
    
    // Load the config dictionary from the plist
    private func loadConfigDict(){
        self.configDict = NSDictionary(contentsOfFile: self.configPath) as!
            [String:String]
    }
    
    // Write the config dictionary to the plist
    private func writeConfigDict(){
        let plistData = try! PropertyListSerialization.data(
            fromPropertyList: self.configDict,
            format: .xml, options: 0)
        self.fm.createFile(atPath: self.configPath, contents: plistData)
    }
    
    // Specify if the current user has access token to imgur api
    public func isAuthorized() -> Bool{
        for key in self.userKeys{
            if (self.configDict[key] == nil){
                return false
            }
        }
        return true
    }
    
    // Remove the user authorization
    public func deleteAuthorization(){
        for key in self.userKeys{
            if (self.configDict[key] != nil){
                self.configDict[key] = nil
            }
        }
    }
    
    // Authorize a user
    public func authorizeUser(){
        // Prompt the user how to authorize
        print("\nTo use this app, we need your authorization. Please follow the instruction" +
            " to authorize:\n")
        print("(1) You will be directed to Imgur authorization page in your default browser.")
        print("(2) Authorize this app.")
        print("(3) After authorization, you will be redirected to the Imgur main page, " +
            "please copy the new URL from your browser.\n")
        print("Press [return ⏎] key to start step (1) \r\n", terminator: "")
        var response = readLine()
        
        // Open the authorization page in default browser
        let defaultBrowerURL = NSWorkspace.shared.urlForApplication(toOpen: authoURL!)
        NSWorkspace.shared.open(authoURL!)
        
        // Launch the default browser and make sure it is at the front
        do {
            try NSWorkspace.shared.launchApplication(at: defaultBrowerURL!,
                                                     options: .andHideOthers,
                                                     configuration: [:])
        } catch {
            printError("Failed to launch the browser.")
        }
        
        // Clear the terminal screen
        let task = Process()
        task.launchPath = "/usr/bin/clear"
        task.launch()
        task.waitUntilExit()
        
        while(true){
            print("The new URL looks like https://imgur.com/?state=copy-url#access_token=...\n")
            print("(4) Paste the full URL here > ", terminator: "")
            response = readLine()
            if (response != nil && response!.hasPrefix("https://imgur.com?")){
                if (parseURL(response!)){
                    break
                }
            }
            print("\nMake sure you copy the full URL\n")
            // TODO
            break
        }
    }
    
    // Parse the response URL into the dictionary
    public func parseURL(_ response: String) -> Bool{
        // Seperate the response
        let poundIndex = response.index(response.index(of: "#")!, offsetBy: 1)
        let pairs = response[poundIndex..<response.endIndex].components(separatedBy: "&")
        
        // Parse the key values into the dictionary
        for pair in pairs{
            let item = pair.components(separatedBy: "=")
            self.configDict[item[0]] = item[1]
        }
        
        // Dump the configDict to plist
        if (self.isAuthorized()){
            self.writeConfigDict()
            return true
        }
        return false
    }
    
    // Post image to Imgur, image should be a base64 encoded string
    public func postImage(from image: String){
        if (!self.isAuthorized()){
            // A loop to get user input
            print("In order to upload image to your colloection, you need to authorize this app." +
                " Do you want to authorize now?")
            var response: String?
            while(true) {
                print("Enter 'yes' to start authorization, enter 'no' to post anonymously")
                print("> ", terminator: "")
                response = readLine()
                let legalResponses = ["yes", "no", "\'yes\'", "\'no\'", "y", "n"]
                if (response != nil && legalResponses.contains(response!)){
                    break
                }
            }
            
            // Start authorization
            if (response! == "yes" || response! == "\'yes\'" || response! == "y"){
                self.authorizeUser()
            } else {
                self.postImageAnonymously(from: image)
            }
        }
    }
    
    private func postImageAnonymously(from image: String){
        // Anonimous upload
        let sema = DispatchSemaphore(value: 0)
        print("what?!")
        var request = URLRequest(url: self.uploadURL!)
        request.httpMethod = "POST"
        request.setValue("Client-ID " + self.configDict["client_id"]!,
            forHTTPHeaderField: "Authorization")
        let data = "image=\(image)&type=base64".data(using: .utf8, allowLossyConversion: false)
        request.httpBody = data
        
        // Upload task
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            print("Responeded!!")
            if let error = error {
                print ("error: \(error)")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response!)")
            }
            sema.signal()
        }
        task.resume()
        // Block the main thread, wait for the URLSession
        sema.wait()
    }
    
    /*
    private func postImageAnony(from image: String){
        let header: HTTPHeaders = ["Authorization": "Client-ID \(self.configDict["client_id"]!)"]
        
        Alamofire.request(self.uploadURL!, method: .post,
                          parameters: ["image": image, "type": "base64"],
                          encoding: JSONEncoding.default,
                          headers: header).responseJSON {
            response in
            switch response.result {
            case .success:
                print(response)
                
                break
            case .failure(let error):
                
                print(error)
            }
        }
    }
 */
}


