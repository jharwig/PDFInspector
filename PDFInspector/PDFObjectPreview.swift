import Cocoa

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
    
    func _setString(_ str: String) -> Void {
        if let v:NSScrollView = textScrollView {
            v.frame = self.bounds;
            
            textView?.string = str;
            
            textView?.textStorage?.beginEditing()
            
            textView?.textStorage?.addAttribute(.backgroundColor, value: NSColor.red, range: NSMakeRange(0, 10))
            
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

    
    func process(_ string: String) -> Void {
        let n = string.count
        textView?.textStorage?.removeAttribute(.backgroundColor, range: NSMakeRange(0, n))
        var foundArray: [String]?
        var addToArray = false
        var startIndex: Int?
//
        
//        var insert: [Any] = []
//        var insert: [] = []
        
        for (index, char) in string.enumerated() {
//        string.forEach {
//            let char = $0
//            let index = 0
//            print("\(index) \(char.) \(char.asciiValue)")
            if foundArray != nil {
                if (char.isASCII && char.asciiValue == 10) {
                    //if (foundArray?.joined().range(of: #"^\s*$"#, options: .regularExpression) == nil) {
                        print("done \(startIndex!)-\(index) \"\(foundArray?.joined() ?? "unknown")\"")
                        
//                        if (index < 39453) {
                        textView?.textStorage?.addAttribute(.backgroundColor, value: NSColor.red, range: NSMakeRange(startIndex!, index - startIndex!))
//                        }
                    //}
                    foundArray = nil
                    addToArray = false
                }
                switch char {
//                    case " ":
//                    print("r EOL \(index)")
                                   
                    case "(": addToArray = true
                    case ")": addToArray = false
                    default:
                        if (addToArray) {
                            foundArray?.append("\(char)")
                        }
                }
            } else if (char == "[") {
                foundArray = []
                startIndex = index
            }
        }
            
        
            //unichar c = [string characterAtIndex:i];
//            if (c == '\\') {
//                [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor lightGrayColor] range:NSMakeRange(i, 1)];
//                i++;
//            } else if (c == '$') {
//                NSUInteger l = ((i < n - 1) && isdigit([string characterAtIndex:i+1])) ? 2 : 1;
//                [textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(i, l)];
//                i++;
//            }
//        }
    }
}
