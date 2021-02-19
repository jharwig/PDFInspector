//
//  PDFUtil.h
//  PDFInspector
//
//  Created by Jason Harwig on 6/22/20.
//

#ifndef PDFUtil_h
#define PDFUtil_h

void getPageIndex(NSString *key, CGPDFObjectRef obj, NSArray *parent, int *pageNumber, int *pages);

NSImage* getImageRef(CGPDFStreamRef myStream);

#endif /* PDFUtil_h */
