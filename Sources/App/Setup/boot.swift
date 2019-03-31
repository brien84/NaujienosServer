import Vapor

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
  
    let feeds = RSSFeeds()

    let urlFetcher = try ArticleURLFetcher(on: app)
    let articleFetcher = try ArticleFetcher(on: app)
    
    urlFetcher.fetch(from: feeds.allFeeds).whenSuccess { articleURLs in
        
        articleFetcher.createArticles(from: articleURLs).whenSuccess { articles in
            
            let filtered = articles.compactMap { $0 }
            
            articleFetcher.saveArticlesToDatabase(articles: filtered).whenComplete {
                print("GOOSH")
                articleFetcher.deleteOldArticles().whenComplete {
                    print("DONE")
                }
                
            }
            
        }
        
    }
}
