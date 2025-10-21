import UIKit
import SwiftUI
import Combine

class HomeViewController: UIViewController {
    private let collectionView: UICollectionView
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
    private let errorLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let viewModel = HomeViewModel()
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(GroupCell.self, forCellWithReuseIdentifier: "GroupCell")
        collectionView.backgroundColor = .systemGroupedBackground
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photo Scanner"
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        viewModel.startScan()
        bindViewModel()
    }
    
    private func bindViewModel() {
        viewModel.$progress.sink { [weak self] progress in
            self?.progressView.progress = Float(progress)
        }.store(in: &cancellables)
        
        viewModel.$processedCount.combineLatest(viewModel.$totalCount)
            .sink { [weak self] processed, total in
                let pct = total > 0 ? Int(Double(processed)/Double(total)*100) : 0
                self?.progressLabel.text = "Scanning photos: \(processed)/\(total) (\(pct)%)"
            }.store(in: &cancellables)
        
        viewModel.$groupedAssets.sink { [weak self] _ in
            self?.collectionView.reloadData()
        }.store(in: &cancellables)
        
        viewModel.$errorMessage.sink { [weak self] errorMessage in
            self?.errorLabel.text = errorMessage
            self?.errorLabel.isHidden = errorMessage == nil
            self?.retryButton.isHidden = errorMessage == nil
        }.store(in: &cancellables)
        
        viewModel.$isScanning.sink { [weak self] isScanning in
            self?.progressView.isHidden = !isScanning && self?.viewModel.progress == 0
            self?.progressLabel.isHidden = !isScanning && self?.viewModel.progress == 0
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func setupUI() {
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        progressLabel.font = .systemFont(ofSize: 14, weight: .medium)
        progressLabel.textAlignment = .center
        
        errorLabel.font = .systemFont(ofSize: 16, weight: .medium)
        errorLabel.textAlignment = .center
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        
        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        retryButton.backgroundColor = .systemBlue
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        
        view.addSubview(progressLabel)
        view.addSubview(progressView)
        view.addSubview(errorLabel)
        view.addSubview(retryButton)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            progressLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            progressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            progressView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 6),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            
            errorLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.widthAnchor.constraint(equalToConstant: 100),
            retryButton.heightAnchor.constraint(equalToConstant: 44),
            
            collectionView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func retryTapped() {
        viewModel.startScan()
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.groupedAssets.keys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let key = Array(viewModel.groupedAssets.keys.sorted())[indexPath.item]
        let assets = viewModel.groupedAssets[key] ?? []
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupCell", for: indexPath) as! GroupCell
        cell.configure(title: key, count: assets.count)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let key = Array(viewModel.groupedAssets.keys.sorted())[indexPath.item]
        let assets = viewModel.groupedAssets[key] ?? []
        let group = PhotoGroup(rawValue: key)
        let detailView = GroupDetailView(group: group, assets: assets)
        let hostingController = UIHostingController(rootView: detailView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
}