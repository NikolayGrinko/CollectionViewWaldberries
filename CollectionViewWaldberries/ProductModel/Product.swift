//
//  Product.swift
//  CollectionViewWaldberries
//
//  Created by Николай Гринько on 01.04.2025.
//

import Foundation

struct Product: Codable, Hashable {
    let id: Int
    let title: String
    let price: Double
    let imageUrl: String
    let description: String
    let images: [String]
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case price
        case imageUrl = "image"
        case description
        case images
        case thumbnail
        case category
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        
        // Обработка цены
        if let priceString = try? container.decode(String.self, forKey: .price) {
            price = Double(priceString) ?? 0.0
        } else {
            price = try container.decode(Double.self, forKey: .price)
        }
        
        // Обработка URL изображений
        if let imagesArray = try? container.decode([String].self, forKey: .images) {
            images = imagesArray
        } else if let mainImage = try? container.decode(String.self, forKey: .imageUrl) {
            images = [mainImage]
        } else if let thumbnail = try? container.decode(String.self, forKey: .thumbnail) {
            images = [thumbnail]
        } else {
            images = []
        }
        
        imageUrl = images.first ?? ""
    }
    
    // Реализация Hashable для использования в Dictionary
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Кодирование для сохранения в кеш
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(price, forKey: .price)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(images, forKey: .images)
        try container.encode(imageUrl, forKey: .imageUrl)
    }
}
