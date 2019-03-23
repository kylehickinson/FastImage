//
//  GIFSizeDecoder.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// GIF size decoder
///
/// File structure: https://www.fileformat.info/format/gif/egff.htm
final class GIFSizeDecoder: ImageSizeDecoder {
  static var imageFormat: FastImage.ImageFormat {
    return .gif
  }
  static func isDecoder(for data: Data) throws -> Bool {
    return try String(bytes: data.readBytes(0..<3), encoding: .ascii) == "GIF"
  }
  static func size(for data: Data) throws -> CGSize {
    struct Size {
      var width: UInt16
      var height: UInt16
    }
    assert(MemoryLayout<Size>.size == 4)
    let size = try data.read(6..<10) as Size
    return CGSize(width: CGFloat(size.width), height: CGFloat(size.height))
  }
}
