//
//  WebViewController.swift
//  Example
//
//  Created by Stefan Wieland on 24/08/15.
//  Copyright © 2015 aaa - all about apps GmbH. All rights reserved.
//

import UIKit
import WebKit

public enum ContentType {
    case LocalURL(url: NSURL)
    case ExternalURL(url: NSURL)
    case HtmlString(htmlString: String)
}

public class WebViewController: UIViewController {

    /// WKWebView will present web content
    public var webView: WKWebView!
    
    /// show loading progressBar, by default progressbar is only shown for ExternalURL
    public var showLoadingProgress = true
    
    /// show loading toolBar, by default toolBar is only shown for ExternalURL
    public var showToolBar = false
    
    /// tintColor will color barButtons and progressBar color
    public var tintColor: UIColor = UIColor.blueColor()
    
    /**
    Call to inject an CSS file from bundle
    
    :param: filename without file extension
    */
    public func addCSSFileFromBundle(filename: String) {
        cssScript = WKUserScript(source: cssJSContentForFile(filename), injectionTime: .AtDocumentStart, forMainFrameOnly: false)
    }
    
    /**
        Do not use init with code init:content:closeHandler is recommend
    */
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    Returns a WebViewController init with content and closeHandler
    
    :param: 
        #content:
            define the type of content: ExternaURL, LocalURL (html in bundle) and html Strings
        #closeHanlder:
            is triggered by "Done" button in modal presentation style
    
    :returns: WebViewController
    */
    public init(content: ContentType, closeHandler: ((controller: WebViewController) -> Void)?) {
        self.contentType = content
        self.closeHandler = closeHandler
        super.init(nibName: nil, bundle: nil)
        
        switch contentType {
        case .ExternalURL:
            showLoadingProgress = true
            showToolBar = true
            break
        default:
            showLoadingProgress = false
            showToolBar = false
            break
        }

    }
    
    deinit {
        webView.scrollView.delegate = nil
        webView.navigationDelegate = nil
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUIWithWebView()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        switch contentType {
        case .ExternalURL(let url):
            loadExternalWebsite(url)
            break
        case .LocalURL(let url):
            loadLocalHTMLFile(url)
            break
        case .HtmlString(let htmlString):
            loadHtmlString(htmlString)
            break
        }
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let webViewController = self.webViewController {
            webViewController.view.frame = self.view.bounds
        }
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("[WebViewController] - DidReceiveMemoryWarning")
    }
    
    /// private vars
    private var webContext = UnsafeMutablePointer<Int>()
    private var contentType: ContentType
    private var closeHandler: ((controller: WebViewController) -> Void)?
    private var webViewController: UIViewController!
    private var progressView: UIProgressView!
    private var toolBar: UIToolbar!
    private var toolBarBottomConstraint: NSLayoutConstraint!
    private var startDragPosition: CGFloat?
    private var modalNavigationController: UINavigationController?
    
    private var barBackButton: UIBarButtonItem!
    private var barForwardButton: UIBarButtonItem!
    private var barReloadButton: UIBarButtonItem!
    private var cssScript: WKUserScript?
    
}

// MARK: - INIT UI
private extension WebViewController {
    
    func setupUIWithWebView() {
        
        view.tintColor = tintColor
        
        // init with navigation controller
        webViewController = UIViewController(nibName: nil, bundle: nil)
        
        if let navigationController = self.navigationController {
            // will show in navigation controller
            webViewController.willMoveToParentViewController(self)
            addChildViewController(webViewController)
            webViewController.didMoveToParentViewController(self)
            view.addSubview(webViewController.view)
            navigationController.navigationBar.tintColor = tintColor
        } else {
            // will present modal, add navigation controller for navigation bar
            let navigationController = UINavigationController(rootViewController: webViewController)
            webViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "webViewDoneButtonPressed")
            navigationController.willMoveToParentViewController(self)
            addChildViewController(navigationController)
            navigationController.didMoveToParentViewController(self)
            view.addSubview(navigationController.view)
            self.modalNavigationController = navigationController
        }
        
        // init webView
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        configuration.userContentController = controller
        
        if let cssScript = self.cssScript {
            configuration.userContentController.addUserScript(cssScript)
        }
        
        webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewController.view.addSubview(webView)
        
