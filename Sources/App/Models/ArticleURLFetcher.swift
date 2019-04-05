//
//  ArticleURLFetcher.swift
//  App
//
//  Created by Marius on 31/03/2019.
//

import Vapor
import SwiftSoup

struct ArticleURL {
    var provider: String
    var category: String
    var url: String
}

final class ArticleURLFetcher {
    
    let app: Application
    let client: Client
    
    init(on app: Application) throws {
        self.app = app
        self.client = try app.make(Client.self)
    }
    
    func fetch(from feeds: [RSSFeed]) -> Future<[ArticleURL]> {
        return feeds.map { feed in
            fetch(from: feed)
        }.flatten(on: app).map { result in
            return result.compactMap { $0 }.flatMap { $0 }
        }
    }
    
    func fetch(from feed: RSSFeed) -> Future<[ArticleURL]?> {
        return client.get(feed.url).map { response in
            return self.create(from: response, from: feed)
        }.catchMap { error -> [ArticleURL]? in
            print("Error fetching \(feed): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func create(from response: Response, from feed: RSSFeed) -> [ArticleURL]? {
        guard let responseData = response.http.body.data else { return nil }
        guard let html = String(bytes: responseData, encoding: .utf8) else { return nil }

        do {
            let doc: Document = try SwiftSoup.parse(html)
            let items = try doc.select("guid")

            return try items.compactMap { item -> ArticleURL in
                let url = try item.text()
                let cleanURL = url.cleanURL()
                return ArticleURL(provider: feed.provider, category: feed.category, url: cleanURL)
            }
        } catch {
            return nil
        }
    }
}

extension String {
    /// Fixes RSS provider's possible human error in URL.
    func cleanURL() -> String {
        return self.replacingOccurrences(of: "www.delfi.lthttps://", with: "")
    }
}
