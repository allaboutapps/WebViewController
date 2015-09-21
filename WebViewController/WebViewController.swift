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

    /// show loading progressBar, by default progressbar is only shown for ExternalURL
    public var showLoadingProgress = true

    /// show loading toolBar, by default toolBar is only shown for ExternalURL
    public var showToolBar = false

    /// automatically hides/show tool bar on scroll
    public var autoHideToolbar = true

    /// will add an hidden button at buttom to restore toolbar on touch. Only if toolBar is enabled
    public var restoreToolBarOnBottomTouch = true
    
    /// tintColor will color barButtons and progressBar color
    public var tintColor: UIColor = UIColor.blueColor()
    
    /// if enabled will open urls with http:// or https:// in Safari. mailto: emails will always open with mail app.
    public var openExternalLinksInSafari: Bool = true
    
    /**
    Call to inject an CSS file from bundle
    
    :param: filename without file extension
    */
    public func addCSS(cssFileName: String, bundle: NSBundle = NSBundle.mainBundle()) {
        cssScript = WKUserScript(source: cssJSContentForFile(bundle: bundle, fileName: cssFileName), injectionTime: .AtDocumentStart, forMainFrameOnly: false)
    }
    
    /**
        Do not use init with coder! "init:content:closeHandler" is recommend
    */
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    Returns a WebViewController init with content and optional closeHandler
    
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
        setupUI()
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
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "title")
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let webViewController = self.webViewController {
            webViewController.view.frame = self.view.bounds
        }
    }

    /// private vars
    private var webView: WKWebView!
    private var webContext = UnsafeMutablePointer<Int>()
    private var customTitle: String?
    private var contentType: ContentType
    private var closeHandler: ((controller: WebViewController) -> Void)?
    private var webViewController: UIViewController!
    private var toolBarBottomConstraint: NSLayoutConstraint!
    private var startDragPosition: CGFloat?
    private var modalNavigationController: UINavigationController?
    private var barBackButton: UIBarButtonItem!
    private var barForwardButton: UIBarButtonItem!
    private var barReloadButton: UIBarButtonItem!
    
    private var progressView: UIProgressView?
    private var toolBar: UIToolbar?
    private var hiddenToolBarRestoreButton: UIButton?
    private var cssScript: WKUserScript?
    
}

// MARK: - INIT UI
private extension WebViewController {
    
    func setupUI() {
        
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
        
        setupWebView()
        
        if showLoadingProgress {
            setupProgressView()
        }
        
        if showToolBar {
            setupToolBar()
            if restoreToolBarOnBottomTouch && autoHideToolbar {
                setupHiddenToolBarRestoreButton()
            }
        }
        
        view.tintColor = tintColor
        customTitle = title
    }
    
    func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        configuration.userContentController = controller
        
        if let cssScript = self.cssScript {
            configuration.userContentController.addUserScript(cssScript)
        }
        