        let leftWeb = NSLayoutConstraint(item: webView, attribute: .Left, relatedBy: .Equal, toItem: webViewController.view, attribute: .Left, multiplier: 1.0, constant: 0.0)
        let rightWeb = NSLayoutConstraint(item: webView, attribute: .Right, relatedBy: .Equal, toItem: webViewController.view, attribute: .Right, multiplier: 1.0, constant: 0.0)
        let topWeb = NSLayoutConstraint(item: webView, attribute: .Top, relatedBy: .Equal, toItem: webViewController.topLayoutGuide, attribute: .Top, multiplier: 1.0, constant: 0.0)
        let bottomWeb = NSLayoutConstraint(item: webView, attribute: .Bottom, relatedBy: .Equal, toItem: webViewController.bottomLayoutGuide, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        
        webViewController.view.addConstraint(leftWeb)
        webViewController.view.addConstraint(rightWeb)
        webViewController.view.addConstraint(topWeb)
        webViewController.view.addConstraint(bottomWeb)
        
        // observer & delegates
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: NSKeyValueObservingOptions.New, context: &webContext)
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        
        // init progressView
        progressView = UIProgressView(progressViewStyle: .Default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.hidden = true
        progressView.tintColor = self.tintColor
        webViewController.view.addSubview(progressView)
        
        let left = NSLayoutConstraint(item: progressView, attribute: .Left, relatedBy: .Equal, toItem: webViewController.view, attribute: .Left, multiplier: 1.0, constant: 0.0)
        let right = NSLayoutConstraint(item: progressView, attribute: .Right, relatedBy: .Equal, toItem: webViewController.view, attribute: .Right, multiplier: 1.0, constant: 0.0)
        let vConstraint = NSLayoutConstraint(item: progressView, attribute: .Top, relatedBy: .Equal, toItem: webViewController.topLayoutGuide, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        
        webViewController.view.addConstraint(left)
        webViewController.view.addConstraint(right)
        webViewController.view.addConstraint(vConstraint)
        
        // init toolbar
        toolBar = UIToolbar(frame: CGRectZero)
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.hidden = !showToolBar
        webViewController.view.addSubview(toolBar)
        let tLeft = NSLayoutConstraint(item: toolBar, attribute: .Left, relatedBy: .Equal, toItem: webViewController.view, attribute: .Left, multiplier: 1.0, constant: 0.0)
        let tRight = NSLayoutConstraint(item: toolBar, attribute: .Right, relatedBy: .Equal, toItem: webViewController.view, attribute: .Right, multiplier: 1.0, constant: 0.0)
        toolBarBottomConstraint = NSLayoutConstraint(item: toolBar, attribute: .Bottom, relatedBy: .Equal, toItem: webViewController.bottomLayoutGuide, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        webViewController.view.addConstraint(tLeft)
        webViewController.view.addConstraint(tRight)
        webViewController.view.addConstraint(toolBarBottomConstraint)
        
        let backImage = UIImage(named: "arrow_back", inBundle: NSBundle(forClass: WebViewController.self), compatibleWithTraitCollection: nil)
        
        barBackButton = UIBarButtonItem(image: backImage, style: .Plain, target: self, action: "historyBackAction:")
        barForwardButton = UIBarButtonItem(image: UIImage(named: "arrow_forward", inBundle: NSBundle(forClass: WebViewController.self), compatibleWithTraitCollection: nil), style: .Plain, target: self, action: "historyForwardAction:")
        barReloadButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "reloadAction:")
        let barFlexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let barFixSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        let barFixSpaceSmal = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        barFixSpace.width = 20.0
        barFixSpaceSmal.width = 10.0
        
        barBackButton.enabled = false
        barForwardButton.enabled = false
        
        toolBar.items = [barFixSpaceSmal, barBackButton, barFixSpace, barForwardButton, barFlexSpace, barReloadButton]
    }
    
}

// MARK: - loading Content
private extension WebViewController {
    
    func loadExternalWebsite(url: NSURL) {
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
        webViewController.title = title
    }
    
    func loadLocalHTMLFile(url: NSURL) {
        if #available(iOS 9.0, *) {
            webView.loadFileURL(url, allowingReadAccessToURL: url)
        } else {
            webView.loadRequest(NSURLRequest(URL:url))
        }
        webViewController.title = title
    }
    
    func loadHtmlString(html: String) {
        webView.loadHTMLString(html, baseURL: nil)
        webView.configuration.preferences.minimumFontSize = 16.0
        webViewController.title = title
    }
    
}

// MARK: - Actions
extension WebViewController {
    
