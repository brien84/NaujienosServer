//
//  ArticleFetcher.swift
//  App
//
//  Created by Marius on 31/03/2019.
//

import Vapor
import FluentSQLite
import SwiftSoup

final class ArticleFetcher {
    
    let app: Application
    let client: Client
    let conn: SQLiteConnection
    
    init(on app: Application) throws {
        self.app = app
        self.client = try app.make(Client.self)
        self.conn = try app.newConnection(to: .sqlite).wait()
    }
    
    func queryDatabaseAll() -> Future<[Article]> {
        return Article.query(on: conn).all()
    }
    
    func deleteOldArticles() -> Future<Void> {
        return queryDatabaseAll().flatMap { articles in
            return articles.map { $0.date.isOlderThanTwoDays() ? $0.delete(on: self.conn) : .done(on: self.conn) }.flatten(on: self.conn)
        }
    }

    func saveArticlesToDatabase(articles: [Article]) -> Future<Void> {
        return articles.map { $0.save(on: conn) }.flatten(on: conn).transform(to: .done(on: conn))
    }
    
    func createArticles(from urls: [ArticleURL]) -> Future<[Article?]> {
        return urls.map { item in
            client.get(item.url).map { response in
                
                return self.createArticle(from: response, from: item)
                
            }.catchMap { error -> (Article?) in
                print("Error fetching \(item): \(error)")
                return nil
            }
        }.flatten(on: app)
    }
    
    private func createArticle(from response: Response, from articleURL: ArticleURL) -> Article? {
        guard let responseData = response.http.body.data else { return nil }
        guard let html = String(bytes: responseData, encoding: .utf8) else { return nil }
        
        do {
            let doc: Document = try SwiftSoup.parse(html)
            let title = try doc.select("[itemprop='headline']").text()
            let description = try doc.select("[itemprop='description']").text()
            let imageURL = try doc.select("[itemprop='image']").attr("src")
            let optionalDate = try doc.select("[itemprop='datePublished']").attr("content").convertToDate()
            guard let date = optionalDate else { return nil }
            
            let newArticle = Article(id: nil,
                                     url: articleURL.url,
                                     title: title,
                                     date: date,
                                     description: description,
                                     imageURL: imageURL,
                                     provider: articleURL.provider,
                                     category: articleURL.category)
            
            try newArticle.validate()
            
            return newArticle
        } catch {
            print("Error creating Article: \(error)")
            return nil
        }
    }
}

extension Date {
    func isOlderThanTwoDays() -> Bool {
        let deadline = Date().addingTimeInterval(-172800)
        return self < deadline
    }
}

extension String {
    func convertToDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"
        return dateFormatter.date(from: self) ?? nil
    }
}
