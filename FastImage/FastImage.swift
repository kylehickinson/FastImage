//
//  FastImage.swift
//  FastImage
//
//  Created by Kyle Hickinson on 2019-03-08.
//  Copyright © 2019 Kyle Hickinson. All rights reserved.
//

import Foundation

public enum Result<T> {
  case success(T)
  case failure(Error)
}

/// An error thrown when there are no size decoders that can decode the given image
public struct UnsupportedImageError: Error {
  public let data: Data
}

/// FastImage is an Swift port of the Ruby project by Stephen Sykes. It's directive is too
/// request as little data as possible (usually just the first batch of bytes returned by a request),
/// to determine the size and type of a remote image.
///
/// See: https://github.com/sdsykes/fastimage
public final class FastImage: NSObject {
  /// The list of image formats that may be returned by `imageSizeAndType(for:completion)`
  public enum ImageFormat {
    case gif
    case png
    case jpg
    case bmp
    case tiff
    case psd
    case ico
    case cur
  }
  /// Maximum amount of time a request has to complete its task.
  /// Defaults to 2 seconds
  public var requestTimeout: TimeInterval = 2.0
  
  private lazy var session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
  
  public typealias CompletionBlock = (Result<(CGSize, ImageFormat)>) -> Void
  
  /// Start a fast image request to get size and type from a remote image
  ///
  /// - parameter url: The remote image URL to parse
  /// - parameter completion: Completion block indicating size and type of the remote image, or an error if it failed
  /// - returns: A data task which has been started. Use this returned value to cancel or suspend a task if needed
  @discardableResult
  public func imageSizeAndType(
    for url: URL,
    completion: @escaping CompletionBlock) -> URLSessionDataTask {
    
    if let request = requests[url.absoluteString] {
      return request.task
    }
    
    let urlRequest = URLRequest(
      url: url,
      cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
      timeoutInterval: requestTimeout
    )
    let task = session.dataTask(with: urlRequest)
    requests[url.absoluteString] = Request(task: task, completion: completion)
    task.resume()
    return task
  }
  
  private class Request {
    var task: URLSessionDataTask
    var data: Data
    var completion: CompletionBlock
    
    init(task: URLSessionDataTask, completion: @escaping CompletionBlock) {
      self.task = task
      self.data = Data()
      self.completion = completion
    }
  }
  
  private var requests: [String: Request] = [:]
  
  private let sizeDecoders: [ImageSizeDecoder.Type] = [
    PNGSizeDecoder.self,
    GIFSizeDecoder.self,
    BMPSizeDecoder.self,
    JPGSizeDecoder.self,
    TIFFSizeDecoder.self,
    PSDSizeDecoder.self,
    ICOSizeDecoder.self,
    CURSizeDecoder.self
  ]
  
  private func decoder(for data: Data) -> ImageSizeDecoder.Type? {
    do {
      return try sizeDecoders.first(where: { try $0.isDecoder(for: data) })
    } catch {
      print(error)
    }
    return nil
  }
  
  private func parse(request: Request) {
    let data = request.data
    if data.isEmpty { return }
    guard let decoder = decoder(for: data) else {
      request.completion(.failure(UnsupportedImageError(data: data)))
      request.task.cancel()
      if let urlString = request.task.originalRequest?.url?.absoluteString {
        requests.removeValue(forKey: urlString)
      }
      return
    }
    do {
      let size = try decoder.size(for: data)
      request.completion(.success((size, decoder.imageFormat)))
      request.task.cancel()
      if let urlString = request.task.originalRequest?.url?.absoluteString {
        requests.removeValue(forKey: urlString)
      }
    } catch {
      // Not enough data
    }
  }
}

extension FastImage: URLSessionDataDelegate {
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    guard let urlString = dataTask.originalRequest?.url?.absoluteString,
      let request = requests[urlString] else {
        return
    }
    request.data.append(data)
    if (!request.data.isEmpty) {
      parse(request: request)
    }
  }
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error as? URLError, error.code == .cancelled {
      return
    }
    guard let urlString = task.originalRequest?.url?.absoluteString,
      let request = requests[urlString] else {
        return
    }
    request.completion(.failure(error ?? SizeNotFoundError(data: request.data)))
    requests.removeValue(forKey: urlString)
  }
  public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
  }
}
