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
    case localURL(url: URL)
    case externalURL(url: URL)
    case htmlString(htmlString: String)
}

open class WebViewController: UIViewController {

    /// show loading progressBar, by default progressbar is only shown for ExternalURL
    open var showLoadingProgress = true

    /// toolbar will be presented at bottom
    open var toolBar: UIToolbar?
    
    /// show loading toolBar, by default toolBar is only shown for ExternalURL
    open var showToolBar = false

    /// automatically hides/show tool bar on scroll
    open var autoHideToolbar = true

    /// will add an hidden button at buttom to restore toolbar on touch. Only if toolBar is enabled
    open var restoreToolBarOnBottomTouch = true
    
    /// tintColor will color barButtons
    open var tintColor: UIColor?
    
    /// tintColor for progressBar
    open var progressColor: UIColor?
    
    /// if enabled will open urls with http:// or https:// in Safari. mailto: emails will always open with mail app.
    open var openExternalLinksInSafari: Bool = true
    
    /// NavigationController where WebViewcontroller will be presented
    open var webViewNaviationController: UINavigationController?
    
    /// pass all urls loaded in webview
    open var loadedHTMLLinksHandler: ((_ url: URL) -> Void)?
    
    /// change the contentMode of the WebView
    open var contentMode: UIViewContentMode? {
        didSet {
            guard let contentMode = contentMode, let webView = self.webView else {
                return
            }
            webView.contentMode = contentMode
        }
    }
    
    /**
    Call to inject an CSS file from bundle
    
    :param: filename without file extension
    */
    open func addCSS(_ cssFileName: String, bundle: Bundle = Bundle.main) {
        cssScript = WKUserScript(source: cssJSContentForFile(bundle: bundle, fileName: cssFileName), injectionTime: .atDocumentStart, forMainFrameOnly: false)
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
    public init(title: String? = nil, content: ContentType, closeHandler: ((_ controller: WebViewController) -> Void)? = nil){
        self.customTitle = title
        self.contentType = content
        self.closeHandler = closeHandler
        super.init(nibName: nil, bundle: nil)
        
        switch contentType {
        case .externalURL:
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
        webViewObserver.forEach({ $0.invalidate() })
    }
        
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupUI()
        
        switch contentType {
        case .externalURL(let url):
            loadExternalWebsite(url)
            break
        case .localURL(let url):
            loadLocalHTMLFile(url)
            break
        case .htmlString(let htmlString):
            loadHtmlString(htmlString)
            break
        }
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let webViewController = self.webViewController {
            webViewController.view.frame = self.view.bounds
        }
        if let contentMode = self.contentMode {
            webView.contentMode = contentMode
        }
    }

    /// private vars
    fileprivate var webView: WKWebView!
    fileprivate var webViewObserver: [NSKeyValueObservation] = []
    fileprivate var customTitle: String?
    fileprivate var contentType: ContentType
    fileprivate var closeHandler: ((_ controller: WebViewController) -> Void)?
    fileprivate var webViewController: UIViewController!
    fileprivate var toolBarBottomConstraint: NSLayoutConstraint!
    fileprivate var startDragPosition: CGFloat?
    fileprivate var modalNavigationController: UINavigationController?
    fileprivate var barBackButton: UIBarButtonItem!
    fileprivate var barForwardButton: UIBarButtonItem!
    fileprivate var barReloadButton: UIBarButtonItem!
    fileprivate var progressView: UIProgressView?
    fileprivate var hiddenToolBarRestoreButton: UIButton?
    fileprivate var cssScript: WKUserScript?
    
}

// MARK: - INIT UI
private extension WebViewController {
    
    func setupUI() {
        guard webViewController == nil else {
            return
        }
        
        webViewController = UIViewController(nibName: nil, bundle: nil)
        if let navigationController = self.navigationController {
            // will show in navigation controller
            webViewController.willMove(toParentViewController: self)
            addChildViewController(webViewController)
            webViewController.didMove(toParentViewController: self)
            view.addSubview(webViewController.view)
            if let tintColor = self.tintColor {
                navigationController.navigationBar.tintColor = tintColor
            }
            self.webViewNaviationController = navigationController
        } else {
            // will present modal, add navigation controller for navigation bar
            let navigationController = UINavigationController(rootViewController: webViewController)
            webViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(WebViewController.webViewDoneButtonPressed))
            navigationController.willMove(toParentViewController: self)
            addChildViewController(navigationController)
            navigationController.didMove(toParentViewController: self)
            view.addSubview(navigationController.view)
            self.modalNavigationController = navigationController
            self.webViewNaviationController = self.modalNavigationController
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
        
        if let tintColor = self.tintColor {
            view.tintColor = tintColor
        }
    }
    
