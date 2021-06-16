import Cocoa
import PDFKit

@IBDesignable

@objc public class PDFObjectPreview: NSView, NSTextViewDelegate {

    @IBOutlet var imageView: NSImageView?
    @IBOutlet var textScrollView: NSScrollView?
    @IBOutlet var textView: NSTextView?
    
   
    
    
    @objc public func setText(_ text:String?) -> Void {
        self.subviews.removeAll()
        if let x = text {
            _setString(x)
        }
    }
    @objc public func setImage(_ image:NSImage?) -> Void {
        self.subviews.removeAll()
        if let i = image {
            _setImage(i)
        }
    }
    @objc public func setPage(_ page:PDFPage?) -> Void {
        self.subviews.removeAll()
        if let p = page {
            _setPage(p)
        }
    }
    
    func _setString(_ str: String) -> Void {
        if let v:NSScrollView = textScrollView {
            v.frame = self.bounds;
            
            textView?.string = str;
            
            textView?.textStorage?.beginEditing()
            process(str);
            textView?.textStorage?.endEditing()
            subviews.append(v);
        }
    }
    
    func _setImage(_ image: NSImage) -> Void {
        if let v:NSImageView = imageView {
            v.frame = self.bounds;
            v.image = image;
        
            subviews.append(v);            
        }
    }
    
    func _setPage(_ page: PDFPage) -> Void {
       // page.draw(with: .cropBox, to: <#T##CGContext#>)
    }

    
    func process(_ string: String) -> Void {
        let n = string.count
        textView?.textStorage?.removeAttribute(.backgroundColor, range: NSMakeRange(0, n))
        var stringArray: [String]?
        var addToArray = false
        var startIndex: Int?
        
        for (index, char) in string.enumerated() {
            switch char {

                case "(":
                    addToArray = true
                    stringArray = []
                    startIndex = index + 1
                    
                case ")":
                    if let a = stringArray {
                        if (a.count > 0) {
                            let str = stringArray?.joined() ?? ""
                            let attributes: [NSAttributedString.Key: Any] = [
                                .backgroundColor: NSColor.yellow,
                                .toolTip: str
                            ]
                            let range = NSMakeRange(startIndex!, index - startIndex!)
                            textView?.textStorage?.addAttributes(attributes, range: range)
                        }
                    }
                    addToArray = false
                    stringArray = nil
                default:
                    if (addToArray) {
                        stringArray?.append("\(char)")
                    }
            }
        }
    }
}
