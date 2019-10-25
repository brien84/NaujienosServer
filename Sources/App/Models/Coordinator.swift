//
//  Coordinator.swift
//  App
//
//  Created by Marius on 01/04/2019.
//

import Vapor

/// Runs scheduled database updates, started on boot.
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
        app.eventLoop.scheduleTask(in: TimeAmount.seconds(Constants.Time.updateTime), start)
        update()
    }
    
    private func update() {
        print("Starting update.")

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
            print("Update completed.")
        }
    }
    
    /// Removes nil values and Articles which are already expired.
    private func filter(articles: [Article?]) -> [Article] {
        return articles.compactMap { $0 }.filter { !$0.date.isExpired }
    }
    
    /// Removes ArticleURL, if corresponding Article already exists in database.
    private func filter(articleURLs: [ArticleURL]) -> Future<[ArticleURL]> {
        return articleFetcher.returnAll().map { articles in

            let urlsInDB = articles.map { $0.url }
            return articleURLs.filter { !urlsInDB.contains($0.url) }
        }
    }
}
