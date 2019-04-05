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
    
    func returnAll() -> Future<[Article]> {
        return Article.query(on: conn).all()
    }
    
    /// Deletes expired Articles from database.
    func deleteExpired() -> Future<Void> {
        return returnAll().flatMap { articles in
            return articles.map {
                $0.date.isExpired ? $0.delete(on: self.conn) : .done(on: self.conn)
            }.flatten(on: self.conn)
        }
    }

    func saveToDatabase(_ articles: [Article]) -> Future<Void> {
        return articles.map { $0.save(on: conn) }.flatten(on: conn).transform(to: .done(on: conn))
    }
    
    func fetch(_ urls: [ArticleURL]) -> Future<[Article?]> {
        return urls.map { item in
            client.get(item.url).map { response in

                return self.create(from: response, from: item)
            }.catchMap { error -> (Article?) in
                print("Error fetching \(item): \(error)")
                return nil
            }
        }.flatten(on: app)
    }
    
    private func create(from response: Response, from articleURL: ArticleURL) -> Article? {
        guard let responseData = response.http.body.data else { return nil }
        guard var html = String(bytes: responseData, encoding: .utf8) else { return nil }

        html = html.shortenHTML(of: articleURL)

        do {
            let doc: Document = try SwiftSoup.parse(html)
            let title = try doc.select("[itemprop='headline']").text()
            let description = try doc.select("[itemprop='description']").text()
            let imageURL = try doc.select("[itemprop='image']").attr("src")
            /// If could not convert html string to date, aborts article creation.
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
            print("Error creating \(articleURL.url): \(error)")
            return nil
        }
    }
}

extension Date {
    /// Returns true if Article's publish date is older than deadline.
    var isExpired: Bool {
        let deadline = Date().addingTimeInterval(Constants.Time.expirationDeadline)
        return deadline > self
    }
}

extension String {
    /// Using regex, searches for a substring, which contains tags needed for Article creation.
    /// If not found, returns an empty string.
    /// Shortening HTML string significantly improves SwiftSoup parsing speed.
    func shortenHTML(of articleURL: ArticleURL) -> String {
        
        let regex: String
        switch articleURL.provider {
        /// <meta itemprop="datePublished"(?s).*itemprop="image"\/>
        case "delfi": regex = "<meta itemprop=\"datePublished\"(?s).*itemprop=\"image\" \\/>"
        /// <meta itemprop="datePublished"(?s).*<h4 class="intro" itemprop="description">(?s).*?<div class="clear"><\/div>
        case "15min": regex = "<meta itemprop=\"datePublished\"(?s).*<h4 class=\"intro\" itemprop=\"description\">(?s).*?<div class=\"clear\"><\\/div>"
        default: regex = ""
        }
        
        let range = self.range(of: regex, options: .regularExpression)
        if let range = range {
            return String(self[range])
        } else {
            print(articleURL.url)
            return ""
        }
    }
}

extension String {
    func convertToDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"
        return dateFormatter.date(from: self) ?? nil
    }
}
