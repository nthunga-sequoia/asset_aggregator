//
//  Helper.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 06/04/23.
//

import Foundation
import UniformTypeIdentifiers
import ZipArchive

class Helper {
    
    
    class func mimeType(ofFileAtUrl url: URL) -> String? {
        //print("\nMIME type for URL --->", url)
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return nil
        }
        return type.preferredMIMEType
    }
    
    class func unzipFile(_ sourceFile: String) -> String? {
        guard let filePath = Bundle.main.path(forResource: sourceFile, ofType: "zip") else {
            print("\nBundle ---> Failed fetch zipped file")
            return nil
        }
        
        guard let tempPath = Bundle.main.path(forResource: "tempfolder", ofType: "") else {
            print("\nBundle ---> Failed fetch zipped file")
            return nil
        }

        let fileManager = FileManager.default
        guard let documentUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let result = SSZipArchive.unzipFile(atPath: filePath, toDestination: tempPath)
        if result == true {
            print("File unzipped successfully.")

            do {
                let folderURL = documentUrl.appendingPathComponent(URLConstants.UnzippedFile)
                if #available(iOS 16.0, *) {
                    try fileManager.copyItem(at: URL(filePath: tempPath), to: folderURL)
                } else {
                    // Fallback on earlier versions
                }
                print("\nFileManager ---> File uploaded successfully")
                return folderURL.absoluteString
            }
            catch {
                print("\nFileManager ---> Failed to load the file")
            }
        }
        else {
            print("Failed to unzip file.")
        }
        return nil
    }
}

