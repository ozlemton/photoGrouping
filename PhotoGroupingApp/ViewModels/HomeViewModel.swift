import Foundation
import Photos
import Combine
import UIKit

class HomeViewModel: ObservableObject {
    @Published var groupedAssets: [String: [PHAsset]] = [:]
    @Published var progress: Double = 0
    @Published var processedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var errorMessage: String? = nil
    @Published var isScanning: Bool = false

    private let scanner = PhotoScanner.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
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
        ImageCache.shared.clearCache()
    }
    
    func startScan() {
        isScanning = true
        errorMessage = nil
        
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.bindScanner()
                    self.scanner.startScan()
                case .denied:
                    self.errorMessage = "Photo access denied. Please enable photo library access in Settings."
                    self.isScanning = false
                case .restricted:
                    self.errorMessage = "Photo access is restricted on this device."
                    self.isScanning = false
                case .notDetermined:
                    self.errorMessage = "Photo access permission not determined."
                    self.isScanning = false
                @unknown default:
                    self.errorMessage = "Unknown photo access status."
                    self.isScanning = false
                }
            }
        }
    }
    
    private func bindScanner() {
        scanner.onProgressUpdate = { [weak self] progress, processed, total in
            DispatchQueue.main.async {
                self?.progress = progress
                self?.processedCount = processed
                self?.totalCount = total
                
                if progress >= 1.0 {
                    self?.isScanning = false
                }
            }
        }
        
        scanner.onGroupUpdate = { [weak self] grouped in
            DispatchQueue.main.async {
                var temp: [String: [PHAsset]] = [:]
                for (group, _) in grouped {
                    temp[group] = self?.scanner.assets(for: group) ?? []
                }
                self?.groupedAssets = temp
            }
        }
    }
}