        webView = WKWebView(frame: CGRectZero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewController.view.addSubview(webView)
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        
        let leftWeb = NSLayoutConstraint(item: webView, attribute: .Left, relatedBy: .Equal, toItem: webViewController.view, attribute: .Left, multiplier: 1.0, constant: 0.0)
        let rightWeb = NSLayoutConstraint(item: webView, attribute: .Right, relatedBy: .Equal, toItem: webViewController.view, attribute: .Right, multiplier: 1.0, constant: 0.0)
        let topWeb = NSLayoutConstraint(item: webView, attribute: .Top, relatedBy: .Equal, toItem: webViewController.topLayoutGuide, attribute: .Top, multiplier: 1.0, constant: 0.0)
        let bottomWeb = NSLayoutConstraint(item: webView, attribute: .Bottom, relatedBy: .Equal, toItem: webViewController.bottomLayoutGuide, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        
        webViewController.view.addConstraint(leftWeb)
        webViewController.view.addConstraint(rightWeb)
        webViewController.view.addConstraint(topWeb)
        webViewController.view.addConstraint(bottomWeb)
        
        // observer & delegates
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Initial], context: &webContext)
        webView.addObserver(self, forKeyPath: "title", options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Initial], context: &webContext)
        webView.UIDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
    }
    
    func setupProgressView() {
        let progressView = UIProgressView(progressViewStyle: .Default)
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
        self.progressView = progressView
    }
    
    func setupToolBar() {
        let toolBar = UIToolbar(frame: CGRectZero)
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.hidden = !showToolBar
        webViewController.view.addSubview(toolBar)
        let tLeft = NSLayoutConstraint(item: toolBar, attribute: .Left, relatedBy: .Equal, toItem: webViewController.view, attribute: .Left, multiplier: 1.0, constant: 0.0)
        let tRight = NSLayoutConstraint(item: toolBar, attribute: .Right, relatedBy: .Equal, toItem: webViewController.view, attribute: .Right, multiplier: 1.0, constant: 0.0)
        toolBarBottomConstraint = NSLayoutConstraint(item: toolBar, attribute: .Bottom, relatedBy: .Equal, toItem: webViewController.bottomLayoutGuide, attribute: .Top, multiplier: 1.0, constant: 0.0)
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
        self.toolBar = toolBar
    }
    
    func setupHiddenToolBarRestoreButton() {
        let button = UIButton()
        button.addTarget(self, action: "hiddenToolBarRestoreButtonTouchUpInside:", forControlEvents: .TouchUpInside)
        button.setTitle("", forState: .Normal)
        button.setTitle("", forState: .Disabled)
        button.setTitle("", forState: .Highlighted)
        button.setTitle("", forState: .Reserved)
        button.setTitle("", forState: .Selected)
        button.setTitle("", forState: .Application)
        button.backgroundColor = UIColor.clearColor()
        button.translatesAutoresizingMaskIntoConstraints = false
        webViewController.view.addSubview(button)
        let left = NSLayoutConstraint(item: button, attribute: .Left, relatedBy: .Equal, toItem: webViewController.view, attribute: .Left, multiplier: 1.0, constant: 0.0)
        let right = NSLayoutConstraint(item: button, attribute: .Right, relatedBy: .Equal, toItem: webViewController.view, attribute: .Right, multiplier: 1.0, constant: 0.0)
        let bottom = NSLayoutConstraint(item: button, attribute: .Bottom, relatedBy: .Equal, toItem: webViewController.bottomLayoutGuide, attribute: .Top, multiplier: 1.0, constant: 0.0)
        let height = NSLayoutConstraint(item: button, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 20.0)
        webViewController.view.addConstraint(left)
        webViewController.view.addConstraint(right)
        webViewController.view.addConstraint(bottom)
        webViewController.view.addConstraint(height)
        hiddenToolBarRestoreButton = button
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
            // iOS8 bug, will not load bundle files in wkwebview
            do {
                let htmlString = try String(contentsOfFile: url.absoluteString, encoding: NSUTF8StringEncoding)
                webView.loadHTMLString(htmlString, baseURL: nil)
            } catch {
                print("[WebViewController] Could not load string from file in bundle")
            }
        }
        webViewController.title = title
    }
    
    func loadHtmlString(html: String) {
        
        var htmlString = ""
        
        if !html.containsString("<html>") {
            htmlString = "<html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\" /></head><body>"
            htmlString += html
            htmlString += "</body></html>"
        } else {
            htmlString = html
        }
        
        webView.loadHTMLString(htmlString, baseURL: nil)
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
    
    func hiddenToolBarRestoreButtonTouchUpInside(sender: UIButton) {
        showToolBarAnimated()
    }

}

// MARK: - Observer
public extension WebViewController {
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if context == &webContext && keyPath == "estimatedProgress" {
            if let newValue = change?[NSKeyValueChangeNewKey] as? Float {
                
                if let progressView = self.progressView {
                    progressView.progress = newValue
                    if !progressView.hidden && (newValue >= 1.0 || newValue <= 0.0) {
                        hideProgressViewAnimated(progressView)
                        if let toolBar = self.toolBar {
                            // adjust scrollview inset if loading is finished
                            let inset = webView.scrollView.scrollIndicatorInsets
                            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(inset.top, inset.left, toolBar.bounds.height, inset.right)
                            webView.scrollView.contentInset = UIEdgeInsetsMake(inset.top, inset.left, toolBar.bounds.height, inset.right)
                        }
                    } else if progressView.hidden {
                        showProgressViewAnimated(progressView)
                    }
                }
                
                if let barReloadButton = barReloadButton {
                    barReloadButton.enabled = (newValue >= 0.9)
                }
            }
        }
        else if context == &webContext && keyPath == "title" {
            if customTitle == nil {
                if let newValue = change?[NSKeyValueChangeNewKey] as? String {
                    if let _ = modalNavigationController {
                        webViewController.title = newValue
                    } else {
                        title = newValue
                    }
                }
            }
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
        
    }
    
}

