//
//  RSSFeeds.swift
//  App
//
//  Created by Marius on 29/03/2019.
//

import Vapor

struct RSSFeed {
    let provider: String
    let category: String
    let url: String
}

/// Decodes RSSFeeds.plist into array of RSSFeed.
struct RSSFeeds {

    var all = [RSSFeed]()
    
    init() {
        guard let data = try? Data(contentsOf: Constants.URLs.rssFeed) else {
            print("Could not find RSSFeeds.plist. Check URL in Constants!")
            return
        }

        let decoder = PropertyListDecoder()
        do {
            self = try decoder.decode(RSSFeeds.self, from: data)
        } catch {
            print("Error decoding RSSFeeds: \(error)")
        }
    }
    
    private init(feeds: [RSSFeed]) {
        self.all = feeds
    }
}

extension RSSFeeds: Decodable {
    
    private struct ProviderKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
    }
    
    private struct CategoryKey: CodingKey {
        var stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        var intValue: Int? { return nil }
        init?(intValue: Int) { return nil }
    }
    
    /// The initializer loops over all of the keys of the first (provider) and second (categories) levels of nesting.
    init(from decoder: Decoder) throws {
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
