import Routing
import Vapor
import Fluent

struct Filter: Content {
    var provider: String
    var categories: [String: Bool]
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    router.post([Filter].self, at: "filter") { req, filter -> Future<[Article]> in
        
        let queryParams = constructQueryParams(with: filter)
        
        return Article.query(on: req).group(.or) { orGroup in
            for key in queryParams.keys {
                guard let queryCategories = queryParams[key] else { continue }
                orGroup.group(.and) { (andGroup) in
                    andGroup.filter(\.provider == key).filter(\.category ~~ queryCategories)
                }
            }
        }.groupBy(\.url).all() // group by url removes duplicates from categories
    }
    
}

private func constructQueryParams(with filters: [Filter]) -> [String: [String]] {
    
    var queryParams = [String: [String]]()
    
    for filter in filters {
        let provider = filter.provider
        var filteredCategories = [String]()
        
        _ = filter.categories.filter { key, value in
            if value {
                filteredCategories.append(key)
            }
            return false
        }
        
        if filteredCategories.count > 0 {
            queryParams[provider] = filteredCategories
        }
    }
    return queryParams
}
