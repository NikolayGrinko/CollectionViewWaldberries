//
//  ProductCell.swift
//  CollectionViewWaldberries
//
//  Created by Николай Гринько on 01.04.2025.
//

import UIKit

// MARK: - Protocol
protocol ProductCellDelegate: AnyObject {
    func didTapProductCell(_ cell: ProductCell)
}


class ProductCell: UICollectionViewCell {
    static let reuseId = "ProductCell"
    
    // Добавляем делегат для обработки нажатия
    weak var delegate: ProductCellDelegate?
    
    private var images: [String] = []
    
    private lazy var imageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.isUserInteractionEnabled = true
        cv.delaysContentTouches = false
        return cv
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .white
        pc.pageIndicatorTintColor = .gray
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.isUserInteractionEnabled = false
        return pc
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let categoty: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let buyButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGreen
        button.setTitle("Купить", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var currentProduct: Product?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = #colorLiteral(red: 0.6240465045, green: 0.09995300323, blue: 0.4080937505, alpha: 1)
        contentView.layer.cornerRadius = 8
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 0.1
        
        isUserInteractionEnabled = true
        
        contentView.addSubview(imageCollectionView)
        contentView.addSubview(pageControl)
        contentView.addSubview(titleLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(categoty)
        contentView.addSubview(buyButton)
        
        buyButton.addTarget(self, action: #selector(buyButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            imageCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalTo: imageCollectionView.widthAnchor),
            
            pageControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 8),
            
            titleLabel.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            priceLabel.bottomAnchor.constraint(equalTo: categoty.topAnchor, constant: -8),
            
            categoty.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 4),
            categoty.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            categoty.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            categoty.bottomAnchor.constraint(lessThanOrEqualTo: buyButton.topAnchor, constant: -8),
            
            buyButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            buyButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            buyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            buyButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currentProduct = nil
        images = []
        pageControl.numberOfPages = 0
        pageControl.currentPage = 0
        titleLabel.text = nil
        categoty.text = nil
        priceLabel.text = nil
        imageCollectionView.reloadData()
        buyButton.backgroundColor = .systemGreen
        buyButton.setTitle("Купить", for: .normal)
    }
    
    func configure(with product: Product) {
        currentProduct = product
        titleLabel.text = product.title
        priceLabel.text = String(format: "%.2f $", product.price)
        categoty.text = product.category
        
        self.images = product.images
        pageControl.numberOfPages = images.count
        pageControl.isHidden = images.count <= 1
        imageCollectionView.reloadData()
        
        // Обновляем состояние кнопки
        updateBuyButton()
    }
    
    func updateBuyButton() {
        guard let product = currentProduct else { return }
        let quantity = CartManager.shared.getQuantity(for: product)
        
        if quantity > 0 {
            buyButton.backgroundColor = .systemRed
            buyButton.setTitle("В корзине (\(quantity))", for: .normal)
        } else {
            buyButton.backgroundColor = .systemGreen
            buyButton.setTitle("Купить", for: .normal)
        }
    }
    
    @objc private func buyButtonTapped() {
        guard let product = currentProduct else { return }
        
        // Добавляем анимацию нажатия
        UIView.animate(withDuration: 0.1, animations: {
            self.buyButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.buyButton.transform = .identity
            }
        }
        
        CartManager.shared.addToCart(product)
        updateBuyButton()
        
        // Добавляем тактильный отклик
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: self)
        if imageCollectionView.frame.contains(location) {
            return true
        }
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        if !imageCollectionView.frame.contains(touch.location(in: self)) {
            animate(isHighlighted: true)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animate(isHighlighted: false)
        // Уведомляем делегат о нажатии
        delegate?.didTapProductCell(self)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animate(isHighlighted: false)
    }
    
    private func animate(isHighlighted: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.transform = isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            self.contentView.alpha = isHighlighted ? 0.8 : 1.0
        }
    }
}

// MARK: - UICollectionViewDelegate
extension ProductCell: UICollectionViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Отменяем нажатие при начале скролла
        animate(isHighlighted: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Уведомляем делегат о нажатии
        delegate?.didTapProductCell(self)
    }
}

// MARK: - UICollectionViewDataSource
extension ProductCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        cell.configure(with: images[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ProductCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        pageControl.currentPage = page
    }
}
