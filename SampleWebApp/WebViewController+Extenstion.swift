//
//  WebViewController+Extenstion.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 03/04/23.
//

import Foundation
import WebKit

extension WebViewController : WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("\nWebview ---> didStartProvisionalNavigation")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        
        print("\nWebview decidePolicyFor ---> \(String(describing: navigationAction.request.url?.absoluteString))")
        
        if let urlStr = navigationAction.request.url?.absoluteString, urlStr.contains(URLConstants.SourceURL) {
            webView.load(URLRequest(url: URL(string: URLConstants.TransformedURL)!))
            return WKNavigationActionPolicy.cancel
        }
        return WKNavigationActionPolicy.allow
    }
    
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
//                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        guard let url = navigationAction.request.url, url.scheme == "http" || url.scheme == "https" else {
//            decisionHandler(.allow)
//            return
//        }
//
//        guard let resourcePath = url.host else {
//            // Handle missing resource path
//            decisionHandler(.cancel)
//            return
//        }
//
//        guard let url = Bundle.main.url(forResource: resourcePath, withExtension: nil) else {
//            // Handle missing asset
//            decisionHandler(.cancel)
//            return
//        }
//        let finalURL = url.absoluteString + "/index.html"
//        webView.loadFileURL(URL(string: finalURL)!, allowingReadAccessTo: url)
//        decisionHandler(.cancel)
//    }
//
//
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("\nURLAuthenticationChallenge ---> \(String(describing: webView.url?.absoluteString))")
        
        if let urlStr = webView.url?.absoluteString, urlStr.contains(URLConstants.SourceURL) {
            webView.load(URLRequest(url: URL(string: URLConstants.TransformedURL)!))
            return completionHandler(URLSession.AuthChallengeDisposition.useCredential, nil)
        }
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error)
    }
}

//MARK: — Load assets to document folder
extension WebViewController {
    func getDocumentURL() {
        let fileManager = FileManager.default
        guard let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        print("\nFileManager docuent URL --->",documentUrl)
    }
    
    // 2 - Fetch file path
    func uploadFileToFileManager(path: String, type: String) -> String? {
        guard let filePath = Bundle.main.path(forResource: path, ofType: type) else {
            print("\nBundle ---> Fail path fetching failed")
            return nil
        }
        return filePath
    }
    
    // 3 - Upload the file Manager
    func uploadToFileManager(fileManager: FileManager, source: String, destination: URL) {
        do {
            try fileManager.copyItem(at: URL(fileURLWithPath: source), to: destination)
            print("\nFileManager ---> File uploaded successfully")
        }
        catch {
            print("\nFileManager ---> Failed to load the file")
        }
    }
    
    // 1 - Initialize Filemanager
    func moveAssetFilesFromBundleToFileManager() {
        let fileManager = FileManager.default
        let documentDirectory = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        //upload index.html file to Document folder
        var filePathStr = URLConstants.SchemaURL + "/index"
        guard let indexFilePath = uploadFileToFileManager(path: filePathStr, type: "html") else {
            return
        }
        let indexURL = documentDirectory.appendingPathComponent("index.html")
        uploadToFileManager(fileManager: fileManager, source: indexFilePath, destination: indexURL)
        
        //upload style.css file to Document folder
        filePathStr = URLConstants.SchemaURL + "/style"
        guard let filePath = uploadFileToFileManager(path: filePathStr, type: "css") else {
            return
        }
        let destinationURL = documentDirectory.appendingPathComponent("style.css")
        uploadToFileManager(fileManager: fileManager, source: filePath, destination: destinationURL)

        //upload page.js file to Document folder
        filePathStr = URLConstants.SchemaURL + "/page"
        guard let filePath = uploadFileToFileManager(path: filePathStr, type: "js") else {
            return
        }
        let jsDestinationURL = documentDirectory.appendingPathComponent("page.js")
        uploadToFileManager(fileManager: fileManager, source: filePath, destination: jsDestinationURL)
        
        // Upload images to FileManager's document folder
        uploadImagesFromBundleToFileManager()
    }
    
    func uploadImagesFromBundleToFileManager() {
        // save images to document folder
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentDirectory.appendingPathComponent("images")
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating folder: \(error)")
        }
        
        let imageNames = ["localassets/images/img1.jpeg", "localassets/images/img2.jpeg", "localassets/images/img3.jpeg"]
        for imageName in imageNames {
            if let bundleURL = Bundle.main.url(forResource: imageName, withExtension: nil) {
                let excludeSchema = URLConstants.SchemaURL + "/images/"
                let finalImageName = imageName.components(separatedBy: excludeSchema).last ?? ""
                let destinationURL = folderURL.appendingPathComponent(finalImageName)
                do {
                    try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
                    print("\nFileManager ---> Image upload successful \(imageName)")
                } catch {
                    print("\nFileManager ---> Error copying \(imageName): \(error)")
                }
            } else {
                print("\nFileManager ---> \(imageName) not found in bundle")
            }
        }
    }
    
//    
//    func uploadImagesToFileManager(imageNamed: String, imageData: NSData) -> URL? {
//        // save images to document folder
//        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let folderURL = documentsDirectoryURL.appendingPathComponent("images")
//        let fileURL = folderURL.appendingPathComponent(imageNamed)
//        do {
//            try imageData.write(to: fileURL)
//            printContent("\nFileManager ---> Downloaed Image writing successful")
//            return fileURL
//        } catch {
//            print("Error writing image data to file: \(error.localizedDescription)")
//            return nil
//        }
//    }
}
