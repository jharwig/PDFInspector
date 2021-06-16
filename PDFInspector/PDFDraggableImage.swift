//
//  PDFDraggableImage.swift
//  PDFInspector
//
//  Created by Jason Harwig on 5/25/21.
//

import Cocoa

class PDFDraggableImage: NSImageView, NSDraggingSource {
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return NSDragOperation.copy
    }
    
    var mouseDownEvent: NSEvent?
   
    override func mouseDown(with theEvent: NSEvent) {
        mouseDownEvent = theEvent
    }

        // Track mouse dragged events to handle dragging sessions.
        override func mouseDragged(with event: NSEvent) {

            // Calculate the dragging distance...
            let mouseDown = mouseDownEvent!.locationInWindow
            let dragPoint = event.locationInWindow
            let dragDistance = hypot(mouseDown.x - dragPoint.x, mouseDown.y - dragPoint.y)

            // Cancel the dragging session in case of an accidental drag.
            if dragDistance < 3 {
                return
            }

            guard let image = self.image else {
                return
            }

//            // Do some math to properly resize the given image.
//            let size = NSSize(width: log10(image.size.width) * 30, height: log10(image.size.height) * 30)
//
//
//            if let draggingImage = image.resize(toSize: size, aspectMode: .fit) {

                    
                // Create a new NSDraggingItem with the image as content.
                let draggingItem = NSDraggingItem(pasteboardWriter: image)

                // Calculate the mouseDown location from the window's coordinate system to the
                // ImageView's coordinate system, to use it as origin for the dragging frame.
                let draggingFrameOrigin = convert(mouseDown, from: nil)
                // Build the dragging frame and offset it by half the image size on each axis
                // to center the mouse cursor within the dragging frame.
                let draggingFrame = NSRect(origin: draggingFrameOrigin, size: image.size)
                    .offsetBy(dx: -image.size.width / 2, dy: -image.size.height / 2)

                // Assign the dragging frame to the draggingFrame property of our dragging item.
                draggingItem.draggingFrame = draggingFrame

                // Provide the components of the dragging image.
                draggingItem.imageComponentsProvider = {
                    let component = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.icon)

                    component.contents = image
                    component.frame = NSRect(origin: NSPoint(), size: draggingFrame.size)
                    return [component]
                }

                // Begin actual dragging session. Woohow!
                beginDraggingSession(with: [draggingItem], event: mouseDownEvent!, source: self)
//            }
//        }
    }
}
