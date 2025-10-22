import SwiftUI
import Photos

struct AssetWrapper: Identifiable {
    let asset: PHAsset
    var id: String { asset.localIdentifier }
}

struct GroupDetailView: View {
    let group: PhotoGroup?
    let assets: [PHAsset]
    @State private var selectedAsset: AssetWrapper? = nil
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    PhotoThumbnailView(asset: asset)
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture { selectedAsset = AssetWrapper(asset: asset) }
                }
            }
            .padding()
        }
        .navigationTitle(groupTitle)
        .fullScreenCover(item: $selectedAsset) { wrapper in
            ImageDetailView(asset: wrapper.asset, assets: assets)
                .overlay(
                    Button(action: { selectedAsset = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                            .padding()
                    }, alignment: .topTrailing
                )
        }
    }
    
    private var groupTitle: String {
        if let group = group { return "Group \(group.rawValue.uppercased())" }
        else { return "Others" }
    }
}



struct PhotoThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    
    private let thumbnailSize = CGSize(width: 150, height: 150)
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else if hasError {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Failed")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        VStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .onAppear { fetchThumbnail() }
    }
    
    private func fetchThumbnail() {
        // Cache varsa kullan
        if let cached = ImageCache.shared.cachedImage(for: asset, size: thumbnailSize) {
            DispatchQueue.main.async {
                self.image = cached
                self.isLoading = false
            }
            return
        }
        
        let manager = PHImageManager.default()
        
        // Önce hızlı thumbnail dene
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        options.isSynchronous = false
        
        manager.requestImage(for: asset,
                             targetSize: thumbnailSize,
                             contentMode: .aspectFill,
                             options: options) { thumbImage, info in
            if let thumbImage = thumbImage {
                DispatchQueue.main.async {
                    self.image = thumbImage
                    ImageCache.shared.setCachedImage(thumbImage, for: self.asset, size: self.thumbnailSize)
                    self.isLoading = false
                }
            } else {
                // Thumbnail yoksa fallback olarak full image iste
                self.fetchFullImage()
            }
        }
    }
    
    private func fetchFullImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            DispatchQueue.main.async {
                if let data = data, let uiImage = UIImage(data: data) {
                    self.image = uiImage
                    ImageCache.shared.setCachedImage(uiImage, for: self.asset, size: self.thumbnailSize)
                } else {
                    self.hasError = true
                }
                self.isLoading = false
            }
        }
    }
}