    func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        configuration.userContentController = controller
        
        if let cssScript = self.cssScript {
            configuration.userContentController.addUserScript(cssScript)
        }
        
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewController.view.addSubview(webView)
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        
        let leftWeb = NSLayoutConstraint(item: webView, attribute: .left, relatedBy: .equal, toItem: webViewController.view, attribute: .left, multiplier: 1.0, constant: 0.0)
        let rightWeb = NSLayoutConstraint(item: webView, attribute: .right, relatedBy: .equal, toItem: webViewController.view, attribute: .right, multiplier: 1.0, constant: 0.0)
        let topWeb = NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: webViewController.topLayoutGuide, attribute: .top, multiplier: 1.0, constant: 0.0)
        let bottomWeb = NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: webViewController.bottomLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        
        webViewController.view.addConstraint(leftWeb)
        webViewController.view.addConstraint(rightWeb)
        webViewController.view.addConstraint(topWeb)
        webViewController.view.addConstraint(bottomWeb)
        
        // observer & delegates
        let progressObserver = webView.observe(\WKWebView.estimatedProgress, options: [.new]) { (wkWebView, change) in
            guard let newValue = change.newValue, let progressView = self.progressView else { return }
            
            progressView.progress = Float(newValue)
            if !progressView.isHidden && (newValue >= 1.0 || newValue <= 0.0) {
                self.hideProgressViewAnimated(progressView)
                if let toolBar = self.toolBar {
                    // adjust scrollview inset if loading is finished
                    let inset = self.webView.scrollView.scrollIndicatorInsets
                    self.webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(inset.top, inset.left, toolBar.bounds.height, inset.right)
                    self.webView.scrollView.contentInset = UIEdgeInsetsMake(inset.top, inset.left, toolBar.bounds.height, inset.right)
                }
            } else if progressView.isHidden {
                self.showProgressViewAnimated(progressView)
            }
        }
        
        let titleObserver = webView.observe(\WKWebView.title, options: [.new]) { (wkWebView, change) in
            guard let newValue = change.newValue, self.customTitle == nil else { return }
            
            self.setTitle(newValue)
        }
        
