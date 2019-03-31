//
//  RSSFeeds.swift
//  App
//
//  Created by Marius on 29/03/2019.
//

import Foundation
import Vapor

struct RSSFeed {
    let provider: String
    let category: String
    let url: String
}

struct RSSFeeds {

    var feeds = [RSSFeed]()
    
    init() {
        guard let url = Constants.URLs.rssFeed else { return }
        guard let data = try? Data(contentsOf: url) else { return }

        let decoder = PropertyListDecoder()
        do {
            self = try decoder.decode(RSSFeeds.self, from: data)
        } catch {
            print("Error decoding RSSFeeds: \(error)")
        }
    }
    
    init(feeds: [RSSFeed]) {
        self.feeds = feeds
    }
}

extension RSSFeeds: Decodable {
    
    struct ProviderKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
    }
    
    struct CategoryKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
    }
    
    public init(from decoder: Decoder) throws {
        var feeds = [RSSFeed]()
        
        let providers = try decoder.container(keyedBy: ProviderKey.self)
        
        for providerKey in providers.allKeys {
            
            let categories = try providers.nestedContainer(keyedBy: CategoryKey.self, forKey: providerKey)
            for categoryKey in categories.allKeys {
                
                let url = try categories.decode(String.self, forKey: categoryKey)
                let feed = RSSFeed(provider: providerKey.stringValue, category: categoryKey.stringValue, url: url)
                feeds.append(feed)
            }
        }
        
        self.init(feeds: feeds)
    }
}
