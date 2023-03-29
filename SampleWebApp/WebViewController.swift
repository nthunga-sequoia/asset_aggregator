//
//  WebViewController.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 21/03/23.
//

import UIKit
import WebKit
import UniformTypeIdentifiers

struct URLConstants {
    static let loadingURL = "http://nthunga.infinityfreeapp.com"
    static let updatedSchemaURL = "localassets://nthunga.infinityfreeapp.com"
    static let schemaURL = "localassets"
}

class WebViewController: UIViewController {

    var initialURL = "http://nthunga.infinityfreeapp.com"
    var targetedURL = "http://nthunga.infinityfreeapp.com"
    var schemaURL = "localassets"
    var updatedSchemaURL = "localassets://nthunga.infinityfreeapp.com"
    
//    var initialURL = "https://px.sequoia.com/"
//    var targetedURL = "https://px.sequoia.com/rtw"
//    var schemaURL = "rtw"
//    var updatedSchemaURL = "rtw://nthunga.infinityfreeapp.com/rtw"
    
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
        if let requestURL = URL(string: initialURL) {
            let URLRequest = NSMutableURLRequest(url: requestURL)
            URLRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            webview.load(URLRequest as URLRequest)
        }
    }
    
    func setupWebview() {
        let preferences = WKPreferences()
        let config = WKWebViewConfiguration()
        config.preferences = preferences
        config.setURLSchemeHandler(ConfigHandler(), forURLScheme: schemaURL)
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
              let fileUrl = fileUrlFromUrl(url),
              let mimeType = mimeType(ofFileAtUrl: fileUrl),
              let data = try? Data(contentsOf: fileUrl) else { return }

        let response = HTTPURLResponse(url: url,
                                       mimeType: mimeType,
                                       expectedContentLength: data.count, textEncodingName: nil)

        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }
    
    // MARK: - Private

    private func fileUrlFromUrl(_ url: URL) -> URL? {
        print("\n\n\n File URL from URL ", url)
        
        var folderName = URLConstants.schemaURL
        if url.absoluteString == URLConstants.updatedSchemaURL {
            folderName += "/" + "index.html"
        }
        else {
            folderName += "/" + (url.absoluteString.components(separatedBy: ".com/").last ?? "")
        }
        print("Foldername ",folderName)
        
//        let queryString = url.absoluteString.components(separatedBy: ":").first
        let url = Bundle.main.url(forResource: folderName,
                                  withExtension: "",
                                  subdirectory: "")
        return url ?? nil
    }
    
    private func mimeType(ofFileAtUrl url: URL) -> String? {
        print("MIME type for URL", url)
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return nil
        }
        return type.preferredMIMEType
    }
}

extension WebViewController : WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("webview > didStartProvisionalNavigation")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        print("\n Webview decidePolicyFor ->> \(String(describing: navigationAction.request.url?.absoluteString))")
        
        if let urlStr = navigationAction.request.url?.absoluteString, urlStr.contains(targetedURL) {
            webView.load(URLRequest(url: URL(string: updatedSchemaURL)!))
            return WKNavigationActionPolicy.cancel
        }
        return WKNavigationActionPolicy.allow
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("URLAuthenticationChallenge ->> \(String(describing: webView.url?.absoluteString))")
        
        if let urlStr = webView.url?.absoluteString, urlStr.contains(targetedURL) {
            webView.load(URLRequest(url: URL(string: updatedSchemaURL)!))
            return completionHandler(URLSession.AuthChallengeDisposition.useCredential, nil)
        }
        completionHandler(URLSession.AuthChallengeDisposition.useCredential, nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error)
    }
}



//if let jsData = try? Data(contentsOf: jsFileURL),
//   let cssData = try? Data(contentsOf: cssFileURL) {
//     let userContentController = WKUserContentController()
//     let jsSource = WKScriptSource(source: String(data: jsData, encoding: .utf8)!, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
//     let cssSource = WKUserScript(source: String(data: cssData, encoding: .utf8)!, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
//     userContentController.addUserScript(jsSource)
//     userContentController.addUserScript(cssSource)
//     webView.configuration.userContentController = userContentController
//}


extension WebViewController {
    func getDocumentURL() {
        let fileManager = FileManager.default
        guard let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        print(documentUrl)
    }
    
    // 2 - Fetch file path
    func uploadFileToFileManager(path: String, type: String) -> String? {
        guard let filePath = Bundle.main.path(forResource: path, ofType: type) else {
            print("Fail path fetching failed")
            return nil
        }
        return filePath
    }
    
    // 3 - Upload the file Manager
    func uploadToFileManager(fileManager: FileManager, source: String, destination: URL) {
        do {
            try fileManager.copyItem(at: URL(fileURLWithPath: source), to: destination)
            print("File uploaded successfully")
        }
        catch {
            print("Failed to load the file")
        }
    }
    
    // 1 - Initialize Filemanager
    func moveAssetFilesFromBundleToFileManager() {
        let fileManager = FileManager.default
        let documentDirectory = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        //upload index.html file to Document folder
        guard let indexFilePath = uploadFileToFileManager(path: "LocalAssets/index", type: "html") else {
            return
        }
        let indexURL = documentDirectory.appendingPathComponent("index.html")
        uploadToFileManager(fileManager: fileManager, source: indexFilePath, destination: indexURL)
        
        //upload style.css file to Document folder
        guard let filePath = uploadFileToFileManager(path: "LocalAssets/style", type: "css") else {
            return
        }
        let destinationURL = documentDirectory.appendingPathComponent("style.css")
        uploadToFileManager(fileManager: fileManager, source: filePath, destination: destinationURL)

        //upload page.js file to Document folder
        guard let filePath = uploadFileToFileManager(path: "LocalAssets/page", type: "js") else {
            return
        }
        let jsDestinationURL = documentDirectory.appendingPathComponent("page.js")
        uploadToFileManager(fileManager: fileManager, source: filePath, destination: jsDestinationURL)
    }

}
