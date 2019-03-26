//
//  DataExtensions.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

extension Data {
  struct AccessError: Error {
    let range: Range<Data.Index>
    let data: Data
  }
  func read<ResultType>(from index: Int, length: Int) throws -> ResultType {
    return try read(index..<index+length)
  }
  func read(_ index: Int) throws -> UInt8 {
    return try read(index..<index+1) as UInt8
  }
  func read<ResultType>(_ range: Range<Data.Index>) throws -> ResultType {
    if range.upperBound <= count {
      return subdata(in: range).withUnsafeBytes({ $0.pointee })
    }
    throw AccessError(range: range, data: self)
  }
  func readBytes(_ range: Range<Data.Index>) throws -> [UInt8] {
    if range.upperBound <= count {
      return subdata(in: range).withUnsafeBytes { bytes in
        Array(UnsafeBufferPointer(start: bytes, count: range.count / MemoryLayout<UInt8>.stride))
      }
    }
    throw AccessError(range: range, data: self)
  }
}

