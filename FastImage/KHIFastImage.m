//
//  FastImage.m
//
//  Copyright (c) 2014 Kyle Hickinson. All rights reserved.
//

#import "KHIFastImage.h"

// There must be something like this already made in CoreFoundation/Foundation... right?
// I guess I could also use NSLocationInRange, but still...
#define _FIValueBetween(value, min, max) ({ \
  __typeof__(value) __value = (value); \
  __typeof__(min) __min = (min); \
  __typeof__(max) __max = (max); \
  __value >= __min && __value <= __max; \
})

/**
 Internal object to track each request
 */
@interface _KHIFIRequest : NSObject

@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, copy) NSMutableData *data;

@property (nonatomic, copy) KHIFastImageCompletionBlock completionBlock;

@end

@implementation _KHIFIRequest

- (instancetype)init
{
  if ((self = [super init])) {
    _data = [[NSMutableData alloc] init];
  }
  return self;
}

@end

#pragma mark -

@interface KHIFastImage () <NSURLSessionDataDelegate> {
  NSMutableDictionary *_requests;
  NSURLSession *_session;
}

@end

@implementation KHIFastImage

- (instancetype)init
{
  if ((self = [super init])) {
    _requestTimeout = 2.0f;
    _requests = [[NSMutableDictionary alloc] init];
    _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]
                                             delegate:self
                                        delegateQueue:nil];
  }
  return self;
}

- (NSURLSessionDataTask *)imageSizeAndTypeForURL:(NSURL *)URL completion:(KHIFastImageCompletionBlock)completion
{
  NSParameterAssert(URL);
  
  NSString *URLString = [URL absoluteString];
  
  // Check to see if this URL is already being parsed.
  if (_requests[URLString]) {
    return ((_KHIFIRequest *)_requests[URLString]).task;
  }
   
  NSURLRequest *request = [NSURLRequest requestWithURL:URL
                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                       timeoutInterval:self.requestTimeout];
  
  NSURLSessionDataTask *task = [_session dataTaskWithRequest:request];
  
  _KHIFIRequest *imageRequest = [[_KHIFIRequest alloc] init];
  imageRequest.task = task;
  imageRequest.completionBlock = completion;
  _requests[URLString] = imageRequest;
  
  [task resume];
  return task;
}

#pragma mark -

- (BOOL)parseRequest:(_KHIFIRequest *)request
{
  NSData *data = request.data;//[request.data copy];
  
  // Get the type
  KHIFastImageType type = [self typeForImageData:data];
  if (type != KHIFastImageTypeUnsupported) {
    // Get the size
    CGSize imageSize = CGSizeZero;
    
    switch (type) {
      case KHIFastImageTypeUnsupported:
        return NO;
        break;
        
      case KHIFastImageTypeGIF:
        imageSize = [self sizeForGIFWithData:data];
        break;
        
      case KHIFastImageTypePNG:
        imageSize = [self sizeForPNGWithData:data];
        break;
        
      case KHIFastImageTypeJPEG: {
        imageSize = [self sizeForJPEGWithData:data];
        break;
      }
      case KHIFastImageTypeBMP:
        imageSize = [self sizeForBMPWithData:data];
        break;
    }
    
    if (request.completionBlock) {
      if (CGSizeEqualToSize(imageSize, CGSizeZero)) {
        return NO;
      } else {
        request.completionBlock(imageSize, type, nil);
      }
    }
  }
  
  return YES;
}

- (KHIFastImageType)typeForImageData:(NSData *)data
{
  // Grab the first 2 bytes to determine type
  UInt16 sample = 0;
  [data getBytes:&sample length:2];
  
  switch (CFSwapInt16BigToHost(sample)) {
    case 0x4749:
      return KHIFastImageTypeGIF;
    case 0xFFD8:
      return KHIFastImageTypeJPEG;
    case 0x8950:
      return KHIFastImageTypePNG;
    case 0x424D:
      return KHIFastImageTypeBMP;
  }
  
  return KHIFastImageTypeUnsupported;
}

#pragma mark - Parse Size