        webViewObserver.append(contentsOf: [progressObserver, titleObserver])
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
    }
    
    func setupProgressView() {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        if let progressColor = self.progressColor {
            progressView.tintColor = progressColor
        }
        webViewController.view.addSubview(progressView)
        
        let left = NSLayoutConstraint(item: progressView, attribute: .left, relatedBy: .equal, toItem: webViewController.view, attribute: .left, multiplier: 1.0, constant: 0.0)
        let right = NSLayoutConstraint(item: progressView, attribute: .right, relatedBy: .equal, toItem: webViewController.view, attribute: .right, multiplier: 1.0, constant: 0.0)
        let vConstraint = NSLayoutConstraint(item: progressView, attribute: .top, relatedBy: .equal, toItem: webViewController.topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        
        webViewController.view.addConstraint(left)
        webViewController.view.addConstraint(right)
        webViewController.view.addConstraint(vConstraint)
        self.progressView = progressView
    }
    
    func setupToolBar() {
        let toolBar = UIToolbar(frame: CGRect.zero)
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.isHidden = !showToolBar
        webViewController.view.addSubview(toolBar)
        let tLeft = NSLayoutConstraint(item: toolBar, attribute: .left, relatedBy: .equal, toItem: webViewController.view, attribute: .left, multiplier: 1.0, constant: 0.0)
        let tRight = NSLayoutConstraint(item: toolBar, attribute: .right, relatedBy: .equal, toItem: webViewController.view, attribute: .right, multiplier: 1.0, constant: 0.0)
        toolBarBottomConstraint = NSLayoutConstraint(item: toolBar, attribute: .bottom, relatedBy: .equal, toItem: webViewController.bottomLayoutGuide, attribute: .top, multiplier: 1.0, constant: 0.0)
        webViewController.view.addConstraint(tLeft)
        webViewController.view.addConstraint(tRight)
        webViewController.view.addConstraint(toolBarBottomConstraint)
        
        let backImage = UIImage(named: "arrow_back", in: Bundle(for: WebViewController.self), compatibleWith: nil)
        
        barBackButton = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(WebViewController.historyBackAction(_:)))
        barForwardButton = UIBarButtonItem(image: UIImage(named: "arrow_forward", in: Bundle(for: WebViewController.self), compatibleWith: nil), style: .plain, target: self, action: #selector(WebViewController.historyForwardAction(_:)))
        barReloadButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(WebViewController.reloadAction(_:)))
        let barFlexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let barFixSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let barFixSpaceSmal = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        barFixSpace.width = 20.0
        barFixSpaceSmal.width = 10.0
        
        barBackButton.isEnabled = false
        barForwardButton.isEnabled = false
        
        toolBar.items = [barFixSpaceSmal, barBackButton, barFixSpace, barForwardButton, barFlexSpace, barReloadButton]
        self.toolBar = toolBar
    }
    
    func setupHiddenToolBarRestoreButton() {
        let button = UIButton()
        button.addTarget(self, action: #selector(WebViewController.hiddenToolBarRestoreButtonTouchUpInside(_:)), for: .touchUpInside)
        button.setTitle("", for: UIControlState())
        button.setTitle("", for: .disabled)
        button.setTitle("", for: .highlighted)
        button.setTitle("", for: .reserved)
        button.setTitle("", for: .selected)
        button.setTitle("", for: .application)
        button.backgroundColor = UIColor.clear
        button.translatesAutoresizingMaskIntoConstraints = false
        webViewController.view.addSubview(button)
        let left = NSLayoutConstraint(item: button, attribute: .left, relatedBy: .equal, toItem: webViewController.view, attribute: .left, multiplier: 1.0, constant: 0.0)
        let right = NSLayoutConstraint(item: button, attribute: .right, relatedBy: .equal, toItem: webViewController.view, attribute: .right, multiplier: 1.0, constant: 0.0)
        let bottom = NSLayoutConstraint(item: button, attribute: .bottom, relatedBy: .equal, toItem: webViewController.bottomLayoutGuide, attribute: .top, multiplier: 1.0, constant: 0.0)
        let height = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 20.0)
        webViewController.view.addConstraint(left)
        webViewController.view.addConstraint(right)
        webViewController.view.addConstraint(bottom)
        webViewController.view.addConstraint(height)
        button.isEnabled = false
        hiddenToolBarRestoreButton = button
    }
    
    func setTitle(_ titleText: String?) {
        if let _ = modalNavigationController {
            webViewController.title = titleText ?? customTitle
        } else {
            title = titleText ?? customTitle
        }
    }
    
}

// MARK: - loading Content
private extension WebViewController {
    
    func loadExternalWebsite(_ url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
        setTitle(nil)
    }
    
    func loadLocalHTMLFile(_ url: URL) {
        if #available(iOS 9.0, *) {
            webView.loadFileURL(url, allowingReadAccessTo: url)
        } else {
            // iOS8 bug, will not load bundle files in wkwebview
            do {
                let htmlString = try String(contentsOfFile: url.absoluteString, encoding: String.Encoding.utf8)
                webView.loadHTMLString(htmlString, baseURL: nil)
            } catch {
                print("[WebViewController] Could not load string from file in bundle")
            }
        }
        setTitle(nil)
    }
    
    func loadHtmlString(_ html: String) {
        
        var htmlString = ""
        
        if !html.contains("<html>") {
            htmlString = "<html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no\" /></head><body>"
            htmlString += html
            htmlString += "</body></html>"
        } else {
            htmlString = html
        }
        
        webView.loadHTMLString(htmlString, baseURL: nil)
        webView.configuration.preferences.minimumFontSize = 16.0
        setTitle(nil)
    }
    
}

// MARK: - Actions
extension WebViewController {
    
    @objc func webViewDoneButtonPressed() {
        if let handler = self.closeHandler {
            handler(self)
        }
    }
    
    @objc func reloadAction(_ sender: UIBarButtonItem) {
        webView.reloadFromOrigin()
    }
    
