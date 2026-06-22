import Cocoa
import FlutterMacOS
import WebKit
import PDFKit

public class FlutterHtmlToPdfPlusPlugin: NSObject, FlutterPlugin {
  // var wkWebView : WKWebView!
  // var urlObservation: NSKeyValueObservation?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_html_to_pdf_plus", binaryMessenger: registrar.messenger)
    let instance = FlutterHtmlToPdfPlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    // case "getPlatformVersion":
    //   result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)

    case "convertHtmlToPdf":
        let args = call.arguments as? [String: Any]
        let htmlFilePath = args!["htmlFilePath"] as? String
        let width = Double(args!["width"] as! Int)
        let height = Double(args!["height"] as! Int)
        let orientation = args!["orientation"]
        let margins = args!["margins"] as? [Int]

        // from https://github.com/owlswipe/CocoaPDFCreator/blob/master/CocoaPDFCreator.swift

        // let webView = WKWebView.init(frame: CGRect(origin: CGPoint(x:0, y:0), size: CGSize(width:width, height: height)))
        let webView = WebView()
        // webView.isHidden = true
        // // wkWebView.tag = 100

        // let viewControler = NSApplication.shared.delegate?.window?!.rootViewController
        // viewControler?.view.addSubview(wkWebView)

        // // the `position: fixed` element not working as expected
        // let contentController = wkWebView.configuration.userContentController
        // contentController.addUserScript(WKUserScript(source: "document.documentElement.style.webkitUserSelect='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        // contentController.addUserScript(WKUserScript(source: "document.documentElement.style.webkitTouchCallout='none';", injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        // // wkWebView.scrollView.bounces = false

        let htmlFileContent = FileHelper.getContent(from: htmlFilePath!) // get html content from file
        // wkWebView.loadHTMLString(htmlFileContent, baseURL: Bundle.main.bundleURL) // load html into hidden webview
        // let formatter: UIPrintFormatter = UIMarkupTextPrintFormatter(markupText: htmlFileContent)

        webView.mainFrame.loadHTMLString(htmlFileContent, baseURL: Bundle.main.bundleURL)
        // webView.loadHTMLString(htmlFileContent, baseURL: Bundle.main.bundleURL)

        let tempFile = NSTemporaryDirectory() + NSUUID().uuidString
        let directoryURL = URL(fileURLWithPath: tempFile)

        let printOpts: [NSPrintInfo.AttributeKey: Any] = [
            NSPrintInfo.AttributeKey.jobDisposition: NSPrintInfo.JobDisposition.save,
            NSPrintInfo.AttributeKey.jobSavingURL: directoryURL]

        let printInfo = NSPrintInfo(dictionary: printOpts)
        printInfo.horizontalPagination = NSPrintInfo.PaginationMode.automatic
        printInfo.verticalPagination = NSPrintInfo.PaginationMode.automatic

        printInfo.paperSize.width = width
        printInfo.paperSize.height = height

//         // printInfo.topMargin = margin.minY
//         // printInfo.leftMargin = margin.minX
//         // printInfo.rightMargin = size.width - margin.maxX
//         // printInfo.bottomMargin = size.height - margin.maxY
        if margins != nil {
            // let printable = CGRect(x: Double(margins![0]), y: Double(margins![1]), width: width - Double(margins![0]) -   Double(margins![2]), height: height - Double(margins![1]) - Double(margins![3]))
            
            printInfo.topMargin = CGFloat.init(margins![0])
            printInfo.leftMargin = CGFloat.init(margins![1])
            printInfo.rightMargin = CGFloat(margins![2])
            printInfo.bottomMargin = CGFloat(margins![3])
        }

        // urlObservation = wkWebView.observe(\.isLoading, changeHandler: { (webView, change) in
        //     // this is workaround for issue with loading local images

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            do {
                let printOperation = NSPrintOperation(view: webView.mainFrame.frameView.documentView, printInfo: printInfo)
                printOperation.showsPrintPanel = false
                printOperation.showsProgressPanel = false
                printOperation.run()
                
//                webView.createPDF() { res in
//                    switch res {
//                      case .success(let data):
//                        // Save the returned data to a PDF file
//                        // try! data.write(to: URL(fileURLWithPath: "\(folder)/Cool.pdf"))
//                        let url = FlutterHtmlToPdfPlusPlugin.createdFileURL;
//                        try! data.write(to: url, options: .atomic)
//                        result(url.absoluteString.replacingOccurrences(of: "file://", with: ""))
//                        
//                      case .failure(let error):
//                        print(error)
//                    }
//                }

                let data = try Data(contentsOf: directoryURL)
//
                let url = FlutterHtmlToPdfPlusPlugin.createdFileURL;
                guard nil != (try? data.write(to: url, options: .atomic))
                      else { fatalError("Error writing PDF data to file.") }

                result(url.absoluteString.replacingOccurrences(of: "file://", with: ""))

                // let fileManager = FileManager.default
                // try fileManager.removeItem(atPath: tempFile)
            } catch {
                // self.printing.onHtmlError(printJob: self, error: "Unable to load the pdf file from \(tempFile)")
                print("Unexpected error: \(error)")
            }

            // let convertedFileURL = PDFCreator.create(printFormatter: formatter, width: width, height: height, orientation: orientation as! String, margins: margins!)
            // let convertedFilePath = convertedFileURL.absoluteString.replacingOccurrences(of: "file://", with: "") // return generated pdf path
            //     if let viewWithTag = viewControler?.view.viewWithTag(100) {
            //         viewWithTag.removeFromSuperview() // remove hidden webview when pdf is generated
            //
            //         // clear WKWebView cache
            //         if #available(iOS 9.0, *) {
            //             WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            //                 records.forEach { record in
            //                     WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            //                 }
            //             }
            //         }
            //     }
            //
            //     // dispose WKWebView
            //     self.urlObservation = nil
            //     self.wkWebView = nil
            //     result(convertedFilePath)
            // }
        }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /**
   Creates temporary PDF document URL
   */
  private class var createdFileURL: URL {
      guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
          else { fatalError("Error getting user's document directory.") }

      let url = directory.appendingPathComponent("generatedPdfFile").appendingPathExtension("pdf")
      return url
  }
}
