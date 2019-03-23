//
//  PNGSizeDecoder.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// A PNG size decoder
///
/// PNG structure:
/// - http://www.libpng.org/pub/png/spec/1.2/PNG-Structure.html
/// - http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html
final class PNGSizeDecoder: ImageSizeDecoder {
  static var imageFormat: FastImage.ImageFormat {
    return .png
  }
  static func isDecoder(for data: Data) throws -> Bool {
    let signature: [UInt8] = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]
    return try data.readBytes(0..<signature.count) == signature
  }
  static func size(for data: Data) throws -> CGSize {
    // PNG is also simple: 8 byte header, next just read the first chunk (IHDR).
    // Chunks have the format:
    //  4 bytes - length
    //  4 bytes - type
    //  X bytes - data
    //  4 bytes - CRC
    // meaning the first chunk is located at offset 8 and the data begins at 16.
    // the width and height are stored as 32 bit unsigned integers (big-endian)
    struct Size {
      var width: UInt32 = 0 // Big-endian
      var height: UInt32 = 0 // Big-endian
    }
    assert(MemoryLayout<Size>.size == 8)
    let size = try data.read(16..<24) as Size
    return CGSize(
      width: CGFloat(CFSwapInt32BigToHost(size.width)),
      height: CGFloat(CFSwapInt32BigToHost(size.height))
    )
  }
}
