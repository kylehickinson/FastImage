//
//  JPGSizeDecoder.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// JPEG Size decoder
///
/// File structure: http://www.fileformat.info/format/jpeg/egff.htm
/// JPEG Tags: https://www.sno.phy.queensu.ca/~phil/exiftool/TagNames/JPEG.html
final class JPGSizeDecoder: ImageSizeDecoder {
  static var imageFormat: FastImage.ImageFormat {
    return .jpg
  }
  
  static func isDecoder(for data: Data) throws -> Bool {
    let signature: [UInt8] = [0xFF, 0xD8]
    return try data.readBytes(0..<2) == signature
  }
  
  private enum SearchState {
    case findHeader
    case determineFrameType
    case skipFrame
    case foundSOF
    case foundEOI
  }
  
  static func size(for data: Data) throws -> CGSize {
    var searchState: SearchState = .findHeader
    var offset = 2
    var imageOrientation: UIImage.Orientation?
    
    while offset < data.count {
      switch searchState {
      case .findHeader:
        while try data.read(offset) != 0xFF {
          offset += 1
        }
        searchState = .determineFrameType
      case .determineFrameType:
        // We've found a data marker, now we determine what type of data we're looking at.
        // FF E0 -> FF EF are 'APPn', and include lots of metadata like EXIF, etc.
        //
        // What we want to find is one of the SOF (Start of Frame) header, cause' it includes
        // width and height (what we want!)
        //
        // JPEG Metadata Header Table
        // http://www.xbdev.net/image_formats/jpeg/tut_jpg/jpeg_file_layout.php
        // Each of these SOF data markers have the same data structure:
        // struct {
        //   UInt16 header; // e.g. FFC0
        //   UInt16 frameLength;
        //   UInt8 samplePrecision;
        //   UInt16 imageHeight;
        //   UInt16 imageWidth;
        //   ... // we only care about this part
        // }
        let sample = try data.read(offset)
        offset += 1
        
        // Technically we should check if this has EXIF data here (looking for FFE1 marker)…
        // Maybe TODO later
        switch sample {
        case 0xE1:
          let exifLength = CFSwapInt16BigToHost(try data.read(from: offset, length: 2))
          let exifString = String(bytes: try data.readBytes(offset+2..<offset+6), encoding: .ascii)
          if exifString == "Exif" {
            let exifData = data.advanced(by: offset + 8)
            if let exif = try? Exif(data: exifData), imageOrientation == nil {
              #if swift(>=5.0)
              imageOrientation = exif.orientation
              #else
              imageOrientation = exif?.orientation
              #endif
            }
          }
          offset += Int(exifLength)
          searchState = .findHeader
        case 0xE0...0xEF:
          // Technically we should check if this has EXIF data here (looking for FFE1 marker)…
          searchState = .skipFrame
        case 0xC0...0xC3, 0xC5...0xC7, 0xC9...0xCB, 0xCD...0xCF:
          searchState = .foundSOF
        case 0xFF:
          searchState = .determineFrameType
        case 0xD9:
          // We made it to the end of the file somehow without finding the size? Likely a corrupt file
          searchState = .foundEOI
        default:
          // Since we don't handle every header case default to skipping an unknown data marker
          searchState = .skipFrame
        }
      case .skipFrame:
        let frameLength = Int(CFSwapInt16BigToHost(try data.read(offset..<offset+2) as UInt16))
        offset += frameLength - 1
        searchState = .findHeader
      case .foundSOF:
        offset += 3
        let height = try data.read(offset..<offset+2) as UInt16
        let width = try data.read(offset+2..<offset+4) as UInt16
        
        if let orientation = imageOrientation, orientation.rawValue >= 5 {
          // Rotated
          return CGSize(
            width: CGFloat(CFSwapInt16BigToHost(height)),
            height: CGFloat(CFSwapInt16BigToHost(width))
          )
        }
        return CGSize(
          width: CGFloat(CFSwapInt16BigToHost(width)),
          height: CGFloat(CFSwapInt16BigToHost(height))
        )
      case .foundEOI:
        throw SizeNotFoundError(data: data)
      }
    }
    
    throw SizeNotFoundError(data: data)
  }
}
