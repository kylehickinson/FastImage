//
//  CURSizeDecoder.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// CUR size decoder
///
/// File structure: https://en.wikipedia.org/wiki/ICO_(file_format)#Outline
final class CURSizeDecoder: ImageSizeDecoder {
  static var imageFormat: FastImage.ImageFormat {
    return .cur
  }
  static func isDecoder(for data: Data) throws -> Bool {
    return try data.readBytes(0..<3) == [0x00, 0x00, 0x02]
  }
  static func size(for data: Data) throws -> CGSize {
    return try ICOSizeDecoder.size(for: data)
  }
}
