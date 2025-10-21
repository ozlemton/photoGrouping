# PhotoGrouping 📸

## 🎯 Overview

PhotoGrouping analyzes photos in the user's library, generates deterministic values for each image, and groups them into 20 distinct categories based on predefined ranges. The app provides a seamless user experience with progressive scanning, real-time updates, and efficient memory management.

## ✨ Features

### Core Functionality
- **📱 Photo Library Scanning**: Scans all images using PHAsset framework
- **🔢 Deterministic Grouping**: Uses SHA256-based hashing for consistent grouping
- **📊 20 Distinct Groups**: Predefined non-contiguous ranges for photo categorization
- **🔄 Progressive Scanning**: Live updates during scanning process
- **💾 Persistence**: Scan progress and results saved to JSON files
- **🔄 Resume Capability**: Continues scanning from where it left off

### User Interface
- **🏠 Home Screen**: UICollectionView displaying photo groups
- **📋 Group Detail**: SwiftUI grid view showing photos in selected group
- **🖼️ Image Detail**: Full-screen photo viewer with swipe navigation
- **📈 Progress Tracking**: Real-time progress bar and percentage display
- **⚠️ Error Handling**: Comprehensive error states and retry functionality

### Performance & Memory Management
- **🚀 Image Caching**: Intelligent caching system for thumbnails and full images
- **💾 Memory Optimization**: Memory warning handling and efficient resource usage
- **⚡ Batch Processing**: 50-asset batches for optimal performance
- **🔄 Background Processing**: Non-blocking UI with background scanning

## 🏗️ Architecture

### MVVM Pattern
- **Model**: `PhotoGroup`, `PhotoHelper` (PHAsset extension)
- **View**: `HomeViewController`, `GroupDetailView`, `ImageDetailView`
- **ViewModel**: `HomeViewModel` with reactive data binding

### SOLID Principles
- **Single Responsibility**: Each class has a focused purpose
- **Open/Closed**: Extensible design for future enhancements
- **Liskov Substitution**: Proper inheritance hierarchy
- **Interface Segregation**: Small, focused interfaces
- **Dependency Inversion**: High-level modules independent of low-level details

## 📁 Project Structure

```
PhotoGroupingApp/
├── Models/
│   └── PhotoGroup.swift          # Photo grouping logic and ranges
├── ViewModels/
│   └── HomeViewModel.swift       # MVVM business logic
├── Views/
│   ├── Home/
│   │   ├── HomeViewController.swift  # UIKit main screen
│   │   └── GroupCell.swift          # Custom collection view cell
│   ├── GroupDetail/
│   │   └── GroupDetailView.swift    # SwiftUI group detail
│   └── ImageDetail/
│       └── ImageDetailView.swift    # SwiftUI image viewer
├── Services/
│   ├── PhotoScanner.swift        # Core scanning logic
│   └── ImageCache.swift          # Image caching system
├── Helpers/
│   └── PhotoHelper.swift         # PHAsset extension
└── Info.plist                   # App configuration
```

## 🛠️ Technical Requirements

- **Language**: Swift 5.0+
- **iOS Target**: 15.0+ (Currently set to 18.5)
- **Architecture**: MVVM with Combine framework
- **UI Framework**: UIKit + SwiftUI hybrid
- **Dependencies**: None (Pure iOS frameworks)
- **Persistence**: JSON file-based (No Core Data)

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 15.0+ device or simulator
- Photo library access permission

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ozlemton/PhotoGroupingApp.git
   cd PhotoGroupingApp
   ```

2. **Open in Xcode**
   ```bash
   open PhotoGroupingApp.xcodeproj
   ```

3. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

### Configuration

The app will automatically request photo library access on first launch. Grant permission to enable photo scanning functionality.

## 📱 Usage

### Scanning Photos
1. Launch the app
2. Grant photo library access when prompted
3. Watch the progress bar as photos are scanned
4. Groups will appear progressively as scanning continues

### Viewing Groups
1. Tap on any group cell to view photos in that group
2. Use the grid view to browse photos
3. Tap any photo to view it in full screen

### Image Navigation
1. In full-screen view, swipe left/right to navigate between photos
2. Use the close button (X) to return to group view
3. View current position with the index counter (X/Y)

## 🔧 Key Components

### PhotoScanner
- Handles photo library scanning
- Implements batch processing for memory efficiency
- Provides real-time progress updates
- Manages persistence of scan results

### ImageCache
- Intelligent caching system for images
- Separate caches for thumbnails and full images
- Memory pressure handling
- Automatic cleanup on memory warnings

### PhotoGroup
- Defines 20 distinct grouping ranges
- Provides deterministic grouping logic
- Handles "Other" category for unmatched photos



## 🐛 Known Issues

- None currently identified

## 🚧 Future Enhancements

- [ ] Custom grouping algorithms
- [ ] Export functionality for grouped photos
- [ ] Advanced filtering options
- [ ] Cloud sync capabilities
- [ ] Batch operations on groups

