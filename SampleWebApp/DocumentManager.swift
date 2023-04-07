//
//  DocumentManager.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 07/04/23.
//

import Foundation

struct DocumentManager {
    
    init() {
        print("\nDocumentManger ---> Initialized")
    }
    
    // MARK: - Fetching the assets from local Document folder
    func fetchAssetURLFromDocument(_ url: URL) -> URL? {
        print("\nFile URL from URL --->", url)
        
        var folderName = URLConstants.UnzippedFile + "/" + URLConstants.SchemaURL
        
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
            let queryString = URLConstants.UnzippedFile + "/" + URLConstants.SchemaURL + "/images/"
            queryFileName = folderName.components(separatedBy: queryString).last ?? ""
        }
        else {
            let queryString = URLConstants.UnzippedFile + "/" + URLConstants.SchemaURL + "/"
            queryFileName = folderName.components(separatedBy: queryString).last ?? ""
        }
        var dataURL = fetchFileURLFromDocument(url, fileName: queryFileName) ?? nil
        
        if dataURL == nil {
            dataURL = fetchMissingAssetsForDocument(url: url)
        }
        return dataURL
    }
    
    private func fetchFileURLFromDocument(_ url: URL, fileName: String) -> URL? {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let pathURLString = URLConstants.UnzippedFile + "/" + URLConstants.SchemaURL
        let unzippedURLs = documentDirectory.appendingPathComponent(pathURLString)
        let documentFiles = try? FileManager.default.contentsOfDirectory(at: unzippedURLs, includingPropertiesForKeys: nil)
        
        if let files = documentFiles {
            for fileUrl in files {
                // Do something with the HTML file, such as loading it into a WebView
                
                if let mimeType = Helper.mimeType(ofFileAtUrl: url), mimeType == "image/jpeg" {
                    if fileUrl.lastPathComponent != "images" {
                        continue
                    }
                    let imageFolderURL = URLConstants.UnzippedFile + "/" + URLConstants.SchemaURL + "/images"
                    let folderURL = documentDirectory.appendingPathComponent(imageFolderURL)
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
    
    private func uploadImagesToFileManager(imageNamed: String, imageData: Data) -> URL? {
        // save images to document folder
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let queryString = URLConstants.UnzippedFile + "/" + URLConstants.SchemaURL + "/images"
        let folderURL = documentsDirectoryURL.appendingPathComponent(queryString)
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
    
    // MARK: - Fetching the assets from local Bundle
    
    func fetchAssetURLFromBundle(_ url: URL) -> URL? {
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
}
