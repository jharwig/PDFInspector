//
//  PDFObjectInspector.h
//  PDFObjectInspector
//
//  Created by Jason Harwig on 3/30/11.
//  Copyright 2011 Near Infinity Corporation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PDFObjectInspector : NSDocument<NSOutlineViewDataSource> {
    
    NSMutableDictionary *objects;
    
@private
    CGPDFDocumentRef pdf;
    CGPDFPageRef page;
    NSOutlineView *outlineView;
}
@property (assign) IBOutlet NSOutlineView *outlineView;

@property (nonatomic, retain) NSMutableDictionary *objects;

@end