    func webViewDoneButtonPressed() {
        if let handler = self.closeHandler {
            handler(controller: self)
        }
    }
    
    func reloadAction(sender: UIBarButtonItem) {
        webView.reloadFromOrigin()
    }
    
    func historyBackAction(sender: UIBarButtonItem) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func historyForwardAction(sender: UIBarButtonItem) {
        if webView.canGoForward {
            webView.goForward()
        }
    }

}

// MARK: - Observer
public extension WebViewController {
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if context == &webContext {
            if let newValue = change?[NSKeyValueChangeNewKey] as? Float {
                
                if showLoadingProgress {
                    progressView.progress = newValue
                    if !progressView.hidden && (newValue >= 1.0 || newValue <= 0.0) {
                        hideAnimated(progressView)
                    } else if progressView.hidden {
                        showAnimated(progressView)
                    }
                }
                
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        
    }
    
}

extension WebViewController: WKNavigationDelegate {
    
    public func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        updateToolBarButtons()
    }
    
    public func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        updateToolBarButtons()
    }
    
    public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        updateToolBarButtons()
    }
    
}

extension WebViewController: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        startDragPosition = scrollView.contentOffset.y
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if let _ = self.startDragPosition {
            if !toolBar.hidden && showToolBar {
                showToolBarAnimated()
            }
        }
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if let startDragPosition = self.startDragPosition {
            let offset = scrollView.contentOffset.y - startDragPosition
            if offset <= toolBar.bounds.size.height && offset > 0 && !toolBar.hidden {
                toolBarBottomConstraint.constant = offset
                
                // TODO: navigation bar scaling on scroll
//                if let navigationController = self.navigationController {
//                    
//                    let originFrame = navigationController.navigationBar.frame
//                    
//                    navigationController.navigationBar.frame = CGRectMake(originFrame.origin.x, originFrame.origin.y, originFrame.size.width, 20)
//                    
//                } else if let navigationController = modalNavigationController {
//                    
//                    let originFrame = navigationController.navigationBar.frame
//                    
//                    navigationController.navigationBar.frame = CGRectMake(originFrame.origin.x, originFrame.origin.y, originFrame.size.width, 20)
//                    
//                }
                
                
            } else if !toolBar.hidden && offset > toolBar.bounds.size.height {
                toolBar.hidden = true
            }
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollingDidStop(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollingDidStop(scrollView)
    }
    
}

// MARK: - Helper
private extension WebViewController {
    
    func hideAnimated(view :UIView) {
        UIView.animateWithDuration(0.25, animations: { _ in
            view.alpha = 0.0
            })
            { complete in
            view.hidden = true
            }
    }
    
    func showAnimated(view :UIView) {
        UIView.animateWithDuration(0.25, animations: { _ in
            view.alpha = 1.0
            })
            { complete in
                view.hidden = false
            }
    }
    
    func scrollingDidStop(scrollView: UIScrollView) {
        if showToolBar {
            if let startDragPosition = self.startDragPosition {
                self.startDragPosition = nil
                let offset = scrollView.contentOffset.y - startDragPosition
                if offset <= 0 || scrollView.contentOffset.y <= 0 {
                    showToolBarAnimated()
                }
            }
        }
    }
    
    func showToolBarAnimated() {
        toolBar.hidden = false
        UIView.animateWithDuration(0.5) { [unowned self] in
            self.toolBarBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func updateToolBarButtons() {
        barBackButton.enabled = webView.canGoBack
        barForwardButton.enabled = webView.canGoForward
    }
    
    func cssJSContentForFile(fileName: String) -> String {
        
        var cssString = ""
        var js = ""
        
        if let url = NSBundle.mainBundle().pathForResource(fileName, ofType:"css") {
            do {
                cssString = try String(contentsOfFile: url, encoding: NSUTF8StringEncoding)
                cssString = cssString.stringByReplacingOccurrencesOfString("\n", withString: "")
            } catch {
                print("[WebViewController] Error: failed to read css file")
            }
            
            js = "var styleTag = document.createElement('style');"
            js += "styleTag.textContent = '\(cssString)';"
            js += "document.documentElement.appendChild(styleTag);"
            
        } else {
            print("[WebViewController] Error: Failed open css file")
        }
        return js
    }
    
    func jSHide() -> String {
        
        let js = "var styleTag = document.createElement('style'); styleTag.textContent = 'h1 {color: #00ff00;}'; document.documentElement.appendChild(styleTag);";
        
        return js
    }
}
