//
//  BMPSizeDecoder.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// Bitmap size decoder
///
/// File structure: http://www.fileformat.info/format/bmp/egff.htm
final class BMPSizeDecoder: ImageSizeDecoder {
  static var imageFormat: FastImage.ImageFormat {
    return .bmp
  }
  
  static func isDecoder(for data: Data) throws -> Bool {
    return try String(bytes: data.readBytes(0..<2), encoding: .ascii) == "BM"
  }
  
  static func size(for data: Data) throws -> CGSize {
    // Read the BMP header size. Depending on the size, it may
    // be an older version which only contains 16 bit width/height
    if try data.read(14) == 12 {
      let width = try data.read(18..<20) as UInt16
      let height = try data.read(20..<22) as UInt16
      return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
    else {
      // Height can be negative (describing the origin of the image)
      // This doesn't really matter to us
      let width = try data.read(18..<22) as Int32
      let height = abs(try data.read(22..<26) as Int32)
      return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
  }
}