- (CGSize)sizeForGIFWithData:(NSData *)data
{
  // GIF parsing is very simple, the first 6 bytes contain header information, starting with 'GIF' and the version
  // The next 4 bytes are image width and image height in little endian. Done.
  
  struct {
    UInt16 width;
    UInt16 height;
  } gif_size;
  
  [data getBytes:&gif_size range:NSMakeRange(6, 4)];
  
  return CGSizeMake(gif_size.width, gif_size.height);
}

- (CGSize)sizeForPNGWithData:(NSData *)data
{
  // PNG is also simple: 8 byte header, next just read the first chunk (IHDR).
  // Chunks have the format:
  //  4 bytes - length
  //  4 bytes - type
  //  X bytes - data
  //  4 bytes - CRC
  // meaning the first chunk is located at offset 8 and the data begins at 16.
  // the width and height are stored as 32 bit unsigned integers (big-endian)
  struct {
    UInt32 width; // Big-endian
    UInt32 height; // Big-endian
  } png_size;
  
  [data getBytes:&png_size range:NSMakeRange(16, 8)];
  
  return CGSizeMake(CFSwapInt32BigToHost(png_size.width), CFSwapInt32BigToHost(png_size.height));
}

- (CGSize)sizeForJPEGWithData:(NSData *)data
{
  // JPEG parsing is a bit more elaborate then the others as the data we're looking for comes after
  // many different variably-sized data structures
  //
  // ELI5: JPEG file data structure includes a bunch of headers which mark certain type of info,
  // we want to find the header that holds the size.
  
  typedef NS_ENUM(NSInteger, _FIJPEGState) {
    _FIJPEGStateFindHeader,
    _FIJPEGStateDetermineFrameType,
    _FIJPEGStateSkipFrame,
    _FIJPEGStateFoundSOF,
    _FIJPEGStateFoundEOI
  };
  
  // Note: Height data comes before width data.  Also both are big-endian
  struct {
    UInt16 height; // Big-endian
    UInt16 width; // Big-endian
  } jpeg_size;
  
  // Start at offset 2 (knowing we already passed the first two bytes determining that this is a JPEG file)
  _FIJPEGState state = _FIJPEGStateFindHeader;
  UInt32 offset = 2;
  
  // Loop until we find what we want
  while (offset < data.length) {
    switch (state) {
        
      case _FIJPEGStateFindHeader: {
        // Find a table header. These are denoted by the bytes `FFXX`, where XX denotes the type of data in that
        // data table. If we parse this correctly, this loop will only run once.
        
        UInt8 sample = 0;
        while (sample != 0xFF) {
          if (offset < data.length) {
            [data getBytes:&sample range:NSMakeRange(offset, 1)];
            offset++;
          } else {
            // If we parsed the whole chuck of data and couldn't find it?...
            // Not enough data or a corrupted JPEG. Should error out here
            return CGSizeZero;
          }
        }
        
        // Move to determine the type of the table
        state = _FIJPEGStateDetermineFrameType;
        break;
      }
        
      case _FIJPEGStateDetermineFrameType: {
        // We've found a data marker, now we determine what type of data we're looking at.
        // FF E0 -> FF EF are 'APPn', and include lots of metadata like JFIF, EXIF, etc.
        //
        // What we want to find is one of the SOF (Start of Frame) header, cause' it includes
        // width and height (what we want!)
        //
        // JPEG Metadata Header Table
        // http://www.xbdev.net/image_formats/jpeg/tut_jpg/jpeg_file_layout.php
        //
        // Start of Frame headers:
        //
        //    FF C0 - SOF0  - Baseline
        //    FF C1 - SOF1  - Extended sequential
        //    FF C2 - SOF2  - Progressive
        //    FF C3 - SOF3  - Loseless
        //
        //    FF C5 - SOF5  - Differential sequential
        //    FF C6 - SOF6  - Differential progressive
        //    FF C7 - SOF7  - Differential lossless
        //    FF C9 - SOF9  - Extended sequential, arithmetic coding
        //
        //    FF CA - SOF10 - Progressive, arithmetic coding
        //    FF CB - SOF11 - Lossless, arithmetic coding
        //
        //    FF CD - SOF13 - Differential sequential, arithmetic coding
        //    FF CE - SOF14 - Differential progressive, arithmetic coding
        //    FF CF - SOF15 - Differential lossless, arithmetic coding
        //
        // Each of these SOF data markers have the same data structure:
        // struct {
        //   UInt16 header; // e.g. FFC0
        //   UInt16 frameLength;
        //   UInt8 samplePrecision;
        //   UInt16 imageHeight;
        //   UInt16 imageWidth;
        //   ... // we only care about this part
        // }
        
        UInt8 sample = 0;
        [data getBytes:&sample range:NSMakeRange(offset, 1)];
        offset++;
        
        // Technically we should check if this has EXIF data here (looking for FFE1 marker)…
        // Maybe TODO later
        if (_FIValueBetween(sample, 0xE0, 0xEF)) {
          state = _FIJPEGStateSkipFrame;
          
        } else if (_FIValueBetween(sample, 0xC0, 0xC3) ||
                   _FIValueBetween(sample, 0xC5, 0xC7) ||
                   _FIValueBetween(sample, 0xC9, 0xCB) ||
                   _FIValueBetween(sample, 0xCD, 0xCF)) {
          state = _FIJPEGStateFoundSOF;
          
        } else if (sample == 0xFF) {
          state = _FIJPEGStateDetermineFrameType;
          
        } else if (sample == 0xD9) {
          // We made it to the end of the file somehow without finding the size? Likely a corrupt file
          state = _FIJPEGStateFoundEOI;
          
        } else {
          // Since we don't handle every header case default to skipping an unknown data marker
          state = _FIJPEGStateSkipFrame;
          
        }
        
        break;
      }
        
      case _FIJPEGStateSkipFrame: {
        UInt16 frameLength = 0;
        [data getBytes:&frameLength range:NSMakeRange(offset, 2)];
        frameLength = CFSwapInt16BigToHost(frameLength);
        
        offset += (frameLength - 1);
        state = _FIJPEGStateFindHeader;
        break;
      }
        
      case _FIJPEGStateFoundSOF: {
        offset += 3; // Skip the frame length and sample precision, see above ^
        [data getBytes:&jpeg_size range:NSMakeRange(offset, 4)];
        return CGSizeMake(CFSwapInt16BigToHost(jpeg_size.width), CFSwapInt16BigToHost(jpeg_size.height));
      }
        
      case _FIJPEGStateFoundEOI: {
        return CGSizeZero;
      }
    }
  }
  
  return CGSizeZero;
}

