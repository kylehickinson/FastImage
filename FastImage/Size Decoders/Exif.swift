//
//  Exif.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// Obtains the image width, height and orientation from an EXIF data structure
///
/// Can also be used for EXIF JPEG's, but will only find orientation data (among other Exif tags we dont care about)
///
/// http://www.fileformat.info/format/tiff/egff.htm
final class Exif {
  private(set) var orientation: UIImage.Orientation?
  private(set) var width: UInt16?
  private(set) var height: UInt16?
  
  init?(data: Data) throws {
    // Little endian defined as "II", big endian defined as "MM"
    let isLittleEndian = try String(bytes: data.readBytes(0..<2), encoding: .ascii) == "II"
    let swap32 = isLittleEndian ? CFSwapInt32LittleToHost : CFSwapInt32BigToHost
    let swap16 = isLittleEndian ? CFSwapInt16LittleToHost : CFSwapInt16BigToHost
    var offset = Int(swap32(try data.read(4..<8)))
    let numberOfTags = swap16(try data.read(from: offset, length: 2))
    offset += 2
    
    for _ in 0..<numberOfTags {
      let tagIdentifier = swap16(try data.read(from: offset, length: 2))
      let value = swap16(try data.read(from: offset + 8, length: 2))
      switch tagIdentifier {
      case 0x0100: // ImageWidth
        width = value
      case 0x0101:
        height = value
      case 0x0112:
        orientation = UIImage.Orientation(rawValue: Int(value))
      default:
        break
      }
      if let _ = width, let _ = height, let _ = orientation {
        return
      }
      // Each tag is 12 bytes long
      offset += 12
    }
    
    if width == nil, height == nil, orientation == nil {
      // Found nothing
      return nil
    }
  }
}
