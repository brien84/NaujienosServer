import Vapor

/// Called after your application has initialized.
public func boot(_ app: Application) throws {
  
    let feeds = RSSFeeds()

    let urlFetcher = ArticleURLFetcher(on: app)
    
    urlFetcher.fetch(from: feeds.allFeeds).whenSuccess { articleURLs in
        
        print(articleURLs.count)
        
    }
}
