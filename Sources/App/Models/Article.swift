//
//  Article.swift
//  App
//
//  Created by Marius on 31/03/2019.
//

import Vapor
import FluentSQLite
import Validation

struct Article {
    
    var id: Int?
    var url: String
    var title: String
    var date: Date
    var description: String
    var imageURL: String
    var provider: String
    var category: String
}

extension Article: SQLiteModel { }

extension Article: Migration { }

extension Article: Content { }

extension Article: Validatable {
    static func validations() throws -> Validations<Article> {
        var validations = Validations(Article.self)
        try validations.add(\.url, .count(1...))
        try validations.add(\.title, .count(1...))
        try validations.add(\.description, .count(1...))
        try validations.add(\.imageURL, .count(1...))
        return validations
    }
}
