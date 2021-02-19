#import <Foundation/Foundation.h>



void _getPageIndex(NSString *key, CGPDFObjectRef obj, NSArray *parent, NSMutableArray *set) {

    CGPDFDictionaryRef dictionary;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeDictionary, &dictionary)) {
        CGPDFReal count;
        if (CGPDFDictionaryGetNumber(dictionary, [@"Count" cStringUsingEncoding:NSASCIIStringEncoding], &count)) {
            
            // Has subtree, need to look at siblings with lower index and add all counts
            CGPDFObjectRef parentKids;
            [[parent objectAtIndex:1] getValue:&parentKids];
            CGPDFArrayRef kids;
            if (CGPDFObjectGetValue(parentKids, kCGPDFObjectTypeArray, &kids)) {
                float total = 0;
                CGPDFArrayApplyBlock(kids,  ^bool(size_t index, CGPDFObjectRef value, void *info) {

                    if (value == obj) return NO;
                    
                    CGPDFDictionaryRef pageDict;
                    if (CGPDFObjectGetValue(value, kCGPDFObjectTypeDictionary, &pageDict)) {
                        CGPDFReal count;
                        if (CGPDFDictionaryGetNumber(pageDict, [@"Count" cStringUsingEncoding:NSASCIIStringEncoding], &count)) {
                            *(float *)info = *(float *)info + count;
                        }
                    }
                                        
                    return YES;
                }, &total);
                [set addObject:[NSNumber numberWithInt:(int)total]];
            }
        } else {
            // Add this index to array;
            [set addObject:[NSNumber numberWithInt:[key intValue]]];
        }
    }
    
    // Get parent/parent, recurse
    NSArray *grandparent = [parent objectAtIndex:2];
    if (grandparent == nil) return;
    NSString *grandparentKey = [grandparent objectAtIndex:0];
    if ([grandparentKey isEqualToString:@"Pages"]) return;
    
    CGPDFObjectRef grandparentObj;
    [[grandparent objectAtIndex:1] getValue:&grandparentObj];
    
    return _getPageIndex(grandparentKey, grandparentObj, [grandparent objectAtIndex:2], set);
}

void getPageIndex(NSString *key, CGPDFObjectRef obj, NSArray *parent, int *pageNumber, int *pages) {
    NSMutableArray *set = [NSMutableArray array];
    _getPageIndex(key, obj, parent, set);
    
    int count = 1;
    CGPDFDictionaryRef dictionary;
    if (CGPDFObjectGetValue(obj, kCGPDFObjectTypeDictionary, &dictionary)) {
        CGPDFReal pageCount;
        if (CGPDFDictionaryGetNumber(dictionary, [@"Count" cStringUsingEncoding:NSASCIIStringEncoding], &pageCount)) {
            count = (int) pageCount;
        }
    }
   
    
    int page = 1;
    for (NSNumber *n in set) {
        page += [n intValue];
    }
    NSLog(@"Set %@ = %d +%d", set, page, count);
    
    *pageNumber = page;
    *pages = count;
}

// https://stackoverflow.com/a/2492305/98048
CGFloat *decodeValuesFromImageDictionary(CGPDFDictionaryRef dict, CGColorSpaceRef cgColorSpace, NSInteger bitsPerComponent) {
    CGFloat *decodeValues = NULL;
    CGPDFArrayRef decodeArray = NULL;

    if (CGPDFDictionaryGetArray(dict, "Decode", &decodeArray)) {
        size_t count = CGPDFArrayGetCount(decodeArray);
        decodeValues = malloc(sizeof(CGFloat) * count);
        CGPDFReal realValue;
        int i;
        for (i = 0; i < count; i++) {
            CGPDFArrayGetNumber(decodeArray, i, &realValue);
            decodeValues[i] = realValue;
        }
    } else {
        size_t n;
        switch (CGColorSpaceGetModel(cgColorSpace)) {
            case kCGColorSpaceModelMonochrome:
                decodeValues = malloc(sizeof(CGFloat) * 2);
                decodeValues[0] = 0.0;
                decodeValues[1] = 1.0;
                break;
            case kCGColorSpaceModelRGB:
                decodeValues = malloc(sizeof(CGFloat) * 6);
                for (int i = 0; i < 6; i++) {
                    decodeValues[i] = i % 2 == 0 ? 0 : 1;
                }
                break;
            case kCGColorSpaceModelCMYK:
                decodeValues = malloc(sizeof(CGFloat) * 8);
                for (int i = 0; i < 8; i++) {
                    decodeValues[i] = i % 2 == 0 ? 0.0 :
                    1.0;
                }
                break;
            case kCGColorSpaceModelLab:
                // ????
                break;
            case kCGColorSpaceModelDeviceN:
                n =
                CGColorSpaceGetNumberOfComponents(cgColorSpace) * 2;
                decodeValues = malloc(sizeof(CGFloat) * (n *
                                                         2));
                for (int i = 0; i < n; i++) {
                    decodeValues[i] = i % 2 == 0 ? 0.0 :
                    1.0;
                }
                break;
            case kCGColorSpaceModelIndexed:
                decodeValues = malloc(sizeof(CGFloat) * 2);
                decodeValues[0] = 0.0;
                decodeValues[1] = pow(2.0,
                                      (double)bitsPerComponent) - 1;
                break;
            default:
                break;
        }
    }

    return (CGFloat *)CFMakeCollectable(decodeValues);
}

