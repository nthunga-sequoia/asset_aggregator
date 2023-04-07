//
//  WebViewController.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 21/03/23.
//

import UIKit
import WebKit

// schema URL should be alway in lowercase
struct URLConstants {
    static let LoadingURL = "http://nthunga.infinityfreeapp.com"
    static let SourceURL = "http://nthunga.infinityfreeapp.com"
    static let TransformedURL = "localassets://nthunga.infinityfreeapp.com"
    static let SchemaURL = "localassets"
    static let UnzippedFile = "unzipped"
    
//    static let LoadingURL = "https://px.sequoia.com/"
//    static let SourceURL = "https://px.sequoia.com/"
//    static let TransformedURL = "assets://px.sequoia.com/rtw"
//    static let SchemaURL = "assets"
}

let documentManger = DocumentManager()

class WebViewController: UIViewController {
    
    var webview = WKWebView()
    
    override func loadView() {
        super.loadView()
        let destinationPath = Helper.unzipFile(URLConstants.SchemaURL)
        print("\n\nUnzipped file path -->",destinationPath ?? "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebview()
        loadWebPage()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshWebView), name: NSNotification.Name("RefreshWebView"), object: nil)
    }
        
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: — Private methods

    // Reload the webivew, when some of the assets are missing
    @objc func refreshWebView() {
        webview.reload()
    }
    
    private func loadWebPage() {
        if let requestURL = URL(string: URLConstants.LoadingURL) {
            let URLRequest = NSMutableURLRequest(url: requestURL)
            URLRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            webview.load(URLRequest as URLRequest)
        }
    }
    
    private func setupWebview() {
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
              let fileUrl = documentManger.fetchAssetURLFromDocument(url), // Switch the file source here
              let mimeType = Helper.mimeType(ofFileAtUrl: fileUrl),
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
}

//MARK: — WK Navigation Delegates methods

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
    
//    // Loading directly from file URL
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
//                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        guard let url = navigationAction.request.url, url.scheme == "http" || url.scheme == "https" else {
//            decisionHandler(.allow)
//            return
//        }
//
//        //MARK: Loading file from bundle
//        /*
//        guard let resourcePath = url.host else {
//            // Handle missing resource path
//            decisionHandler(.cancel)
//            return
//        }
//        guard let url = Bundle.main.url(forResource: resourcePath, withExtension: nil) else {
//            // Handle missing asset
//            decisionHandler(.cancel)
//            return
//        }
//
//        let finalURL = url.absoluteString + "index.html"
//        webView.loadFileURL(URL(string: finalURL)!, allowingReadAccessTo: url)
//        decisionHandler(.cancel)
//         */
//
//        //MARK: Loading file from document folder
//        let fileManager = FileManager.default
//        guard let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
//            return
//        }
//        let finalURL = documentUrl.absoluteString + "/index.html"
//        webView.loadFileURL(URL(string: finalURL)!, allowingReadAccessTo: documentUrl)
//        decisionHandler(.cancel)
//    }

//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//
//        if let url = navigationAction.request.url, !url.isFileURL {
//            if let resourceURL = Bundle.main.url(forResource: url.lastPathComponent, withExtension: nil) {
//                do {
//                    let resourceData = try Data(contentsOf: resourceURL)
//                    let mimeType = Helper.mimeType(ofFileAtUrl: url)
//                    webView.load(resourceData, mimeType: mimeType!, characterEncodingName: "UTF-8", baseURL: url.deletingLastPathComponent())
//                    decisionHandler(.cancel)
//                    return
//                } catch {
//                    print("Error loading file: \(error.localizedDescription)")
//                }
//            }
//        }
//        decisionHandler(.allow)
//    }
    
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
