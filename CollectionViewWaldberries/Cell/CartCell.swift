//
//  CartCell.swift
//  CollectionViewWaldberries
//
//  Created by Николай Гринько on 02.04.2025.
//

import UIKit

// MARK: - CartCell
class CartCell: UITableViewCell {
    private static let imageCache = NSCache<NSString, UIImage>()
    private var imageLoadTask: URLSessionDataTask?
    
    weak var delegate: CartCellDelegate?
    private var product: Product?
    
    private let productImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var minusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("-", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        button.addTarget(self, action: #selector(minusButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        button.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
        contentView.addSubview(productImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(minusButton)
        contentView.addSubview(quantityLabel)
        contentView.addSubview(plusButton)
        
        NSLayoutConstraint.activate([
            productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            productImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            productImageView.widthAnchor.constraint(equalToConstant: 80),
            productImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            priceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            minusButton.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 16),
            minusButton.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 30),
            
            quantityLabel.leadingAnchor.constraint(equalTo: minusButton.trailingAnchor, constant: 8),
            quantityLabel.centerYAnchor.constraint(equalTo: minusButton.centerYAnchor),
            quantityLabel.widthAnchor.constraint(equalToConstant: 40),
            
            plusButton.leadingAnchor.constraint(equalTo: quantityLabel.trailingAnchor, constant: 8),
            plusButton.centerYAnchor.constraint(equalTo: minusButton.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadTask?.cancel()
        imageLoadTask = nil
        productImageView.image = nil
    }
    
    func configure(with product: Product, quantity: Int) {
        self.product = product
        
        titleLabel.text = product.title
        priceLabel.text = String(format: "%.2f $", product.price)
        quantityLabel.text = "\(quantity)"
        
        loadImage(for: product)
    }
    
    private func loadImage(for product: Product) {
        imageLoadTask?.cancel()
        
        if let cachedImage = CartCell.imageCache.object(forKey: product.imageUrl as NSString) {
            self.productImageView.image = cachedImage
            return
        }
        
        guard let imageUrl = URL(string: product.imageUrl) else { return }
        
        imageLoadTask = URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  error == nil,
                  self.product?.id == product.id else { return }
            
            DispatchQueue.main.async {
                CartCell.imageCache.setObject(image, forKey: product.imageUrl as NSString)
                self.productImageView.image = image
            }
        }
        imageLoadTask?.resume()
    }
    
    static func clearImageCache() {
        imageCache.removeAllObjects()
    }
    
    @objc private func minusButtonTapped() {
        guard let product = product else { return }
        let currentQuantity = CartManager.shared.getQuantity(for: product)
        if currentQuantity > 0 {
            delegate?.cartCell(self, didUpdateQuantity: currentQuantity - 1, for: product)
        }
    }
    
    @objc private func plusButtonTapped() {
        guard let product = product else { return }
        let currentQuantity = CartManager.shared.getQuantity(for: product)
        delegate?.cartCell(self, didUpdateQuantity: currentQuantity + 1, for: product)
    }
}

protocol CartCellDelegate: AnyObject {
    func cartCell(_ cell: CartCell, didUpdateQuantity quantity: Int, for product: Product)
}
