import Flutter
import UIKit
import WebKit

public class SwiftFlutterHtmlToPdfPlugin: NSObject, FlutterPlugin{
  var wkWebView : WKWebView!
  var urlObservation: NSKeyValueObservation?
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_html_to_pdf_plus", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterHtmlToPdfPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "convertHtmlToPdf":
        // Safely parse arguments
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a JSON object", details: nil))
            return
        }

        // htmlFilePath must be provided
        guard let htmlFilePath = args["htmlFilePath"] as? String, !htmlFilePath.isEmpty else {
            result(FlutterError(code: "MISSING_HTML_PATH", message: "'htmlFilePath' is required", details: nil))
            return
        }

        // Support width/height provided as Int or Double
        let widthValue = args["width"]
        let heightValue = args["height"]

        func toDouble(_ any: Any?) -> Double? {
            if let i = any as? Int { return Double(i) }
            if let d = any as? Double { return d }
            if let s = any as? String, let d = Double(s) { return d }
            return nil
        }

        guard let width = toDouble(widthValue), let height = toDouble(heightValue), width > 0, height > 0 else {
            result(FlutterError(code: "INVALID_SIZE", message: "'width' and 'height' must be positive numbers", details: nil))
            return
        }

        // margins can be [Int] or [Double] or [String]
        var margins: [Int]? = nil
        if let rawMargins = args["margins"] {
            if let ints = rawMargins as? [Int] {
                margins = ints
            } else if let doubles = rawMargins as? [Double] {
                margins = doubles.map { Int($0) }
            } else if let strings = rawMargins as? [String] {
                margins = strings.compactMap { Int($0) }
            }
        }

        let linksClickable = (args["linksClickable"] as? Bool) ?? false

        // Create WKWebView safely
        let webView = WKWebView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: height)))
        webView.isHidden = true
        webView.tag = 100
        self.wkWebView = webView

        // Obtain a root view controller safely (iOS 13+ scene support)
        let viewController = SwiftFlutterHtmlToPdfPlugin.getRootViewController()
        guard let containerView = viewController?.view else {
            result(FlutterError(code: "NO_ROOT_VIEW", message: "Unable to get root view to attach WKWebView", details: nil))
            return
        }
        containerView.addSubview(webView)

        // the `position: fixed` element not working as expected
        let contentController = webView.configuration.userContentController
        contentController.addUserScript(WKUserScript(source: "document.documentElement.style.webkitUserSelect='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        contentController.addUserScript(WKUserScript(source: "document.documentElement.style.webkitTouchCallout='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        webView.scrollView.bounces = false

        // Load local file content into the WKWebView
        let fileURL = URL(fileURLWithPath: htmlFilePath)
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)

        // Prepare print formatter
        let fmt: UIPrintFormatter
        if linksClickable {
            let htmlFileContent = FileHelper.getContent(from: htmlFilePath)
            fmt = UIMarkupTextPrintFormatter(markupText: htmlFileContent)
        } else {
            fmt = webView.viewPrintFormatter()
        }

        // Observe loading to trigger PDF creation
        urlObservation = webView.observe(\.isLoading, changeHandler: { [weak self] (webView, change) in
            guard let self = self else { return }
            // this is workaround for issue with loading local images
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let convertedFileURL = PDFCreator.create(printFormatter: fmt, width: width, height: height, margins: margins)
                let convertedFilePath = convertedFileURL.absoluteString.replacingOccurrences(of: "file://", with: "")

                if let viewWithTag = containerView.viewWithTag(100) {
                    viewWithTag.removeFromSuperview() // remove hidden webview when pdf is generated

                    // clear WKWebView cache
                    if #available(iOS 9.0, *) {
                        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                            records.forEach { record in
                                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                            }
                        }
                    }
                }

                // dispose WKWebView
                self.urlObservation = nil
                self.wkWebView = nil
                result(convertedFilePath)
            }
        })

    default:
        result(FlutterMethodNotImplemented)
    }
  }

  // Helper to safely get the root view controller
  private static func getRootViewController() -> UIViewController? {
      // iOS 13+ multiple scenes
      if #available(iOS 13.0, *) {
          let scenes = UIApplication.shared.connectedScenes
          let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
          let window = windowScene?.windows.first { $0.isKeyWindow }
          return window?.rootViewController
      } else {
          return UIApplication.shared.keyWindow?.rootViewController
      }
  }
}
