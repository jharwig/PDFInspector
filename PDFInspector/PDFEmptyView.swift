import Cocoa

@objc protocol PDFEmptyViewDelegate {
    func hovering(_: Bool)
    func handleUrl(_: String)
}

class PDFEmptyView: NSView {
    
    @IBOutlet
    @objc public var delegate: PDFEmptyViewDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        delegate?.hovering(true)
        return .link
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        delegate?.hovering(false)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        delegate?.hovering(false)
        if let file:String = sender.draggingPasteboard.propertyList(forType: .fileURL) as? String {
            print(file)
            delegate?.handleUrl(file)
            return true
        }
        return false
    }
    
}
