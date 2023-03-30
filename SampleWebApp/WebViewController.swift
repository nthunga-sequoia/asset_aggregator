//
//  WebViewController.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 21/03/23.
//

import UIKit
import WebKit
import UniformTypeIdentifiers

// schema URL should be alway in lowercase
struct URLConstants {
    static let LoadingURL = "http://nthunga.infinityfreeapp.com"
    static let SourceURL = "http://nthunga.infinityfreeapp.com"
    static let TransformedURL = "localassets://nthunga.infinityfreeapp.com"
    static let SchemaURL = "localassets"
    
//    static let LoadingURL = "https://px.sequoia.com/"
//    static let SourceURL = "https://px.sequoia.com/"
//    static let TransformedURL = "rtw://px.sequoia.com/rtw"
//    static let SchemaURL = "rtw"
}

class WebViewController: UIViewController {
    
    var webview = WKWebView()
    
    override func loadView() {
        super.loadView()
        moveAssetFilesFromBundleToFileManager()
        getDocumentURL()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebview()
        loadWebPage()
    }
    
    func loadWebPage() {
        if let requestURL = URL(string: URLConstants.LoadingURL) {
            let URLRequest = NSMutableURLRequest(url: requestURL)
            URLRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            webview.load(URLRequest as URLRequest)
        }
    }
    
    func setupWebview() {
        let preferences = WKPreferences()
        let config = WKWebViewConfiguration()
        config.preferences = preferences
        config.setURLSchemeHandler(ConfigHandler(), forURLScheme: URLConstants.SchemaURL)
//        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
//        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        webview = WKWebView(frame: .zero, configuration: config)
        webview.navigationDelegate = self
        webview.allowsBackForwardNavigationGestures = true
        webview.frame = self.view.frame
        self.view.addSubview(webview)
    }
}

class ConfigHandler: NSObject, WKURLSchemeHandler {

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        
        guard let url = urlSchemeTask.request.url,
              let fileUrl = fileUrlFromUrlFromDocument(url), // Switch the file source here
              let mimeType = mimeType(ofFileAtUrl: fileUrl),
              let data = try? Data(contentsOf: fileUrl) else { return }

        let response = HTTPURLResponse(url: url,
                                       mimeType: mimeType,
                                       expectedContentLength: data.count, textEncodingName: nil)
        
        print("\nURL Schema Task response ---> ",response)

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }
    
    // MARK: - Private

    private func fileUrlFromUrlFromBundle(_ url: URL) -> URL? {
        print("\nFile URL from URL --->", url)
        var folderName = URLConstants.SchemaURL
        
        // At first we need to pass HTML page, then each assets in the HTML file will be called for respective assets.
        if url.absoluteString == URLConstants.TransformedURL {
            folderName += "/" + "index.html"
        }
        else {
            folderName += "/" + (url.absoluteString.components(separatedBy: ".com/").last ?? "")
        }
        print("Asset filepath --->",folderName)
        
        let url = Bundle.main.url(forResource: folderName,
                                  withExtension: "",
                                  subdirectory: "")
        return url ?? nil
    }
    
    private func fileUrlFromUrlFromDocument(_ url: URL) -> URL? {
        print("\nFile URL from URL --->", url)
        
        var folderName = URLConstants.SchemaURL
        
        // At first we need to pass HTML page, then each assets in the HTML file will be called for respective assets.
        if url.absoluteString == URLConstants.TransformedURL {
            folderName += "/" + "index.html"
        }
        else {
            folderName += "/" + (url.absoluteString.components(separatedBy: ".com/").last ?? "")
        }
        print("\nAsset filepath --->",folderName)
        
        var queryFileName = ""
        if folderName.contains("/images") {
            queryFileName = folderName.components(separatedBy: "localassets/images/").last ?? ""
        }
        else {
            queryFileName = folderName.components(separatedBy: "localassets/").last ?? ""
        }
        let url = fetchFileURLFromDocument(url, fileName: queryFileName) ?? nil
        return url
    }
    
    private func mimeType(ofFileAtUrl url: URL) -> String? {
        //print("\nMIME type for URL --->", url)
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return nil
        }
        return type.preferredMIMEType
    }
    
    private func fetchFileURLFromDocument(_ url: URL, fileName: String) -> URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let documentFiles = try? FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
        if let files = documentFiles {
            for fileUrl in files {
                // Do something with the HTML file, such as loading it into a WebView
                
                if let mimeType = mimeType(ofFileAtUrl: url), mimeType == "image/jpeg" {
                    if fileUrl.lastPathComponent != "images" {
                        continue
                    }
                    let folderURL = documentDirectory.appendingPathComponent("images")
                    do {
                        let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
                        let url = fileURLs.filter{$0.lastPathComponent == fileName}.first
                        return url
                    } catch {
                        print("Error fetching files: \(error)")
                    }
                }
                else {
                    // check the filename & return the right
                    if fileName == fileUrl.lastPathComponent {
                        return fileUrl
                    }
                }
            }
        } else {
            print("\nFileManager ---> No Files found")
        }
        
        return nil
    }
}

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

//MARK: — Loading assets to document folder
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
    

}
