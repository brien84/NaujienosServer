//
//  Coordinator.swift
//  App
//
//  Created by Marius on 01/04/2019.
//

import Vapor

final class Coordinator {
    
    let app: Application
    let articleFetcher: ArticleFetcher
    let urlFetcher: ArticleURLFetcher
    
    init(on app: Application) throws {
        self.app = app
        self.articleFetcher = try ArticleFetcher(on: app)
        self.urlFetcher = try ArticleURLFetcher(on: app)
    }
    
    func start() {
        
        let feeds = RSSFeeds()
        
        urlFetcher.fetch(from: feeds.all).whenSuccess { articleURLs in
            
            self.filterArticleURLs(articleURLs: articleURLs).whenSuccess { filteredURLs in
                
                self.articleFetcher.createArticles(from: filteredURLs).whenSuccess { articles in
                    
                    let filtered = articles.compactMap { article -> Article? in
                        if let article = article, !article.date.isOlderThanTwoDays() {
                            return article
                        }
                        return nil
                    }
                    
                    self.articleFetcher.saveArticlesToDatabase(articles: filtered).whenComplete {
                        
                        self.articleFetcher.deleteOldArticles().whenComplete {
                            print("DONE")
                        }
                    }
                }
            }
        }
        
    }
    
    private func filterArticleURLs(articleURLs: [ArticleURL]) -> Future<[ArticleURL]> {
        return articleFetcher.queryDatabaseAll().map { articles in
            
            var itemsToGetArticlesFrom = [ArticleURL]()
            let urlsInDB = articles.map { $0.url }
            
            for url in articleURLs {
                if !urlsInDB.contains(url.url) {
                    itemsToGetArticlesFrom.append(url)
                }
            }
            
            return itemsToGetArticlesFrom
        }
    }
}
