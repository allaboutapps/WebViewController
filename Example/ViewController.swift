//
//  ViewController.swift
//  Example
//
//  Created by Stefan Wieland on 28/08/15.
//  Copyright © 2015 aaa - all about apps GmbH. All rights reserved.
//

import UIKit
import WebViewController

class ViewController: UIViewController {
    
    /// Opens an external URL
    @IBAction func openWebSite1(_ sender: AnyObject) {
        let url = URL(string: "http://google.at")!
        
        let webView = WebViewController(title: "Halloe", content: .externalURL(url: url), closeHandler: { viewController in
                viewController.dismiss(animated: true, completion: nil)
        })
        
        webView.loadedHTMLLinksHandler = { url in
            print(url)
        }
        webView.showLoadingProgress = true
        
        present(webView, animated: true, completion: nil)
        //navigationController?.showViewController(webView, sender: self)
    }
    
    /// Opens a local HTML file
    @IBAction func openWebSite2(_ sender: AnyObject) {
        let path = Bundle.main.path(forResource: "contact", ofType:"html")!
        let url = URL(fileURLWithPath: path)
        
        (url as NSURL).isFileReferenceURL()
        
        let webView = WebViewController(title: "Hallo Apple", content: .localURL(url: url), closeHandler: nil)
        
        webView.tintColor = UIColor.orange
        webView.addCSS("style")
        webView.openExternalLinksInSafari = true
        webView.showLoadingProgress = true
        
        navigationController?.show(webView, sender: self)
    }
    
    /// Opens a HTML string
    @IBAction func openWebSite3(_ sender: AnyObject) {
        let webView = WebViewController(title: "Hallo Apple", content: ContentType.htmlString(htmlString: "hallo")) { controller in
            controller.dismiss(animated: true, completion: nil)
        }
        present(webView, animated: true, completion: nil)
    }

}

