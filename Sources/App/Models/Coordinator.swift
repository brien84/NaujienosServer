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
        app.eventLoop.scheduleTask(in: TimeAmount.seconds(300), start)
        update()
    }
    
    private func update() {
        print("Starting update!")

        let feeds = RSSFeeds()

        urlFetcher.fetch(from: feeds.all).then { articleURLs in
            self.filter(articleURLs: articleURLs)
        }.then { filteredArticleURLs in
            self.articleFetcher.fetch(filteredArticleURLs)
        }.map { articles in
            self.filter(articles: articles)
        }.then { filteredArticles in
            self.articleFetcher.saveToDatabase(filteredArticles)
        }.then {
            self.articleFetcher.deleteExpired()
        }.whenComplete {
            print("Done!")
        }
    }
    
    private func filter(articles: [Article?]) -> [Article] {
        return articles.compactMap { $0 }.filter { !$0.date.isExpired }
    }
    
    private func filter(articleURLs: [ArticleURL]) -> Future<[ArticleURL]> {
        return articleFetcher.returnAll().map { articles in

            let urlsInDB = articles.map { $0.url }
            
            return articleURLs.filter { !urlsInDB.contains($0.url) }
        }
    }
}
