#import "PDFObjectInspector.h"
#import "PDFInspector-Swift.h"
#import "PDFUtil.h"

void CollectKeys(const char *key, CGPDFObjectRef object, void *info)
{    
    NSMutableArray *keys = info;    
    NSString *keyStr = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];        
    [keys addObject:keyStr];        
}

void CollectKeysCFDict(const void *key, const void *value, void *context) {
    NSMutableArray *keys = context;
    //NSString *keyStr = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
    [keys addObject:(NSString *)key];
}

@implementation PDFObjectInspector

@synthesize outlineView, previewView, splitView, view;

- (NSString *)windowNibName
{
    return @"PDFObjectInspector";
}

- (void)dealloc
{
    CGPDFDocumentRelease(pdf);
    [pdfDocument release];
    outlineView = nil;
    previewView = nil;
    [super dealloc];
}

- (BOOL) isInViewingMode {
    return YES;
}

- (NSString *)defaultDraftName {
    return @"PDF Inspector";
}

- (void)awakeFromNib {
    if (pdf) {
        self.splitView.frame = self.view.bounds;
        [self.view setSubviews:[NSArray array]];
        [self.view addSubview:self.splitView];      
    }
}

- (void) handleUrl:(NSString *)urlStr {
    NSURL *url = [NSURL URLWithString:urlStr];
    
    [self.view.window setTitle:[url lastPathComponent]];    
    
    CGPDFDocumentRelease(pdf);
    [pdfDocument release];

    CGDataProviderRef provider = CGDataProviderCreateWithURL((CFURLRef)url);
    pdf = CGPDFDocumentCreateWithProvider(provider);
    pdfDocument = [[PDFDocument alloc] initWithURL:url];
    CGDataProviderRelease(provider);
    
    [self.outlineView reloadData];
    [self.outlineView collapseItem:nil];
    [self.previewView setText:nil];
    self.splitView.frame = self.view.bounds;
    [self.view setSubviews:[NSArray array]];
    [self.view addSubview:self.splitView];
}

- (void) hovering:(BOOL) hovering {
    self.view.layer.borderColor = [[[NSColor controlAccentColor] colorWithAlphaComponent:0.5] CGColor];
    self.view.layer.borderWidth = hovering ? 5 : 0;
   
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    pdf = CGPDFDocumentCreateWithProvider(provider);
    pdfDocument = [[PDFDocument alloc] initWithData:data];
    CGDataProviderRelease(provider);
       
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    
  
    return YES;
}