NSImage* getImageRef(CGPDFStreamRef myStream) {
    CGPDFArrayRef colorSpaceArray = NULL;
    CGPDFStreamRef dataStream;
    CGPDFDataFormat format;
    CGPDFDictionaryRef dict;
    CGPDFInteger width, height, bps, spp;
    CGPDFBoolean interpolation = 0;
    //  NSString *colorSpace = nil;
    CGColorSpaceRef cgColorSpace;
    const char *name = NULL, *colorSpaceName = NULL, *renderingIntentName = NULL;
    CFDataRef imageDataPtr = NULL;
    CGImageRef cgImage;
    //maskImage = NULL,
    CGImageRef sourceImage = NULL;
    CGDataProviderRef dataProvider;
    CGColorRenderingIntent renderingIntent;
    CGFloat *decodeValues = NULL;
    
    if (myStream == NULL)
        return nil;

    dataStream = myStream;
    dict = CGPDFStreamGetDictionary(dataStream);

    // obtain the basic image information
    if (!CGPDFDictionaryGetName(dict, "Subtype", &name))
        return nil;

    if (strcmp(name, "Image") != 0)
        return nil;

    if (!CGPDFDictionaryGetInteger(dict, "Width", &width))
        return nil;

    if (!CGPDFDictionaryGetInteger(dict, "Height", &height))
        return nil;

    if (!CGPDFDictionaryGetInteger(dict, "BitsPerComponent", &bps))
        return nil;

    if (!CGPDFDictionaryGetBoolean(dict, "Interpolate", &interpolation))
        interpolation = NO;

    if (!CGPDFDictionaryGetName(dict, "Intent", &renderingIntentName))
        renderingIntent = kCGRenderingIntentDefault;
    else{
        renderingIntent = kCGRenderingIntentDefault;
        //      renderingIntent = renderingIntentFromName(renderingIntentName);
    }

    imageDataPtr = CGPDFStreamCopyData(dataStream, &format);
    dataProvider = CGDataProviderCreateWithCFData(imageDataPtr);
    CFRelease(imageDataPtr);

    if (CGPDFDictionaryGetArray(dict, "ColorSpace", &colorSpaceArray)) {
        cgColorSpace = CGColorSpaceCreateDeviceRGB();
        //      cgColorSpace = colorSpaceFromPDFArray(colorSpaceArray);
        spp = CGColorSpaceGetNumberOfComponents(cgColorSpace);
    } else if (CGPDFDictionaryGetName(dict, "ColorSpace", &colorSpaceName)) {
        if (strcmp(colorSpaceName, "DeviceRGB") == 0) {
            cgColorSpace = CGColorSpaceCreateDeviceRGB();
            //          CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
            spp = 3;
        } else if (strcmp(colorSpaceName, "DeviceCMYK") == 0) {
            cgColorSpace = CGColorSpaceCreateDeviceCMYK();
            //          CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);
            spp = 4;
        } else if (strcmp(colorSpaceName, "DeviceGray") == 0) {
            cgColorSpace = CGColorSpaceCreateDeviceGray();
            //          CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
            spp = 1;
        } else if (bps == 1) { // if there's no colorspace entry, there's still one we can infer from bps
            cgColorSpace = CGColorSpaceCreateDeviceGray();
            //          colorSpace = NSDeviceBlackColorSpace;
            spp = 1;
        } else {
            cgColorSpace = CGColorSpaceCreateDeviceRGB();
            spp = 3;
        }
    } else {
        cgColorSpace = CGColorSpaceCreateDeviceRGB();
        spp = 3;
    }

    decodeValues = decodeValuesFromImageDictionary(dict, cgColorSpace, bps);

    long rowBits = bps * spp * width;
    long rowBytes = rowBits / 8;
    // pdf image row lengths are padded to byte-alignment
    if (rowBits % 8 != 0)
        ++rowBytes;

//  maskImage = SMaskImageFromImageDictionary(dict);

    if (format == CGPDFDataFormatRaw)
    {
        sourceImage = CGImageCreate(width, height, bps, bps * spp, rowBytes, cgColorSpace, 0, dataProvider, decodeValues, interpolation, renderingIntent);
        CGDataProviderRelease(dataProvider);
        cgImage = sourceImage;
//      if (maskImage != NULL) {
//          cgImage = CGImageCreateWithMask(sourceImage, maskImage);
//          CGImageRelease(sourceImage);
//          CGImageRelease(maskImage);
//      } else {
//          cgImage = sourceImage;
//      }
    } else {
        if (format == CGPDFDataFormatJPEGEncoded){ // JPEG data requires a CGImage; AppKit can't decode it {
            sourceImage =
            CGImageCreateWithJPEGDataProvider(dataProvider,decodeValues,interpolation,renderingIntent);
            CGDataProviderRelease(dataProvider);
            cgImage = sourceImage;
//          if (maskImage != NULL) {
//              cgImage = CGImageCreateWithMask(sourceImage,maskImage);
//              CGImageRelease(sourceImage);
//              CGImageRelease(maskImage);
//          } else {
//              cgImage = sourceImage;
//          }
        }
        // note that we could have handled JPEG with ImageIO as well
        else if (format == CGPDFDataFormatJPEG2000) { // JPEG2000 requires ImageIO {
            CFDictionaryRef dictionary = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
            sourceImage=
            CGImageCreateWithJPEGDataProvider(dataProvider, decodeValues, interpolation, renderingIntent);


            //          CGImageSourceRef cgImageSource = CGImageSourceCreateWithDataProvider(dataProvider, dictionary);
            CGDataProviderRelease(dataProvider);

            cgImage=sourceImage;

            //          cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, dictionary);
            CFRelease(dictionary);
        } else // some format we don't know about or an error in the PDF
            return nil;
    }
    return [[[NSImage alloc] initWithCGImage:cgImage size:NSMakeSize(width, height)] autorelease];
}

