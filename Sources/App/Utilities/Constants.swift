//
//  Constants.swift
//  App
//
//  Created by Marius on 31/03/2019.
//

import Vapor

struct Constants {
    
    struct URLs {
        static var rssFeed: URL? {
            let directory = DirectoryConfig.detect()
            return URL(fileURLWithPath: "\(directory.workDir)Sources/App/Models/RSSFeeds.plist")
        }
    }
    
}


