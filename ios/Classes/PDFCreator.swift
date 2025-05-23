import UIKit

class PDFCreator {
    
    /**
     Creates a PDF using the given print formatter and saves it to the user's document directory.
     - returns: The generated PDF path.
     */
    class func create(printFormatter: UIPrintFormatter, width: Double, height: Double, margins: [Int]?) -> URL {
        // assign paperRect and printableRect values
        let page = CGRect(x: 0, y: 0, width: width, height: height)

        let printable: CGRect
        if let margins = margins {
            printable = CGRect(
                x: CGFloat(margins[1]),           // left margin
                y: CGFloat(margins[0]),           // top margin
                width: width - CGFloat(margins[1] + margins[2]),  // width minus left and right margins
                height: height - CGFloat(margins[0] + margins[3]) // height minus top and bottom margins
            )
        } else {
            printable = page
        }

        // assign the print formatter to the print page renderer
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        renderer.setValue(page, forKey: "paperRect")
        renderer.setValue(printable, forKey: "printableRect")

        // create pdf context and draw each page
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, page, nil)

        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage() // Let the system handle page setup
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }

        UIGraphicsEndPDFContext();

        guard nil != (try? pdfData.write(to: createdFileURL, options: .atomic))
            else { fatalError("Error writing PDF data to file.") }

        return createdFileURL;
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

    /**
     Search for matches in provided text
     */
    private class func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}
