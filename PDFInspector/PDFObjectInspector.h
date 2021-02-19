#import <Cocoa/Cocoa.h>

@class PDFObjectPreview;

@interface PDFObjectInspector : NSDocument<NSOutlineViewDataSource> {
@private
    CGPDFDocumentRef pdf;
    NSOutlineView *outlineView;
    PDFObjectPreview *previewView;
    NSSplitView *splitView;
    NSView *view;
}
@property (assign) IBOutlet NSOutlineView *outlineView;
@property (assign) IBOutlet PDFObjectPreview *previewView;
@property (assign) IBOutlet NSSplitView *splitView;
@property (assign) IBOutlet NSView *view;

@end
