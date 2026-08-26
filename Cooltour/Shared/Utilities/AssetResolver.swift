import Foundation
import UIKit

/// Centralized utility for resolving bundled audio and image resources across
/// root bundle and nested resource subdirectories (e.g. `Audio/{renon,sanur}`, `SitePictures/{renon,sanur}`).
enum AssetResolver {
  private static let audioSubdirectories: [String] = [
    "Audio",
    "Audio/renon",
    "Audio/sanur",
    "renon",
    "sanur"
  ]

  private static let imageSubdirectories: [String] = [
    "SitePictures",
    "SitePictures/renon",
    "SitePictures/sanur",
    "renon",
    "sanur"
  ]

  // MARK: - Audio Resolution

  /// Locates the file URL for a given audio asset name.
  static func audioURL(named name: String, bundle: Bundle = .main) -> URL? {
    guard !name.isEmpty else { return nil }

    // 1. Direct root resolution
    if let url = bundle.url(forResource: name, withExtension: nil) {
      return url
    }

    let nsName = name as NSString
    let baseName = nsName.deletingPathExtension
    let ext = nsName.pathExtension.isEmpty ? "m4a" : nsName.pathExtension

    if let url = bundle.url(forResource: baseName, withExtension: ext) {
      return url
    }

    // 2. Search known subdirectories
    for subDir in audioSubdirectories {
      if let url = bundle.url(forResource: baseName, withExtension: ext, subdirectory: subDir) {
        return url
      }
      if let url = bundle.url(forResource: name, withExtension: nil, subdirectory: subDir) {
        return url
      }
    }

    return nil
  }

  // MARK: - Image Resolution

  /// Loads a UIImage for a given site thumbnail / image asset name.
  static func siteImage(named name: String?, bundle: Bundle = .main) -> UIImage? {
    guard let name, !name.isEmpty else { return nil }

    // 1. Try Assets catalog
    if let img = UIImage(named: name, in: bundle, with: nil) {
      return img
    }

    let nsName = name as NSString
    let baseName = nsName.deletingPathExtension
    let originalExt = nsName.pathExtension
    let candidateExtensions = originalExt.isEmpty ? ["jpg", "jpeg", "png"] : [originalExt]

    // 2. Try direct path and subdirectories
    for ext in candidateExtensions {
      // Root bundle
      if let path = bundle.path(forResource: baseName, ofType: ext),
         let img = UIImage(contentsOfFile: path) {
        return img
      }

      // Subdirectories
      for subDir in imageSubdirectories {
        if let path = bundle.path(forResource: baseName, ofType: ext, inDirectory: subDir),
           let img = UIImage(contentsOfFile: path) {
          return img
        }
        if let path = bundle.path(forResource: name, ofType: nil, inDirectory: subDir),
           let img = UIImage(contentsOfFile: path) {
          return img
        }
      }

      // Direct URL fallback
      if let url = bundle.url(forResource: baseName, withExtension: ext),
         let data = try? Data(contentsOf: url),
         let img = UIImage(data: data) {
        return img
      }
    }

    return nil
  }
}
