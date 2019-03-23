//
//  PSDSizeDecode.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// PSD size decoder
final class PSDSizeDecoder: ImageSizeDecoder {
  static var imageFormat: FastImage.ImageFormat {
    return .psd
  }
  static func isDecoder(for data: Data) throws -> Bool {
    return try String(bytes: data.readBytes(0..<2), encoding: .ascii) == "8B"
  }
  static func size(for data: Data) throws -> CGSize {
    let height = CFSwapInt32BigToHost(try data.read(14..<18))
    let width = CFSwapInt32BigToHost(try data.read(18..<22))
    return CGSize(width: Int(width), height: Int(height))
  }
}
