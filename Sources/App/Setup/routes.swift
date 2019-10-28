import Routing
import Vapor
import FluentSQLite

struct Filter: Content {
    var provider: String
    var categories: [String: Bool]
}

struct FilterItem {
    var provider: String
    var category: String
}

public func routes(_ router: Router) throws {
    
    /// Decodes request to Filter object and converts it to array of FilterItems.
    /// Then returns Articles from database using query with FilterItems.
    router.post([Filter].self, at: "get") { req, filter -> Future<[Article]> in
        
        let filters = convertFilterToItems(with: filter)
        
        if filters.count > 0 {
            return Article.query(on: req).group(.or) { orGroup in
                for filter in filters {
                    orGroup.group(.and) { (andGroup) in
                        andGroup.filter(\.provider == filter.provider).filter(\.category == filter.category)
                    }
                }
            /// groupBy(\.url) removes possible duplicates, if same Article exists under many categories.
            }.groupBy(\.url).all()
        } else {
            return req.eventLoop.newSucceededFuture(result: [Article]())
        }
    }
}

private func convertFilterToItems(with filters: [Filter]) -> [FilterItem] {
    
    var items = [FilterItem]()
    
    for filter in filters {
        
        let provider = filter.provider
        
        filter.categories.forEach { key, value in
            if value {
                items.append(FilterItem(provider: provider, category: key))
            }
        }
    }
    return items
}
