//
//  Helper.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 06/04/23.
//

import Foundation
import UniformTypeIdentifiers

class Helper {
    
    
    class func mimeType(ofFileAtUrl url: URL) -> String? {
        //print("\nMIME type for URL --->", url)
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return nil
        }
        return type.preferredMIMEType
    }

}

