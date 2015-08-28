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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openWebSite1(sender: AnyObject) {
        
        let url = NSURL(string: "https://apple.com")!
        let webView = WebViewController(content: .ExternalURL(url: url)) { controller in
            controller.dismissViewControllerAnimated(true, completion: nil)
        }
        webView.autoHideToolbar = false
        
        
//        presentViewController(webView, animated: true, completion: nil)
        navigationController?.showViewController(webView, sender: self)
    }
    
    @IBAction func openWebSite2(sender: AnyObject) {
        
        let url = NSURL(string: "https://apple.com")!
        let webView = WebViewController(content: .ExternalURL(url: url)) { controller in
            controller.dismissViewControllerAnimated(true, completion: nil)
        }
        //        presentViewController(webView, animated: true, completion: nil)
        navigationController?.showViewController(webView, sender: self)
    }
    
    @IBAction func openWebSite3(sender: AnyObject) {
        
        let url = NSURL(string: "https://apple.com")!
        let webView = WebViewController(content: .ExternalURL(url: url)) { controller in
            controller.dismissViewControllerAnimated(true, completion: nil)
        }
        //        presentViewController(webView, animated: true, completion: nil)
        navigationController?.showViewController(webView, sender: self)
    }
    


}

