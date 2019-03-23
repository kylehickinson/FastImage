//
//  ImageSizeDecoder.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-23.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

/// An error thrown by an ImageSizeDecoder when it cannot find a size with the available data
public struct SizeNotFoundError: Error {
  public let data: Data
}

protocol ImageSizeDecoder {
  /// THe image format that this size decoder
  static var imageFormat: FastImage.ImageFormat { get }
  /// Whether or not given the data, this image size decoder should be used
  ///
  /// For example, a GIF size decoder will check the first 3 bytes to see if they match "GIF"
  ///
  /// - throws: DataAccessError
  static func isDecoder(for data: Data) throws -> Bool
  /// Get the size of the image given the data available
  ///
  /// - throws: SizeNotFoundError, DataAccessError
  static func size(for data: Data) throws -> CGSize
}
