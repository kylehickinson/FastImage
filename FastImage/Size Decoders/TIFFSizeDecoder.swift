//
//  TIFFSizeDecoder.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// TIFF size decoder
///
/// File structure: http://www.fileformat.info/format/tiff/egff.htm
final class TIFFSizeDecoder: ImageSizeDecoder {
  static var imageFormat: FastImage.ImageFormat {
    return .tiff
  }
  
  static func isDecoder(for data: Data) throws -> Bool {
    let order = try String(bytes: data.readBytes(0..<2), encoding: .ascii)
    switch order {
    case "II", "MM":
      // do not recognise CRW or CR2 as tiff
      let isCRW = try String(bytes: data.readBytes(8..<11), encoding: .ascii) == "APC"
      let isCR2 = try data.readBytes(8..<11) == [0x43, 0x52, 0x02] // "CR" 2
      return !(isCRW || isCR2)
    default:
      return false
    }
  }
  
  static func size(for data: Data) throws -> CGSize {
    guard let exif = try Exif(data: data), let width = exif.width, let height = exif.height else {
      throw SizeNotFoundError(data: data)
    }
    if let orientation = exif.orientation, orientation.rawValue >= 5 {
      // Rotated
      return CGSize(width: Int(height), height: Int(width))
    }
    return CGSize(width: Int(width), height: Int(height))
  }
}
