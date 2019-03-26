//
//  FastImageTests.swift
//  FastImageTests
//
//  Created by Kyle Hickinson on 2019-03-08.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import XCTest
import FastImage

private let testFixturesBaseURL = "https://raw.githubusercontent.com/sdsykes/fastimage/master/test/fixtures/";

private struct GoodFixture {
  let name: String
  let expectedSize: CGSize
  let expectedType: FastImage.ImageFormat
  
  init(_ name: String,
       _ expectedWidth: Int,
       _ expectedHeight: Int,
       _ format: FastImage.ImageFormat) {
    self.name = name
    self.expectedSize = CGSize(width: expectedWidth, height: expectedHeight)
    self.expectedType = format
  }
}

private let goodFixtures: [GoodFixture] = [
  GoodFixture("test.bmp", 40, 27, .bmp),
  GoodFixture("test2.bmp", 1920, 1080, .bmp),
  GoodFixture("test.gif", 17, 32, .gif),
  GoodFixture("test.png", 30, 20, .png),
  GoodFixture("test.jpg", 882, 470, .jpg),
  GoodFixture("test2.jpg", 250, 188, .jpg),
  GoodFixture("test3.jpg", 630, 367, .jpg),
  GoodFixture("test4.jpg", 1485, 1299, .jpg),
  GoodFixture("infinite.jpg", 160, 240, .jpg),
  GoodFixture("exif_orientation.jpg", 600, 450, .jpg),
  GoodFixture("orient_2.jpg", 230, 408, .jpg),
  GoodFixture("orient_6.jpg", 1250, 2500, .jpg),
  GoodFixture("test.tiff", 85, 67, .tiff),
  GoodFixture("test2.tiff", 333, 225, .tiff),
  GoodFixture("favicon.ico",  16, 16, .ico),
  GoodFixture("favicon2.ico",  32, 32, .ico),
  GoodFixture("man.ico",  256, 256, .ico),
  GoodFixture("test.cur",  32, 32, .cur),
  GoodFixture("test.psd", 17, 32, .psd),
//  GoodFixture("webp_vp8x.webp",  386, 395, .webp),
//  GoodFixture("webp_vp8l.webp",  386, 395, .webp),
//  GoodFixture("webp_vp8.webp",  550, 368, .webp),
//  GoodFixture("test.svg",  200, 300, .svg),
//  GoodFixture("test_partial_viewport.svg",  860, 400, .svg),
//  GoodFixture("test2.svg",  366, 271, .svg),
//  GoodFixture("test3.svg",  255, 48, .svg),
//  GoodFixture("test4.svg",  271, 271, .svg),
]

class FastImageTests: XCTestCase {
  
  var fastImage: FastImage!
  
  override func setUp() {
    super.setUp()
    fastImage = FastImage()
    fastImage.requestTimeout = 10.0
  }
  
  func testGoodFixtures() {
    for fixture in goodFixtures {
      let e = expectation(description: fixture.name)
      let url = fixture.name.contains("http") ? URL(string: fixture.name)! : URL(string: "\(testFixturesBaseURL)\(fixture.name)")!
      
      fastImage.imageSizeAndType(for: url, completion: { result in
        switch result {
        case .success(let (size, type)):
          XCTAssertEqual(type, fixture.expectedType)
          XCTAssertEqual(size, fixture.expectedSize, "\(fixture.name) - Sizes do not match")
        case .failure(let error):
          XCTFail("\(fixture.name) failed with error: \(error.localizedDescription)")
        }
        e.fulfill()
      })
      waitForExpectations(timeout: fastImage.requestTimeout + 2.0)
    }
  }
  
  func testSizeNotFoundFixtures() {
    let badFixtures = ["faulty.jpg"]
    for filename in badFixtures {
      let expectation = self.expectation(description: filename)
      let url = URL(string: "\(testFixturesBaseURL)\(filename)")!
      
      fastImage.imageSizeAndType(for: url) { result in
        switch result {
        case .success:
          XCTFail("Should have failed to get the size / type of \(filename)")
        case .failure(let error):
          XCTAssertTrue(error is SizeNotFoundError)
        }
        expectation.fulfill()
      }
      waitForExpectations(timeout: self.fastImage.requestTimeout + 2.0)
    }
  }
  
  func testUnsupportedImageFormats() {
    fastImage.requestTimeout = 30.0
    
    let images = ["a.CR2", "a.CRW", "test.xml"]
    for filename in images {
      let expectation = self.expectation(description: filename)
      let url = URL(string: "\(testFixturesBaseURL)\(filename)")!
      
      fastImage.imageSizeAndType(for: url) { result in
        switch result {
        case .success:
          XCTFail("Should have failed to get the size / type of \(filename)")
        case .failure(let error):
          XCTAssertTrue(error is UnsupportedImageError)
        }
        expectation.fulfill()
      }
      waitForExpectations(timeout: self.fastImage.requestTimeout + 2.0)
    }
  }
  
  func testTimeout() {
    fastImage.requestTimeout = 0.01 // Set unrealistically low to force timeout
    let filename = "test2.bmp"
    let expectation = self.expectation(description: filename)
    let url = URL(string: "\(testFixturesBaseURL)\(filename)")!
    
    fastImage.imageSizeAndType(for: url) { result in
      switch result {
      case .success:
        XCTFail("Should have failed to get the size / type")
      case .failure(let error as URLError):
        XCTAssertEqual(error.code, URLError.Code.timedOut)
      case .failure(let error):
        XCTFail("Incorrect failure type: \(error.localizedDescription)")
      }
      expectation.fulfill()
    }
    waitForExpectations(timeout: self.fastImage.requestTimeout + 2.0)
  }
  
  func testDataURI() {
    let e = expectation(description: "Data URI")
    let url = URL(string: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAIAAAABCAYAAAD0In+KAAAAD0lEQVR42mNk+M9QzwAEAAmGAYCF+yOnAAAAAElFTkSuQmCC")!
    
    fastImage.imageSizeAndType(for: url, completion: { result in
      switch result {
      case .success(let (size, type)):
        XCTAssertEqual(type, .png)
        XCTAssertEqual(size, CGSize(width: 2, height: 1), "Data URI - Sizes do not match")
      case .failure(let error):
        XCTFail("Data URI failed with error: \(error.localizedDescription)")
      }
      e.fulfill()
    })
    waitForExpectations(timeout: fastImage.requestTimeout + 2.0)
  }
}
