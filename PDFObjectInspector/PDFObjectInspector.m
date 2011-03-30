//
//  PDFObjectInspector.m
//  PDFObjectInspector
//
//  Created by Jason Harwig on 3/30/11.
//  Copyright 2011 Near Infinity Corporation. All rights reserved.
//

#import "PDFObjectInspector.h"

void MyFunction (const char *key, CGPDFObjectRef object, void *info) 
{    
    NSMutableArray *keys = info;    
    NSString *keyStr = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];        
    [keys addObject:keyStr];        
}


@implementation PDFObjectInspector

@synthesize outlineView, objects;

- (NSString *)windowNibName
{
    return @"PDFObjectInspector";
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
    CGDataProviderRelease(provider);
    
    page = CGPDFDocumentGetPage(pdf, 1);
    CGPDFPageRetain(page);
    
    
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}



- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        CGPDFDictionaryRef dictionary = CGPDFPageGetDictionary(page);
        NSMutableArray *keys = [NSMutableArray array];
        CGPDFDictionaryApplyFunction(dictionary, MyFunction, keys);
        
        NSString *key = [keys objectAtIndex:index];
        CGPDFObjectRef obj;
        CGPDFDictionaryGetObject(dictionary, [key cStringUsingEncoding:NSUTF8StringEncoding], &obj);        
        NSValue *objVal = [NSValue valueWithBytes:&obj objCType:@encode(CGPDFObjectRef)];
        return [[NSArray arrayWithObjects:key, objVal, nil] retain];        
    }
    
    
    NSArray *comp = (NSArray *)item;
    NSValue *objVal = [comp objectAtIndex:1];
    CGPDFObjectRef obj;
    [objVal getValue:&obj];
    
    CGPDFArrayRef array;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeArray, &array)) {
        
        CGPDFObjectRef obj;
        CGPDFArrayGetObject(array, index, &obj);
        NSValue *objVal = [NSValue valueWithBytes:&obj objCType:@encode(CGPDFObjectRef)];
        return [[NSArray arrayWithObjects:[NSString stringWithFormat:@"%lu", index], objVal, nil] retain];    
    }
    
    CGPDFDictionaryRef dictionary;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeDictionary, &dictionary)) {
        NSMutableArray *keys = [NSMutableArray array];
        CGPDFDictionaryApplyFunction(dictionary, MyFunction, keys);
        NSString *key = [keys objectAtIndex:index];
        CGPDFObjectRef obj;
        CGPDFDictionaryGetObject(dictionary, [key cStringUsingEncoding:NSUTF8StringEncoding], &obj);   
        NSValue *objVal = [NSValue valueWithBytes:&obj objCType:@encode(CGPDFObjectRef)];
        return [[NSArray arrayWithObjects:key, objVal, nil] retain];     
    }
    
    CGPDFStreamRef stream;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeStream, &stream)) {
        CGPDFDictionaryRef dict = CGPDFStreamGetDictionary(stream);
        NSMutableArray *keys = [NSMutableArray array];
        CGPDFDictionaryApplyFunction(dict, MyFunction, keys);
        NSString *key = [keys objectAtIndex:index];
        CGPDFObjectRef obj;
        CGPDFDictionaryGetObject(dict, [key cStringUsingEncoding:NSUTF8StringEncoding], &obj);   
        NSValue *objVal = [NSValue valueWithBytes:&obj objCType:@encode(CGPDFObjectRef)];
        return [[NSArray arrayWithObjects:key, objVal, nil] retain];  
    }

    NSAssert(false, @"should not be here");
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {  
    NSArray *comp = (NSArray *)item;
    NSValue *objVal = [comp objectAtIndex:1];
    CGPDFObjectRef obj;
    [objVal getValue:&obj];
    
    CGPDFObjectType type = CGPDFObjectGetType((CGPDFObjectRef)obj);

    return type == kCGPDFObjectTypeDictionary || type == kCGPDFObjectTypeArray || type == kCGPDFObjectTypeStream;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        CGPDFDictionaryRef dictionary = CGPDFPageGetDictionary(page);
        return CGPDFDictionaryGetCount(dictionary);        
    }
    
    NSArray *comp = (NSArray *)item;
    NSValue *objVal = [comp objectAtIndex:1];
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
        CGPDFObjectRef obj;
        [objVal getValue:&obj];
        
        CGPDFObjectType type = CGPDFObjectGetType(obj);
        
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
@end
