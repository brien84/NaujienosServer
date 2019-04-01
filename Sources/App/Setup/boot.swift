import Vapor

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
  
    let feeds = RSSFeeds()

    let urlFetcher = try ArticleURLFetcher(on: app)
    let articleFetcher = try ArticleFetcher(on: app)
    
    
    urlFetcher.fetch(from: feeds.allFeeds).whenSuccess { articleURLs in
        
        filterArticleURLs(articleURLs: articleURLs).whenSuccess { filteredURLs in
        
            articleFetcher.createArticles(from: filteredURLs).whenSuccess { articles in
                
                let filtered = articles.compactMap { article -> Article? in
                    if let article = article, !article.date.isOlderThanTwoDays() {
                        return article
                    }
                    return nil
                }
                
                articleFetcher.saveArticlesToDatabase(articles: filtered).whenComplete {
                    
                    articleFetcher.deleteOldArticles().whenComplete {
                        print("DONE")
                    }
                }
            }
        }
    }
    
    func filterArticleURLs(articleURLs: [ArticleURL]) -> Future<[ArticleURL]> {
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
