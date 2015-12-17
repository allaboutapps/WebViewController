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
    @IBAction func openWebSite1(sender: AnyObject) {
        let url = NSURL(string: "https://apple.com")!
        let webView = WebViewController(title: nil, content: .ExternalURL(url: url)) { controller in
            controller.dismissViewControllerAnimated(true, completion: nil)
        }

        presentViewController(webView, animated: true, completion: nil)
//        navigationController?.showViewController(webView, sender: self)
    }
    
    /// Opens a local HTML file
    @IBAction func openWebSite2(sender: AnyObject) {
        let path = NSBundle.mainBundle().pathForResource("contact", ofType:"html")!
        let url = NSURL(fileURLWithPath: path)
        
        url.isFileReferenceURL()
        
        let webView = WebViewController(title: "Hallo Apple", content: .LocalURL(url: url), closeHandler: nil)
        
        webView.tintColor = UIColor.orangeColor()
        webView.addCSS("style")
        webView.openExternalLinksInSafari = true
        webView.showLoadingProgress = true
        
        navigationController?.showViewController(webView, sender: self)
    }
    
    /// Opens a HTML string
    @IBAction func openWebSite3(sender: AnyObject) {
        let webView = WebViewController(title: "Hallo Apple", content: ContentType.HtmlString(htmlString: "hallo")) { controller in
            controller.dismissViewControllerAnimated(true, completion: nil)
        }
        presentViewController(webView, animated: true, completion: nil)
    }

}

