//
//  FastImageTest.m
//  FastImage
//
//  Created by Kyle Hickinson on 2014-11-08.
//  Copyright (c) 2014 Kyle Hickinson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <XCTest/XCTest.h>

#import "KHIFastImage.h"

static inline NSDictionary *KHIFastImageCorrectFixture(KHIFastImageType type, CGSize size) {
  return @{ @"type": @(type),
            @"size": @{
                @"width": @(size.width),
                @"height": @(size.height)
                }
            };
}

static NSString * const KHITestBaseURL = @"https://raw.githubusercontent.com/sdsykes/fastimage/master/test/fixtures/";

/**
 All the files in the `fixtures` directory that I am downloading from belong to the repo of Stephen Sykes:
 https://github.com/sdsykes/fastimage
 
 I am using them to test in the same way to be consistent. Perhaps I should copy the file to this repo
 */
@interface KHIFastImageTest : XCTestCase

@property (nonatomic, strong) KHIFastImage *fastImage;
@property (nonatomic, readonly) NSDictionary *goodFixtures;
@property (nonatomic, readonly) NSArray *badFixtures;

@end

@implementation KHIFastImageTest

- (void)setUp
{
  [super setUp];
  
  self.fastImage = [KHIFastImage new];
}

- (NSDictionary *)goodFixtures
{
  static NSDictionary *_goodFixtures = nil;
  if (!_goodFixtures) {
    _goodFixtures = @{
      @"test.bmp": KHIFastImageCorrectFixture(KHIFastImageTypeBMP, CGSizeMake(40, 27)),
      @"test2.bmp": KHIFastImageCorrectFixture(KHIFastImageTypeBMP, CGSizeMake(1920, 1080)),
      @"test.gif": KHIFastImageCorrectFixture(KHIFastImageTypeGIF, CGSizeMake(17, 32)),
      @"test.jpg": KHIFastImageCorrectFixture(KHIFastImageTypeJPEG, CGSizeMake(882, 470)),
      @"test.png": KHIFastImageCorrectFixture(KHIFastImageTypePNG, CGSizeMake(30, 20)),
      @"test2.jpg": KHIFastImageCorrectFixture(KHIFastImageTypeJPEG, CGSizeMake(250, 188)),
      @"test3.jpg": KHIFastImageCorrectFixture(KHIFastImageTypeJPEG, CGSizeMake(630, 367)),
      @"test4.jpg": KHIFastImageCorrectFixture(KHIFastImageTypeJPEG, CGSizeMake(1485, 1299)),
      @"infinite.jpg": KHIFastImageCorrectFixture(KHIFastImageTypeJPEG, CGSizeMake(160, 240)),
      // When EXIF data extraction is supported, re-add these:
//      @"orient_2.jpg": _FIGoodFixtureInfo(KHIFastImageTypeJPEG, CGSizeMake(230, 408)),
//      @"exif_orientation.jpg": _FIGoodFixtureInfo(KHIFastImageTypeJPEG, CGSizeMake(600, 450)),
    };
  }
  return _goodFixtures;
}

- (NSArray *)badFixtures
{
  return @[ @"faulty.jpg" ];
}

- (void)testShouldReportGoodFixturesCorrectly
{
  typeof(self) __weak weakSelf = self;
  
  for (NSString *fileName in self.goodFixtures) {
    XCTestExpectation *expectation = [self expectationWithDescription:fileName];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", KHITestBaseURL, fileName];
    
    [self.fastImage imageSizeAndTypeForURL:[NSURL URLWithString:path] completion:^(CGSize size, KHIFastImageType type, NSError *error) {
      XCTAssertTrue(type == [weakSelf.goodFixtures[fileName][@"type"] integerValue]);
      XCTAssertTrue(size.width == [weakSelf.goodFixtures[fileName][@"size"][@"width"] floatValue]);
      XCTAssertTrue(size.height == [weakSelf.goodFixtures[fileName][@"size"][@"height"] floatValue]);
      [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:self.fastImage.requestTimeout + 2.0 handler:nil];
  }
}

- (void)testShouldReportBadFixtureCorrectly
{
  for (NSString *fileName in self.badFixtures) {
    XCTestExpectation *expectation = [self expectationWithDescription:fileName];
    
    NSString *path = [NSString stringWithFormat:@"%@%@", KHITestBaseURL, fileName];
    
    [self.fastImage imageSizeAndTypeForURL:[NSURL URLWithString:path] completion:^(CGSize size, KHIFastImageType type, NSError *error) {
      
      XCTAssertNotNil(error);
      [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:self.fastImage.requestTimeout + 2.0 handler:nil];
  }
}

@end
