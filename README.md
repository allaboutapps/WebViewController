# WebViewController

A WebViewController to display external and local content written in swift 3.0.

supported iOS Version +8.0

## Usage

The `WebViewController` needs to be initialized with a `ContentType`.
ContentType can either be an external URL, a local HTML file in the application bundle or an HTML string.

```swift
let url = NSURL(string: "https://apple.com")!
let webView = WebViewController(content: .ExternalURL(url: url)) { controller in
	controller.dismissViewControllerAnimated(true, completion: nil)
}
presentViewController(webView, animated: true, completion: nil)
```

### Configuration

The WebViewController can be configured to show progress and a navigation toolbar, as well as adopt to a specific tint color.

```swift 
webView.showLoadingProgess = true
webView.showToolBar = true
webView.tintColor = .redColor()
```

### Custom CSS for HTML pages

WebViewController support a custom CSS to style your HTML content.
Call `addCSS:bundle:` to inject a new CSS style.

## App Transport Security (ATS)

### Since iOS 9 HTTPS and TLSv1.2 is required!

> App Transport Security (ATS) lets an app add a declaration to its Info.plist file that specifies the domains with which it needs secure communication. ATS prevents accidental disclosure, provides secure default behavior, and is easy to adopt. You should adopt ATS as soon as possible, regardless of whether you’re creating a new app or updating an existing one.

> If you’re developing a new app, you should use HTTPS exclusively. If you have an existing app, you should use HTTPS as much as you can right now, and create a plan for migrating the rest of your app as soon as possible.
> If you want to display websites without https you have to enter the basepath in your ```Info.plist ```

```bash
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
    <key>yourserver.com</key>
    <dict>
      <!--Include to allow subdomains-->
      <key>NSIncludesSubdomains</key>
      <true/>
      <!--Include to allow HTTP requests-->
      <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
      <true/>
      <!--Include to specify minimum TLS version-->
      <key>NSTemporaryExceptionMinimumTLSVersion</key>
      <string>TLSv1.1</string>
    </dict>
  </dict>
</dict>
```

For more information about ATS go to:
<http://ste.vn/2015/06/10/configuring-app-transport-security-ios-9-osx-10-11>

## Install with Carthage

To integrate WebViewController into your Xcode project using Carthage, specify it in your ```Cartfile```

```
git "ssh://git@git.allaboutapps.at:2222/aaaios/webviewcontroller.git" "swift3"
```
This framework has to build with xcode8+

## Version Compatibility

Current Swift compatibility breakdown:

| Swift Version | Framework Version |
| ------------- | ----------------- |
| 3.0	        | swift3          	|
| 2.3	        | 1.2          		|

## Tests

Open the Xcode project and press `⌘-U` to run the tests.

Alternatively, all tests can be run from the terminal using [xctool](https://github.com/facebook/xctool).

```bash
xctool -scheme OAuthTests -sdk iphonesimulator test
```

## Contact

Feel free to get in touch.

* <stefan.wieland@allaboutapps.at>
