//
//  ViewController.swift
//  SampleWebApp
//
//  Created by Naveen Thunga on 21/03/23.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    lazy var initialURL = "http://nthunga.infinityfreeapp.com/"
    var webview = WKWebView()

    override func loadView() {
        super.loadView()
        
        webview = ReaderWebView(frame: self.view.frame)
        self.view.addSubview(webview)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.perform(#selector(loadWebpage), with: nil, afterDelay: 1.0)
    }
    
    @objc func loadWebpage() {
        print("$$$$$$$ Triggered $$$$$$$$$$")
        loadHtmlIntoWebview()
    }
    
    internal func loadHtmlIntoWebview() -> Void {
        if #available(iOS 11.0 , *){
            let fileURL = Bundle.main.url(forResource: "sample", withExtension: "html")
            webview.loadFileURL(fileURL!, allowingReadAccessTo: fileURL!)
        }
    }
}