// WKUIDelegate
extension WebViewController: WKUIDelegate {
    
    public func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if openExternalLinksInSafari {
            if navigationAction.targetFrame == nil {
                if let url = navigationAction.request.URL {
                    if url.description.lowercaseString.rangeOfString("http://") != nil || url.description.lowercaseString.rangeOfString("https://") != nil || url.description.lowercaseString.rangeOfString("mailto:") != nil  {
                        UIApplication.sharedApplication().openURL(url)
                    }
                }
            }
        }
        return nil
    }

}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    
    public func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        if let _ = self.toolBar {
            updateToolBarButtons()
        }
    }
    
    public func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        if let _ = self.toolBar {
            updateToolBarButtons()
        }
    }
    
    public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        if let _ = self.toolBar {
            updateToolBarButtons()
        }
    }
    
    public func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.URL where openExternalLinksInSafari || url.absoluteString.containsString("mailto") {
            switch contentType {
            case .HtmlString:
                openURLInExternalApp(url) ? decisionHandler(.Cancel) : decisionHandler(.Allow)
                return
            case .LocalURL:
                openURLInExternalApp(url) ? decisionHandler(.Cancel) : decisionHandler(.Allow)
                return
            default:
                break
            }
        }
        
        decisionHandler(.Allow)
        
    }
}

// MARK: - UIScrollViewDelegate
extension WebViewController: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        startDragPosition = scrollView.contentOffset.y
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if let _ = self.startDragPosition {
            if let toolBar = toolBar {
                if !toolBar.hidden && autoHideToolbar {
                    showToolBarAnimated()
                }
            }
        }
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if autoHideToolbar {
            if let startDragPosition = self.startDragPosition, toolBar = self.toolBar {
                let offset = scrollView.contentOffset.y - startDragPosition
                if offset <= toolBar.bounds.size.height && offset > 0 && !toolBar.hidden {
                    toolBarBottomConstraint.constant = offset
                } else if !toolBar.hidden && offset > toolBar.bounds.size.height {
                    hideToolBar()
                }
            }
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if autoHideToolbar {
            scrollingDidStop(scrollView)
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if autoHideToolbar {
            scrollingDidStop(scrollView)
        }
    }
    
}

// MARK: - Helper
private extension WebViewController {
    
    func hideProgressViewAnimated(view :UIView) {
        UIView.animateWithDuration(0.25, animations: { _ in
            view.alpha = 0.0
            })
            { complete in
            view.hidden = true
            }
    }
    
    func showProgressViewAnimated(view :UIView) {
        UIView.animateWithDuration(0.25, animations: { _ in
            view.alpha = 1.0
            })
            { complete in
                view.hidden = false
            }
    }
    
    func scrollingDidStop(scrollView: UIScrollView) {
        if let _ = self.toolBar {
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
        if let toolBar = self.toolBar {
            toolBar.hidden = false
            UIView.animateWithDuration(0.25) { [unowned self] in
                self.toolBarBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }
            let inset = webView.scrollView.scrollIndicatorInsets
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(inset.top, inset.left, toolBar.bounds.height, inset.right)
            webView.scrollView.contentInset = UIEdgeInsetsMake(inset.top, inset.left, toolBar.bounds.height, inset.right)
        }
        if let button = hiddenToolBarRestoreButton {
            button.enabled = false
        }
    }
    
    func hideToolBar() {
        if let toolBar = self.toolBar {
            toolBar.hidden = true
            let inset = webView.scrollView.scrollIndicatorInsets
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(inset.top, inset.left, 0, inset.right)
            webView.scrollView.contentInset = UIEdgeInsetsMake(inset.top, inset.left, 0, inset.right)
            if let button = hiddenToolBarRestoreButton {
                button.enabled = true
            }
        }
    }
    
    func updateToolBarButtons() {
        barBackButton.enabled = webView.canGoBack
        barForwardButton.enabled = webView.canGoForward
    }
    
    func openURLInExternalApp(url : NSURL) -> Bool {
        if url.absoluteString.hasPrefix("http") || url.absoluteString.hasPrefix("mailto") {
            if UIApplication.sharedApplication().canOpenURL(url) {
                UIApplication.sharedApplication().openURL(url)
                return true
            }
        }
        return false
    }
  
    func cssJSContentForFile(bundle bundle: NSBundle, fileName: String) -> String {
        
        var cssString = ""
        var js = ""
        
        if let url = bundle.pathForResource(fileName, ofType:"css") {
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
