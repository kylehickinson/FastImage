//
//  FastImage.h
//
//  Licensed under the MIT license.
//  Copyright (c) 2015 Kyle Hickinson. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

typedef NS_ENUM(NSInteger, KHIFastImageType) {
  KHIFastImageTypeUnsupported = 0,
  KHIFastImageTypeGIF,
  KHIFastImageTypePNG,
  KHIFastImageTypeJPEG,
  KHIFastImageTypeBMP,
};

typedef void (^KHIFastImageCompletionBlock)(CGSize size, KHIFastImageType type, NSError *error);

/**
 FastImage is an Objective-C port of the Ruby project by Stephen Sykes. It's directive is too
 request as little data as possible (usually just the first batch of bytes returned by a request),
 to determine the size and type of a remote image.

 See: https://github.com/sdsykes/fastimage
 */
@interface KHIFastImage : NSObject

/**
 Maximum amount of time a request has to complete its task.
 
 Defaults to 2.0
 */
@property (nonatomic, assign) NSTimeInterval requestTimeout;

/**
 Start a fast image request to get size and type from a remote image
 
 @param URL The remote image URL to parse
 @param completion Completion block indicating size and type of the remote image, or an error if it failed
 
 @return A data task which has been started. Use this returned value to cancel or suspend a task if needed
 */
- (NSURLSessionDataTask *)imageSizeAndTypeForURL:(NSURL *)URL completion:(KHIFastImageCompletionBlock)completion;

@end