- (CGSize)sizeForBMPWithData:(NSData *)data
{
  // BMP file structure 
  //
  UInt8 frameLength = 0;
  [data getBytes:&frameLength range:NSMakeRange(14, 1)];
  
  if (frameLength == 40) {
    struct {
      SInt32 width;
      SInt32 height;
    } bmp_size;
    
    [data getBytes:&bmp_size range:NSMakeRange(18, 8)];
    return CGSizeMake(bmp_size.width, abs(bmp_size.height));
    
  } else {
    struct {
      UInt16 width;
      UInt16 height;
    } bmp_size;
    
    [data getBytes:&bmp_size range:NSMakeRange(18, 4)];
    return CGSizeMake(bmp_size.width, bmp_size.height);
  }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
  NSString *URLString = [dataTask.originalRequest.URL absoluteString];
  
  _KHIFIRequest *request = _requests[URLString];
  if (request) {
    [request.data appendData:data];
    
    if (request.data.length > 0) {
      if ([self parseRequest:request]) {
        [request.task cancel];
        [_requests removeObjectForKey:URLString];
      }
    }
  }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  NSString *URLString = [task.originalRequest.URL absoluteString];
  
  _KHIFIRequest *request = _requests[URLString];
  if (request) {
    NSError *parseError = [NSError errorWithDomain:@"com.fastimage"
                                              code:-1
                                          userInfo:@{ NSLocalizedDescriptionKey: @"Completed request but did not succeed in parsing size and type." }];
    
    
    request.completionBlock(CGSizeZero, KHIFastImageTypeUnsupported, error ?: parseError);
  }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
  completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

@end
