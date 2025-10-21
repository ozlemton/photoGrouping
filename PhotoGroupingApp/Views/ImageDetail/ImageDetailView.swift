import SwiftUI
import Photos

struct ImageDetailView: View {
    let asset: PHAsset
    let assets: [PHAsset]
    @State private var currentIndex: Int = 0
    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                } else if hasError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Failed to load image")
                            .foregroundColor(.white)
                            .font(.headline)
                        Button("Retry") {
                            fetchImage(for: currentIndex)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                
                Text("\(currentIndex + 1) / \(assets.count)")
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            if let index = assets.firstIndex(where: { $0.localIdentifier == asset.localIdentifier }) {
                currentIndex = index
                fetchImage(for: currentIndex)
            }
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width < -50 { nextImage() }
                else if value.translation.width > 50 { previousImage() }
            }
        )
    }
    
    private func fetchImage(for index: Int) {
        guard assets.indices.contains(index) else { return }
        
        let currentAsset = assets[index]
        
        if let cachedImage = ImageCache.shared.cachedFullImage(for: currentAsset) {
            DispatchQueue.main.async {
                self.isLoading = false
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.image = cachedImage
                }
            }
            return
        }
        
        isLoading = true
        hasError = false
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact

        manager.requestImage(for: currentAsset,
                             targetSize: PHImageManagerMaximumSize,
                             contentMode: .aspectFit,
                             options: options) { image, info in
            DispatchQueue.main.async {
                self.isLoading = false
                if let image = image {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.image = image
                    }
                    ImageCache.shared.setCachedFullImage(image, for: currentAsset)
                } else {
                    self.hasError = true
                }
            }
        }
    }
    
    private func nextImage() {
        let newIndex = min(currentIndex + 1, assets.count - 1)
        if newIndex != currentIndex {
            currentIndex = newIndex
            fetchImage(for: currentIndex)
        }
    }
    
    private func previousImage() {
        let newIndex = max(currentIndex - 1, 0)
        if newIndex != currentIndex {
            currentIndex = newIndex
            fetchImage(for: currentIndex)
        }
    }
}