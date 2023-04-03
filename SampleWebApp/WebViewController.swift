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
//    static let TransformedURL = "assets://px.sequoia.com/rtw"
//    static let SchemaURL = "assets"
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

//MARK: — Custom URL schema Handler

class ConfigHandler: NSObject, WKURLSchemeHandler {

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        
        guard let url = urlSchemeTask.request.url,
              let fileUrl = fileUrlFromUrlFromBundle(url), // Switch the file source here
              let mimeType = mimeType(ofFileAtUrl: fileUrl),
              let data = try? Data(contentsOf: fileUrl) else { return }

        let response = HTTPURLResponse(url: url,
                                       mimeType: mimeType,
                                       expectedContentLength: data.count,
                                       textEncodingName: nil)
        
        print("\nURL Schema Task Response ---> ",response)

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

