//
//  ImgurAPI.swift
//  clip2imgur
//
//  Created by Jay Wong on 2/7/18.
//

import Foundation
import Cocoa
import Rainbow

// Define a protocol to hide refreshToken implementation
@objc protocol Imgurable{
    @objc func postImage(from image: String, anony: Bool) -> String
    @objc func authorizeUser()
    // Use optional to build with/without refreshToken function
    @objc optional func refreshToken()
}

public class ImgurAPI: Imgurable{
    
    private let authoURL = URL(string: "https://api.imgur.com/oauth2/authorize?client_id=95b05e2e3ac5624&response_type=token&state=copy-url")
    private let uploadURL = URL(string: "https://api.imgur.com/3/image")
    private let configPath: String
    internal var configDict: [String: String]
    private let userKeys =  ["access_token", "refresh_token", "account_username",
                             "account_id", "expires_in", "expire_date"]
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
    internal func writeConfigDict(){
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
        print(
        """
         (1) You will be directed to Imgur authorization page in your default browser.
         (2) Authorize this app.
         (3) After authorization, you will be redirected to the Imgur main page, please copy the new URL from your browser.\n
         """.blue.bold
        )

        print("Press [return ⏎ ] key to start step (1) \r\n", terminator: "")
        var response = readLine()
        
        // Open the authorization page in default browser
        let defaultBrowerURL = NSWorkspace.shared.urlForApplication(toOpen: authoURL!)
        NSWorkspace.shared.open(authoURL!)
        
        // Launch the default browser and make sure it is at the front
        do {
            try NSWorkspace.shared.launchApplication(at: defaultBrowerURL!,
                                                     options: .andHideOthers,
                                                     configuration: [:])
        } catch let error as NSError{
            printError("Failed to launch the browser with error: \(error.localizedDescription)")
        }
        
        // Clear the terminal screen
        let task = Process()
        task.launchPath = "/usr/bin/clear"
        task.launch()
        task.waitUntilExit()
        
        while(true){
            print("The new URL looks like " +
                    "https://imgur.com/?state=copy-url#access_token=...\n".underline)
            print("(4) Paste the full URL below: ".blue.bold)
            print("> ".bold, terminator: "")
            response = readLine()
            
            if (response != nil && response!.hasPrefix("https://imgur.com")){
                if (parseURL(response!)){
                    break
                }
            }
            printError("\nMake sure you copy the full URL\n")
        }
    }
    
    // Parse the response URL into a dictionary
    private func parseURL(_ response: String) -> Bool{
        // Seperate the response
        let poundIndex = response.index(response.index(of: "#")!, offsetBy: 1)
        let pairs = response[poundIndex..<response.endIndex].components(separatedBy: "&")
        
        // Parse the key values into the dictionary
        for pair in pairs{
            let item = pair.components(separatedBy: "=")
            self.configDict[item[0]] = item[1]
            // Compute the expire date from expires_in entry
            if (item[0] == "expires_in"){
                self.storeExpireDateTime(from: item[1])
            }
        }
        
        // Dump the configDict to the plist
        if (self.isAuthorized()){
            self.writeConfigDict()
            return true
        }
        return false
    }
    
    // Upload the base64 image to imgur
    // Support two modes: authorized mode and anonymious mode, depending on the autho arg
    @discardableResult
    public func postImage(from image: String, anony: Bool = false) -> String{
        // Switch mode
        let authoValue = anony ? "Client-ID " + self.configDict["client_id"]! :
                                 "Bearer " + self.configDict["access_token"]!
        // Parameters for header and body
        let headers = [
            "content-type": "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW",
            "Authorization": authoValue,
            "Cache-Control": "no-cache"
        ]
        let parameters = [
            ["name": "image", "value": image],
            ["name": "type", "value": "base64"]
        ]
        
        // Build Postman format multipart body
        let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
        var body = ""
        let error: NSError? = nil
        for param in parameters {
            let paramName = param["name"]!
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"\(paramName)\""
            if let filename = param["fileName"] {
                let contentType = param["content-type"]!
                let fileContent = try! String(contentsOfFile: filename, encoding: String.Encoding.utf8)
                if (error != nil) {
                    printError(error!.localizedDescription)
                }
                body += "; filename=\"\(filename)\"\r\n"
                body += "Content-Type: \(contentType)\r\n\r\n"
                body += fileContent
            } else if let paramValue = param["value"] {
                body += "\r\n\r\n\(paramValue)"
            }
        }
        
        // Build request using header and body
        let request = NSMutableURLRequest(url: self.uploadURL!,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body.data(using: .utf8, allowLossyConversion: false)
        
        // Semaphore to wait for the dispatch
        let sema = DispatchSemaphore(value: 0)
        var link: String?
        
        let dataTask = URLSession.shared.dataTask(
            with: request as URLRequest,
            completionHandler: { (data, response, error) -> Void in
                if (error != nil) {
                    printError(error!.localizedDescription)
                } else {
                    let httpResponse = response as? HTTPURLResponse
                    if (httpResponse?.statusCode != 200){
                        printError("Failed to upload image with code" +
                            "\(String(describing: httpResponse?.statusCode))")
                        exit(-1)
                    }
                    do {
                        // Parse the response as json and fetch the interesting info
                        let json = try JSONSerialization.jsonObject(with: data!,
                                options: .allowFragments) as! [String:Any]
                        let json_data = json["data"] as! [String: Any]
                        
                        link = json_data["link"] as? String
                        if (link == nil){
                            printError("Failed to fetch the link")
                            exit(-1)
                        }
                    } catch let error as NSError {
                        printError(error.localizedDescription)
                        exit(-1)
                    }
                }
                sema.signal()
            }
        )
        // Start the task and wait for it to complete
        dataTask.resume()
        print("Uploading...")
        sema.wait()
        print("\n🎉 Successfully uploaded your screenshot to Imgur at \(link!.underline)\n")
        return link!
    }
    
    // Store the access_token expire time to the config dictionary
    internal func storeExpireDateTime(from expire: String){
        // Give 2 minutes offset to offset the reandom compile time offset
        let expireOffset = 120
        guard let expireInterval: TimeInterval = Double(expire) else{
            print("Failed to convert expire time to TimeInterval")
            exit(-1)
        }
        let expireDate = Date().timeIntervalSinceReferenceDate +
            expireInterval - Double(expireOffset)
        self.configDict["expire_date"] = String(expireDate)
    }
    
    // Check whether the stored access token is expired
    internal func isExpire() -> Bool{
        if (!self.isAuthorized()){
            printError("Attempted to access expire date when the user is not authorized")
            exit(-1)
        }
        
        let currentDateTime = Date()
        let expireDateTime = Date(timeIntervalSinceReferenceDate:
            Double(self.configDict["expire_date"]!)!)
        return currentDateTime > expireDateTime
    }
}
