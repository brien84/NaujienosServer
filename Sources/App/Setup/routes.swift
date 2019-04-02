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

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    router.post([Filter].self, at: "filter") { req, filter -> Future<[Article]> in
        
        let filters = convertFilterToItems(with: filter)
        
        if filters.count > 0 {
            return Article.query(on: req).group(.or) { orGroup in
                for filter in filters {
                    orGroup.group(.and) { (andGroup) in
                        andGroup.filter(\.provider == filter.provider).filter(\.category == filter.category)
                    }
                }
            }.all() // group by url removes duplicates from categories
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
