//
//  Constants.swift
//  App
//
//  Created by Marius on 31/03/2019.
//

import Vapor

struct Constants {
    
    struct Time {
        /// Schedule database update every amount of seconds.
        static let updateTime = 300
        /// Amount of seconds after publish date for article be considered expired.
        /// Needs to be negative!
        static let expirationDeadline: Double = -172800.0
    }
    
    struct URLs {
        static var rssFeed: URL {
            let directory = DirectoryConfig.detect()
            return URL(fileURLWithPath: "\(directory.workDir)Public/RSSFeeds.plist")
        }
    }
    
}


