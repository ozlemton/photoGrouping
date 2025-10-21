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
        if let cachedImage = ImageCache.shared.cachedImage(for: asset, size: thumbnailSize) {
            DispatchQueue.main.async {
                self.image = cachedImage
                self.isLoading = false
            }
            return
        }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        manager.requestImage(for: asset,
                             targetSize: thumbnailSize,
                             contentMode: .aspectFill,
                             options: options) { image, info in
            DispatchQueue.main.async {
                self.isLoading = false
                if let image = image {
                    self.image = image
                    ImageCache.shared.setCachedImage(image, for: self.asset, size: self.thumbnailSize)
                } else {
                    self.hasError = true
                }
            }
        }
    }
}