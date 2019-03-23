//
//  ICOSizeDecoder.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// ICO size decoder
///
/// File structure: https://en.wikipedia.org/wiki/ICO_(file_format)#Outline
final class ICOSizeDecoder: ImageSizeDecoder {
  static var imageFormat: FastImage.ImageFormat {
    return .ico
  }
  static func isDecoder(for data: Data) throws -> Bool {
    return try data.readBytes(0..<3) == [0x00, 0x00, 0x01]
  }
  static func size(for data: Data) throws -> CGSize {
    let numberOfIcons = Int(CFSwapInt16LittleToHost(try data.read(4..<6)))
    var width: Int = 0
    var height: Int = 0
    for index in 0..<numberOfIcons {
      let offset: Int = 6 + (index * 16)
      width = max(width, try data.read(offset) == 0 ? Int(256) : Int(try data.read(offset)))
      height = max(height, try data.read(offset+1) == 0 ? Int(256) : Int(try data.read(offset+1)))
    }
    return CGSize(width: width, height: height)
  }
}
