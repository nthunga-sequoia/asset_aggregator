//
//  ReaderWebView.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 22/03/23.
//

import Foundation
import WebKit

class ReaderWebView: WKWebView {

    init(frame: CGRect) {
        let conf = WKWebViewConfiguration()
        conf.setURLSchemeHandler(SchemaHandler(), forURLScheme: "sample")
        super.init(frame: frame, configuration: conf)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
