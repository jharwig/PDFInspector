#import <Cocoa/Cocoa.h>
#import <PDFKit/PDFKit.h>

@class PDFObjectPreview;

@interface PDFObjectInspector : NSDocument<NSOutlineViewDataSource> {
@private
    CGPDFDocumentRef pdf;
    PDFDocument *pdfDocument;
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