    @objc func historyBackAction(_ sender: UIBarButtonItem) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc func historyForwardAction(_ sender: UIBarButtonItem) {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @objc func hiddenToolBarRestoreButtonTouchUpInside(_ sender: UIButton) {
        showToolBarAnimated()
    }

}

// WKUIDelegate
extension WebViewController: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if openExternalLinksInSafari {
            if navigationAction.targetFrame == nil {
                if let url = navigationAction.request.url {
                    if url.description.lowercased().range(of: "http://") != nil || url.description.lowercased().range(of: "https://") != nil || url.description.lowercased().range(of: "mailto:") != nil  {
                        UIApplication.shared.openURL(url)
                    }
                }
            }
        }
        return nil
    }

}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let _ = self.toolBar {
            updateToolBarButtons()
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if let _ = self.toolBar {
            updateToolBarButtons()
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let _ = self.toolBar {
            updateToolBarButtons()
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url, let linkAction = self.loadedHTMLLinksHandler {
            linkAction(url)
        }
        
        if let url = navigationAction.request.url , openExternalLinksInSafari || url.absoluteString.contains("mailto") {
            switch contentType {
            case .htmlString:
                openURLInExternalApp(url) ? decisionHandler(.cancel) : decisionHandler(.allow)
                return
            case .localURL:
                openURLInExternalApp(url) ? decisionHandler(.cancel) : decisionHandler(.allow)
                return
            default:
                break
            }
        }
        
        decisionHandler(.allow)
        
    }
}

// MARK: - UIScrollViewDelegate
extension WebViewController: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startDragPosition = scrollView.contentOffset.y
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if let _ = self.startDragPosition {
            if let toolBar = toolBar {
                if !toolBar.isHidden && autoHideToolbar {
                    showToolBarAnimated()
                }
            }
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if autoHideToolbar {
            if let startDragPosition = self.startDragPosition, let toolBar = self.toolBar {
                let offset = scrollView.contentOffset.y - startDragPosition
                if offset <= toolBar.bounds.size.height && offset > 0 && !toolBar.isHidden {
                    toolBarBottomConstraint.constant = offset
                } else if !toolBar.isHidden && offset > toolBar.bounds.size.height {
                    hideToolBar()
                }
            }
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if autoHideToolbar {
            scrollingDidStop(scrollView)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if autoHideToolbar {
            scrollingDidStop(scrollView)
        }
    }
    
}

// MARK: - Helper
private extension WebViewController {
    
    func hideProgressViewAnimated(_ view :UIView) {
        UIView.animate(withDuration: 0.25, animations: { 
            view.alpha = 0.0
            }, completion: { complete in
            view.isHidden = true
            })
            
    }
    
    func showProgressViewAnimated(_ view :UIView) {
        UIView.animate(withDuration: 0.25, animations: { 
            view.alpha = 1.0
            }, completion: { complete in
                view.isHidden = false
            })
            
    }
    
    func scrollingDidStop(_ scrollView: UIScrollView) {
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
            toolBar.isHidden = false
            UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                self.toolBarBottomConstraint.constant = 0
                self.view.layoutIfNeeded()
            }) 
            let inset = webView.scrollView.scrollIndicatorInsets
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(inset.top, inset.left, toolBar.bounds.height, inset.right)
            webView.scrollView.contentInset = UIEdgeInsetsMake(inset.top, inset.left, toolBar.bounds.height, inset.right)
        }
        if let button = hiddenToolBarRestoreButton {
            button.isEnabled = false
        }
    }
    
    func hideToolBar() {
        if let toolBar = self.toolBar {
            toolBar.isHidden = true
            let inset = webView.scrollView.scrollIndicatorInsets
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(inset.top, inset.left, 0, inset.right)
            webView.scrollView.contentInset = UIEdgeInsetsMake(inset.top, inset.left, 0, inset.right)
            if let button = hiddenToolBarRestoreButton {
                button.isEnabled = true
            }
        }
    }
    
    func updateToolBarButtons() {
        barBackButton.isEnabled = webView.canGoBack
        barForwardButton.isEnabled = webView.canGoForward
    }
    
    func openURLInExternalApp(_ url : URL) -> Bool {
        if url.absoluteString.hasPrefix("http") || url.absoluteString.hasPrefix("mailto") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
                return true
            }
        }
        return false
    }
  
    func cssJSContentForFile(bundle: Bundle, fileName: String) -> String {
        
        var cssString = ""
        var js = ""
        
        if let url = bundle.path(forResource: fileName, ofType:"css") {
            do {
                cssString = try String(contentsOfFile: url, encoding: String.Encoding.utf8)
                cssString = cssString.replacingOccurrences(of: "\n", with: "")
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
