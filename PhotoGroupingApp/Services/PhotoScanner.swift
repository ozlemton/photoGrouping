import Foundation
import Photos
import UIKit

class PhotoScanner {
    static let shared = PhotoScanner()
    
    private let fileManager = FileManager.default
    private let scanProgressFile = "scan_progress.json"
    private let groupingResultsFile = "grouping_results.json"
    private var processedAssets: Set<String> = []
    private var groupedAssets: [String: [String]] = [:]
    private var allAssets: [PHAsset] = []
    var onProgressUpdate: ((Double, Int, Int) -> Void)?
    var onGroupUpdate: (([String: [String]]) -> Void)?
    private let batchSize = 50
    private var isScanning = false
    
    private init() {
        loadScanProgress()
        loadGroupingResults()
        
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
        if !isScanning {
            allAssets.removeAll()
        }
    }
    
    func startScan() {
        guard !isScanning else { return }
        isScanning = true
        
        let fetchOptions = PHFetchOptions()
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard fetchResult.count > 0 else {
            isScanning = false
            DispatchQueue.main.async { self.onProgressUpdate?(0, 0, 0) }
            return
        }
        allAssets = fetchResult.objects(at: IndexSet(0..<fetchResult.count))
        DispatchQueue.main.async { self.onProgressUpdate?(0, self.processedAssets.count, self.allAssets.count) }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.processAssetsInBatches()
        }
    }
    
    private func processAssetsInBatches() {
        let total = allAssets.count
        for batchStart in stride(from: 0, to: total, by: batchSize) {
            autoreleasepool {
                let batchEnd = min(batchStart + batchSize, total)
                let batch = Array(allAssets[batchStart..<batchEnd])
                
                for asset in batch {
                    if processedAssets.contains(asset.localIdentifier) { continue }
                    let hashValue = asset.reliableHash()
                    let group = PhotoGroup.group(for: hashValue)?.rawValue ?? "Other"

                    groupedAssets[group, default: []].append(asset.localIdentifier)
                    processedAssets.insert(asset.localIdentifier)
                }
                saveScanProgress()
                saveGroupingResults()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let processedCount = self.processedAssets.count
                    self.onProgressUpdate?(Double(processedCount)/Double(total), processedCount, total)
                    self.onGroupUpdate?(self.groupedAssets)
                }
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isScanning = false
        }
    }
    
    private func saveScanProgress() {
        let array = Array(processedAssets)
        saveJSON(array, fileName: scanProgressFile)
    }
    
    private func loadScanProgress() {
        if let array: [String] = loadJSON(fileName: scanProgressFile) {
            processedAssets = Set(array)
        }
    }
    
    private func saveGroupingResults() {
        saveJSON(groupedAssets, fileName: groupingResultsFile)
    }
    
    private func loadGroupingResults() {
        if let dict: [String: [String]] = loadJSON(fileName: groupingResultsFile) {
            groupedAssets = dict
        }
    }
    
    private func saveJSON<T: Encodable>(_ object: T, fileName: String) {
        guard let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = docURL.appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: fileURL)
        } catch { print("Error saving \(fileName): \(error)") }
    }
    
    private func loadJSON<T: Decodable>(fileName: String) -> T? {
        guard let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = docURL.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Error loading \(fileName): \(error)")
            return nil
        }
    }
    
    func assets(for group: String) -> [PHAsset] {
        guard let identifiers = groupedAssets[group] else { return [] }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        return fetchResult.objects(at: IndexSet(0..<fetchResult.count))
    }
    
    func clearData() {
        processedAssets.removeAll()
        groupedAssets.removeAll()
        allAssets.removeAll()
        
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docURL = docURL {
            try? fileManager.removeItem(at: docURL.appendingPathComponent(scanProgressFile))
            try? fileManager.removeItem(at: docURL.appendingPathComponent(groupingResultsFile))
        }
    }
    
    func getScanProgress() -> (processed: Int, total: Int) {
        return (processedAssets.count, allAssets.count)
    }
}