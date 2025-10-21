import UIKit

final class GroupCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    private let countLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        contentView.backgroundColor = .systemBlue.withAlphaComponent(0.15)
        contentView.layer.cornerRadius = 12
        contentView.layer.borderColor = UIColor.systemBlue.cgColor
        contentView.layer.borderWidth = 1

        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center

        countLabel.font = .systemFont(ofSize: 14)
        countLabel.textAlignment = .center
        countLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(title: String, count: Int) {
        titleLabel.text = title.uppercased()
        countLabel.text = "\(count) photos"
    }
}