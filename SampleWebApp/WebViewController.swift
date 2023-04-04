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
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshWebView), name: NSNotification.Name("RefreshWebView"), object: nil)
    }
    
    // Reload the webivew, when some of the assets are missing
    @objc func refreshWebView() {
        webview.reload()
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
              let fileUrl = fetchAssetURLFromDocument(url), // Switch the file source here
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
    
    private func mimeType(ofFileAtUrl url: URL) -> String? {
        //print("\nMIME type for URL --->", url)
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return nil
        }
        return type.preferredMIMEType
    }
    
    // MARK: - Fetching the assets from local Bundle

    private func fetchAssetURLFromBundle(_ url: URL) -> URL? {
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
        
        var dataURL = Bundle.main.url(forResource: folderName,
                                  withExtension: "",
                                  subdirectory: "")
        
        if dataURL == nil {
            dataURL = fetchMissingAssetsForBundle(url: url)
        }
        
        return dataURL ?? nil
    }
    
    private func fetchMissingAssetsForBundle(url: URL) -> URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentDirectory.appendingPathComponent("images")
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating folder: \(error)")
        }
        
       // hard coded the image name for experiment
       let imageName = "imageassets/img3.jpeg"
       if let bundleURL = Bundle.main.url(forResource: imageName, withExtension: nil) {
           let finalImageName = imageName.components(separatedBy: "imageassets/").last ?? ""
           let destinationURL = folderURL.appendingPathComponent(finalImageName)
           do {
               try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
               print("\nFileManager ---> Image upload successful \(imageName)")
               return destinationURL
           } catch {
               print("\nFileManager ---> Error copying \(imageName): \(error)")
           }
       } else {
           print("\nFileManager ---> \(imageName) not found in bundle")
       }
        return nil
    }
    
    // MARK: - Fetching the assets from local Document folder

    private func fetchAssetURLFromDocument(_ url: URL) -> URL? {
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
        var dataURL = fetchFileURLFromDocument(url, fileName: queryFileName) ?? nil
        
        if dataURL == nil {
            dataURL = self.fetchMissingAssetsForDocument(url: url)
        }
        return dataURL
    }
    
    private func fetchMissingAssetsForDocument(url: URL) -> URL? {
        let imageNamed = url.lastPathComponent
        var dataURL = URL(string: "")
        guard let imageUrl = URL(string: "https://cdn.pixabay.com/photo/2015/03/10/17/23/youtube-667451_1280.png") else {
            return nil
        }
        
        let task = URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            guard let data = data, error == nil else {
                print("Data not found")
                return
            }
            dataURL = self.uploadImagesToFileManager(imageNamed: imageNamed, imageData: data)
            
            if dataURL != nil {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshWebView"), object: nil)
                }
            }
        }
        task.resume()
        return dataURL
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
    
    func uploadImagesToFileManager(imageNamed: String, imageData: Data) -> URL? {
        // save images to document folder
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentsDirectoryURL.appendingPathComponent("images")
        let fileURL = folderURL.appendingPathComponent(imageNamed)
        do {
            try imageData.write(to: fileURL)
            print("\nFileManager ---> Downloaed Image writing successful")
            return fileURL
        } catch {
            print("Error writing image data to file: \(error.localizedDescription)")
            return nil
        }
    }
}

