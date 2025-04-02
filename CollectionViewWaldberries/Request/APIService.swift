//
//  APIService.swift
//  CollectionViewWaldberries
//
//  Created by Николай Гринько on 01.04.2025.
//

import Foundation
import UIKit

// Определяем структуру для разных форматов API
struct DummyJSONWrapper: Decodable {
    let products: [Product]
    
    enum CodingKeys: String, CodingKey {
        case products
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        products = try container.decode([Product].self, forKey: .products)
    }
}

class APIService {
    static let shared = APIService()
    private let session: URLSession
    private let imageCache = NSCache<NSString, UIImage>()
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 50_000_000,
                                 diskCapacity: 100_000_000,
                                 diskPath: nil)
        session = URLSession(configuration: config)
        
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50_000_000
    }
    
    func fetchProducts(completion: @escaping ([Product]?) -> Void) {
        let urls = [
            "https://dummyjson.com/products",
            "https://fakestoreapi.com/products",
            "https://api.escuelajs.co/api/v1/products"
        ]
        
        print("Fetching products from network...")
        tryNextURL(urls: urls, currentIndex: 0, completion: completion)
    }
    
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            completion(cachedImage)
            return
        }
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self?.imageCache.setObject(image, forKey: urlString as NSString)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    private func tryNextURL(urls: [String], currentIndex: Int, completion: @escaping ([Product]?) -> Void) {
        guard currentIndex < urls.count else {
            print("All URLs failed")
            completion(nil)
            return
        }
        
        let urlString = urls[currentIndex]
        print("Trying URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            tryNextURL(urls: urls, currentIndex: currentIndex + 1, completion: completion)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.cachePolicy = .returnCacheDataElseLoad
        
        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error with \(urlString): \(error.localizedDescription)")
                self?.tryNextURL(urls: urls, currentIndex: currentIndex + 1, completion: completion)
                return
            }
            
            guard let data = data else {
                self?.tryNextURL(urls: urls, currentIndex: currentIndex + 1, completion: completion)
                return
            }
            
            do {
                let products: [Product]
                if urlString.contains("dummyjson.com") {
                    let wrapper = try JSONDecoder().decode(DummyJSONWrapper.self, from: data)
                    products = wrapper.products
                } else {
                    products = try JSONDecoder().decode([Product].self, from: data)
                }
                
                print("Successfully received \(products.count) products")
                
                DispatchQueue.main.async {
                    completion(products)
                }
            } catch {
                print("Decoding error from \(urlString): \(error)")
                self?.tryNextURL(urls: urls, currentIndex: currentIndex + 1, completion: completion)
            }
        }.resume()
    }
}
