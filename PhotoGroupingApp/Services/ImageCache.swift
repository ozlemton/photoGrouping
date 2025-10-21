import UIKit
import Photos

class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        
        thumbnailCache.countLimit = 200
        thumbnailCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleMemoryWarning() {
        cache.removeAllObjects()
        thumbnailCache.removeAllObjects()
    }
    
    func cachedImage(for asset: PHAsset, size: CGSize) -> UIImage? {
        let key = cacheKey(for: asset, size: size)
        return thumbnailCache.object(forKey: key)
    }
    
    func setCachedImage(_ image: UIImage, for asset: PHAsset, size: CGSize) {
        let key = cacheKey(for: asset, size: size)
        thumbnailCache.setObject(image, forKey: key)
    }
    
    func cachedFullImage(for asset: PHAsset) -> UIImage? {
        let key = cacheKey(for: asset, size: PHImageManagerMaximumSize)
        return cache.object(forKey: key)
    }
    
    func setCachedFullImage(_ image: UIImage, for asset: PHAsset) {
        let key = cacheKey(for: asset, size: PHImageManagerMaximumSize)
        cache.setObject(image, forKey: key)
    }
    
    private func cacheKey(for asset: PHAsset, size: CGSize) -> NSString {
        return "\(asset.localIdentifier)_\(Int(size.width))x\(Int(size.height))" as NSString
    }
    
    func clearCache() {
        cache.removeAllObjects()
        thumbnailCache.removeAllObjects()
        
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
