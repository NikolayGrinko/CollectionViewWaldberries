//
//  CartViewController.swift
//  CollectionViewWaldberries
//
//  Created by Николай Гринько on 01.04.2025.
//

import UIKit

class CartViewController: UIViewController, UITableViewDelegate {
    
    private let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100
        return cache
    }()
    
    private var imageLoadTasks: [IndexPath: URLSessionDataTask] = [:]
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.estimatedRowHeight = 100
        tv.isPrefetchingEnabled = true
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = #colorLiteral(red: 0.6240465045, green: 0.09995300323, blue: 0.4080937505, alpha: 1)
        tv.separatorStyle = .none
        tv.register(CartCell.self, forCellReuseIdentifier: "CartCell")
        return tv
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Корзина пуста"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 18)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let checkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
        
        preloadInitialImages()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUI),
            name: .cartDidUpdate,
            object: nil
        )
    }
    
    private func setupUI() {
        title = "Корзина"
        view.backgroundColor = #colorLiteral(red: 0.6240465045, green: 0.09995300323, blue: 0.4080937505, alpha: 1)
        
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(checkoutButton)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        
        checkoutButton.addTarget(self, action: #selector(checkoutButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: checkoutButton.topAnchor, constant: -20),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            checkoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            checkoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            checkoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            checkoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func preloadInitialImages() {
        let initialItems = min(5, CartManager.shared.cartItems.count)
        let items = Array(CartManager.shared.cartItems.prefix(initialItems))
        
        for item in items {
            loadImage(from: item.key.imageUrl)
        }
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if imageCache.object(forKey: urlString as NSString) != nil {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  error == nil else { return }
            
            self.imageCache.setObject(image, forKey: urlString as NSString)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        task.resume()
    }
    
    @objc private func updateUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let totalItems = CartManager.shared.totalItems
            let totalPrice = CartManager.shared.totalPrice
            
            self.emptyLabel.isHidden = totalItems > 0
            self.checkoutButton.isEnabled = totalItems > 0
            
            self.checkoutButton.setTitle(
                totalItems > 0 ? "Оформить заказ • $\(String(format: "%.2f", totalPrice))" : "Корзина пуста",
                for: .normal
            )
            self.checkoutButton.backgroundColor = totalItems > 0 ?
                #colorLiteral(red: 1, green: 0.233240068, blue: 0.191813916, alpha: 1) :
                #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
            
            self.tableView.reloadData()
        }
    }
    
    @objc private func checkoutButtonTapped() {
        let alert = UIAlertController(title: "Оформление заказа", message: "Введите ваши данные", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Имя"
        }
        alert.addTextField { textField in
            textField.placeholder = "Телефон"
            textField.keyboardType = .phonePad
        }
        alert.addTextField { textField in
            textField.placeholder = "Адрес доставки"
        }
        
        let confirmAction = UIAlertAction(title: "Оформить", style: .default) { [weak self] _ in
            self?.processOrder(
                name: alert.textFields?[0].text ?? "",
                phone: alert.textFields?[1].text ?? "",
                address: alert.textFields?[2].text ?? ""
            )
        }
        
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func processOrder(name: String, phone: String, address: String) {
        let successAlert = UIAlertController(
            title: "Заказ оформлен!",
            message: """
                Спасибо за заказ!
                Сумма: $\(String(format: "%.2f", CartManager.shared.totalPrice))
                
                Данные доставки:
                Имя: \(name)
                Телефон: \(phone)
                Адрес: \(address)
                """,
            preferredStyle: .alert
        )
        
        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            CartManager.shared.clearCart()
            NotificationCenter.default.post(name: .cartDidUpdate, object: nil)
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(successAlert, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDataSource
extension CartViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CartManager.shared.cartItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartCell", for: indexPath) as! CartCell
        let item = Array(CartManager.shared.cartItems)[indexPath.row]
        
        cell.configure(with: item.key, quantity: item.value)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK: - UITableViewDataSourcePrefetching
extension CartViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let items = Array(CartManager.shared.cartItems)
            guard indexPath.row < items.count else { continue }
            
            let item = items[indexPath.row]
            loadImage(from: item.key.imageUrl)
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let task = imageLoadTasks[indexPath] {
                task.cancel()
                imageLoadTasks.removeValue(forKey: indexPath)
            }
        }
    }
}

// MARK: - CartCellDelegate
extension CartViewController: CartCellDelegate {
    func cartCell(_ cell: CartCell, didUpdateQuantity quantity: Int, for product: Product) {
        let currentQuantity = CartManager.shared.getQuantity(for: product)
        
        if quantity < currentQuantity {
            CartManager.shared.removeFromCart(product)
        } else if quantity > currentQuantity {
            CartManager.shared.addToCart(product)
        }
    }
}
