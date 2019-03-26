//
//  DataTests.swift
//  FastImageTests
//
//  Created by Kyle Hickinson on 2019-03-25.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import XCTest
@testable import FastImage

class DataTests: XCTestCase {
  
  func testSingleByteRead() {
    let data = Data([0x01, 0x02])
    do {
      XCTAssertEqual(try data.read(0), 0x01)
      XCTAssertEqual(try data.read(1), 0x02)
    }
  }
  
  func testDataAccessError() {
    let data = Data([0x01, 0x02])
    do {
      _ = try data.read(3)
      XCTFail("Should have failed to read from 3")
    } catch {
      XCTAssertTrue(error is Data.AccessError)
    }
  }
  
  func testReadBytes() {
    let bytes: [UInt8] = [0xdd, 0xee, 0xff]
    let data = Data(bytes)
    XCTAssertEqual(try data.readBytes(0..<3), bytes)
  }
  
  func testReadToType() {
    let value: UInt16 = 4096
    let data = Data(withUnsafeBytes(of: value, { Array($0) }))
    XCTAssertEqual(data.count, 2)
    XCTAssertEqual(try data.read(0..<2) as UInt16, value)
  }
  
  func testReadToStruct() {
    struct TestType: Equatable {
      let a: UInt16
      let b: UInt16
      let c: UInt32
    }
    let value = TestType(a: 0x800, b: 0x1000, c: 0x10000)
    let data = Data(withUnsafeBytes(of: value, { Array($0) }))
    let structSize = MemoryLayout<TestType>.size
    XCTAssertEqual(data.count, structSize)
    XCTAssertEqual(try data.read(0..<structSize) as TestType, value)
    XCTAssertEqual(try data.read(2..<4) as UInt16, value.b)
    XCTAssertEqual(try data.read(4..<8) as UInt32, value.c)
  }
}