#pragma mark - Outline View DataSource

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        NSString *key;
        NSValue *objVal;
        switch (index) {
            case 0:
                key = @"Info";
                CGPDFDictionaryRef info = CGPDFDocumentGetInfo(pdf);
                objVal = [NSValue valueWithBytes:&info objCType:@encode(CGPDFDictionaryRef)];
                break;
            case 1:
                key = @"Catalog";
                CGPDFDictionaryRef catalog = CGPDFDocumentGetCatalog(pdf);
                
                objVal = [NSValue valueWithBytes:&catalog objCType:@encode(CGPDFDictionaryRef)];
                break;
            case 2:
                key = @"Outline";
                CFDictionaryRef outline = CGPDFDocumentGetOutline(pdf);
                objVal = [NSValue valueWithBytes:&outline objCType:@encode(CFDictionaryRef)];
                break;
        }
        
        return [NSArray arrayWithObjects:key, objVal, [NSNull null], [NSNumber numberWithLong:index], nil];
    }
    
    
    NSArray *comp = (NSArray *)item;
    NSValue *objVal = [comp objectAtIndex:1];
    id parent = item;
    
    if ([objVal isKindOfClass:[NSDictionary class]]) {
        NSDictionary *d = (NSDictionary *)objVal;
        NSString *key = [[d allKeys] objectAtIndex:index];
        id value = [d objectForKey:key];
        return [[NSArray arrayWithObjects:key, value, parent, nil] retain];
    }
    if ([objVal isKindOfClass:[NSArray class]]) {
        return [[NSArray arrayWithObjects:[NSString stringWithFormat:@"%lu", index], [(NSArray *)objVal objectAtIndex:index], parent, nil] retain];
    }
    
    BOOL isDictionary = [comp count] == 4 && [[comp objectAtIndex:2] isEqual:[NSNull null]];
    
    // Is Outline
    if (isDictionary && [[comp objectAtIndex:3] intValue] == 2) {
        CFDictionaryRef dictionary;
        [objVal getValue:&dictionary];
        NSDictionary *d = (NSDictionary *)dictionary;
        NSMutableArray *keys = [NSMutableArray array];
        CFDictionaryApplyFunction(dictionary, CollectKeysCFDict, keys);
        NSString *key = [keys objectAtIndex:index];
//        NSValue *value = [NSValue valueWithPointer:CFDictionaryGetValue(dictionary, key)];
        return [[NSArray arrayWithObjects:key, d, parent, nil] retain];
    }
    
    CGPDFObjectRef obj;
    [objVal getValue:&obj];
    
    CGPDFArrayRef array;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeArray, &array)) {
        CGPDFObjectRef obj;
        CGPDFArrayGetObject(array, index, &obj);
        NSValue *objVal = [NSValue valueWithBytes:&obj objCType:@encode(CGPDFObjectRef)];
        return [[NSArray arrayWithObjects:[NSString stringWithFormat:@"%lu", index], objVal, parent, nil] retain];
    }
    
    CGPDFDictionaryRef dictionary;
    if (isDictionary || CGPDFObjectGetValue(obj, kCGPDFObjectTypeDictionary, &dictionary)) {
        if (isDictionary) {
            [objVal getValue:&dictionary];
        }
        NSMutableArray *keys = [NSMutableArray array];
        CGPDFDictionaryApplyFunction(dictionary, CollectKeys, keys);
        NSString *key = [keys objectAtIndex:index];
        if ([key isEqualToString:@"Parent"]) {
            return [[NSArray arrayWithObjects:key, [NSNull null], parent, nil] retain];
        }
        CGPDFObjectRef obj;
        CGPDFDictionaryGetObject(dictionary, [key cStringUsingEncoding:NSUTF8StringEncoding], &obj);   
        NSValue *objVal = [NSValue valueWithBytes:&obj objCType:@encode(CGPDFObjectRef)];
        return [[NSArray arrayWithObjects:key, objVal, parent, nil] retain];
    }
    
    CGPDFStreamRef stream;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeStream, &stream)) {
        CGPDFDictionaryRef dict = CGPDFStreamGetDictionary(stream);
        NSMutableArray *keys = [NSMutableArray array];
        CGPDFDictionaryApplyFunction(dict, CollectKeys, keys);
        NSString *key = [keys objectAtIndex:index];
        CGPDFObjectRef obj;
        CGPDFDictionaryGetObject(dict, [key cStringUsingEncoding:NSUTF8StringEncoding], &obj);   
        NSValue *objVal = [NSValue valueWithBytes:&obj objCType:@encode(CGPDFObjectRef)];
        return [NSArray arrayWithObjects:key, objVal, parent, nil];
    }

    NSAssert(false, @"should not be here");
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {  
    NSArray *comp = (NSArray *)item;
    id value =[comp objectAtIndex:1];
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
        return YES;
    }
    
    NSValue *objVal = value;
    
    if ([objVal isEqualTo:[NSNull null]]) return NO;
    if ([objVal isKindOfClass:[NSString class]]) return NO;
    if ([objVal isKindOfClass:[NSNumber class]]) return NO;
    
    if ([comp count] == 4 && [[comp objectAtIndex:2] isEqual:[NSNull null]]) {
        if ([[comp objectAtIndex:3] intValue] == 2) {
            CFDictionaryRef dict;
            [objVal getValue:&dict];
            return dict != nil;
        }
        return YES;
    }

    CGPDFObjectRef obj;
    [objVal getValue:&obj];
    
    CGPDFObjectType type = CGPDFObjectGetType((CGPDFObjectRef)obj);

    return type == kCGPDFObjectTypeDictionary || type == kCGPDFObjectTypeArray || type == kCGPDFObjectTypeStream;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return 3; // info + catalog + outline
    }
    
    NSArray *comp = (NSArray *)item;
    NSValue *objVal = [comp objectAtIndex:1];
    
    if ([objVal isKindOfClass:[NSDictionary class]]) return [(NSDictionary *)objVal count];
    if ([objVal isKindOfClass:[NSArray class]]) return [(NSArray*) objVal count];
    
    if ([comp count] == 4 && [[comp objectAtIndex:2] isEqual:[NSNull null]]) {
        
        NSInteger index = [(NSNumber *)[comp objectAtIndex:3] intValue];
        // Info, Catalog
        if (index < 2) {
            CGPDFDictionaryRef dict;
            [objVal getValue:&dict];
            return CGPDFDictionaryGetCount(dict);
        } else {
            CFDictionaryRef dict;
            [objVal getValue:&dict];
            return CFDictionaryGetCount(dict);
        }
    }
    
    CGPDFObjectRef obj;
    [objVal getValue:&obj];
    
    CGPDFArrayRef array;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeArray, &array)) {
        return CGPDFArrayGetCount(array);
    }
    
    CGPDFDictionaryRef dictionary;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeDictionary, &dictionary)) {
        return CGPDFDictionaryGetCount(dictionary);
    }
    
    CGPDFStreamRef stream;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeStream, &stream)) {
        CGPDFDictionaryRef dict = CGPDFStreamGetDictionary(stream);
        return CGPDFDictionaryGetCount(dict);
    }

    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    
    NSArray *comp = (NSArray *)item;
    if ([[tableColumn identifier] isEqual:@"key"]) {
        return [comp objectAtIndex:0];
    } else if ([[tableColumn identifier] isEqual:@"value"]) {
        NSValue *objVal = [comp objectAtIndex:1];
        if ([objVal isEqualTo:[NSNull null]]) return @"recursive";
        if ([objVal isKindOfClass:[NSString class]]) return objVal;
        if ([objVal isKindOfClass:[NSDictionary class]]) return @"Dictionary";
        if ([objVal isKindOfClass:[NSArray class]]) return @"Array";
        if ([objVal isKindOfClass:[NSNumber class]]) return [objVal description];
                 
        CGPDFObjectRef obj;
        [objVal getValue:&obj];
        CGPDFObjectType type = CGPDFObjectGetType(obj);
        
        if ([comp count] == 4 && [[comp objectAtIndex:2] isEqual:[NSNull null]]) {
            if ([[comp objectAtIndex:3] intValue] == 2) return nil;
            type = kCGPDFObjectTypeDictionary;
        }
        
        CGPDFBoolean boolean;
        if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeBoolean, &boolean)) {
            return boolean == 0 ? @"false" : @"true";
        }
        
        CGPDFReal real;
        if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeReal, &real)) {
            return [NSString stringWithFormat:@"%f", real];
        }
        
        CGPDFInteger integer;
        if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeInteger, &integer)) {
            return [NSString stringWithFormat:@"%li", integer];
        }

        CGPDFStringRef string;
        if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeString, &string)) {
            return (NSString *) CGPDFStringCopyTextString(string);
        }        
              
        const char *name;
        if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeName, &name)) {
            return [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        }
        
        return  type == kCGPDFObjectTypeDictionary ? @"Dictionary" : 
            type == kCGPDFObjectTypeArray ? @"Array" : 
            type == kCGPDFObjectTypeStream ? @"Stream" : 
            [NSString stringWithFormat:@"type = %i", type];
    }
    
    return @"";
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSInteger rowIndex = [outlineView selectedRow];
    NSArray *item = [outlineView itemAtRow:rowIndex];
    NSString *key = [item objectAtIndex:0];
    NSValue *value = [item objectAtIndex:1];
    NSArray *parent = [item objectAtIndex:2];
    
    if (key == nil) return;
    if ([value isEqualTo:[NSNull null]]) return;
    if ([parent isEqualTo:[NSNull null]]) return;
    if ([value isKindOfClass:[NSString class]]) return;
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSLog(@"%@", value);
        return;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSLog(@"%@", value);
        return;
    }
    
    CGPDFObjectRef obj;
    [value getValue:&obj];
    CGPDFStreamRef stream;
    
    BOOL isPage = [[parent objectAtIndex:0] isEqualToString:@"Kids"];

    if (isPage) {

        int index, count;
        getPageIndex(key, obj, parent, &index, &count);
        if (count == 0) {
            [previewView setImage:nil];
            return;
        }
        NSLog(@"Display %d more", count - 1);
        CGPDFPageRef page = CGPDFDocumentGetPage(pdf, index);
        if (page == nil) {
            NSLog(@"No page found");
            [previewView setImage:nil];
            return;
        }
        
        
        CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        
        if (CGSizeEqualToSize(pageRect.size, CGSizeZero)) {
            NSLog(@"No size for page");
            [previewView setImage:nil];
            return;
        }
        
        NSImage *image = [[NSImage alloc] initWithSize:pageRect.size];
        [image lockFocus];
        CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
        
        PDFPage *pdfPageForDisplay = [pdfDocument pageAtIndex:index - 1];
                CGContextSaveGState(context);
                CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
                CGContextFillRect(context, pageRect);
        [pdfPageForDisplay drawWithBox:kPDFDisplayBoxCropBox toContext:context];
        CGContextRestoreGState(context);
        
        [image unlockFocus];
        
        [previewView setImage:image];
        [image release];
        
    } else if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeStream, &stream)) {
        CGPDFDictionaryRef dict = CGPDFStreamGetDictionary(stream);
        CGPDFDataFormat format;
        NSData *streamData = (NSData *) CGPDFStreamCopyData(stream, &format);
        const char * string;
        NSString *subType = nil;
        
        if (CGPDFDictionaryGetName(dict, [@"Subtype" cStringUsingEncoding:NSASCIIStringEncoding], &string)) {
            subType = [NSString stringWithCString:string encoding:NSASCIIStringEncoding];
        }
        
        if ([subType isEqualToString:@"Image"]) {//} || format != CGPDFDataFormatRaw) {
            NSImage *image = getImageRef(stream);
            [previewView setImage:image];
        } else {
            NSString *str = [[[NSString alloc] initWithData:streamData encoding:NSASCIIStringEncoding] autorelease];
            [previewView setText:str];
        }
        [streamData release];
    }
}

@end
