//
//  SchemaHandler.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 22/03/23.
//

import Foundation
import WebKit

class SchemaHandler: NSObject, WKURLSchemeHandler {
    
    override init() {
        print("SchemaHandler Initialization")
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        //Check that the url path is of interest for you, etc...
        
        print("----------->>>> Start URL schema hanlder \n\n")
        
        let url = urlSchemeTask.request.url!
        var filepath = url.path
        if filepath == "" || filepath == "/" {
            filepath = "/index.html"
        }
        let path = Bundle.main.path(forResource: "public", ofType: "")!.appending(filepath)
        if url.host == "reactjs.org", FileManager.default.fileExists(atPath: path) {
            let localData = NSData(contentsOfFile: path)!
            
            //Create a NSURLResponse with the correct mimetype.
            let urlResponse = URLResponse(url: url, mimeType: "image/jpeg",
                                          expectedContentLength: -1, textEncodingName: nil)
            //IMPORTANT: Forward your response to the task.
            urlSchemeTask.didReceive(urlResponse)
            urlSchemeTask.didReceive(localData as Data)

            //IMPORTANT: Tell the task that you're done.
            urlSchemeTask.didFinish()
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

    }

}
