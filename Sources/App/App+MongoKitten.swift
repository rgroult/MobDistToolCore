//
//  File.swift
//  
//
//  Created by Rémi Groult on 21/12/2020.
//

import MongoKitten
import Meow
import Vapor

extension Request {
    public var mongoDB: MongoDatabase {
        return application.mongoDB.hopped(to: eventLoop)
    }
    
    // For Meow users only
    public var meow: MeowDatabase {
        return MeowDatabase(mongoDB)
    }
    
    // For Meow users only
    public func meow<M: ReadableModel>(_ type: M.Type) -> MeowCollection<M> {
        return meow[type]
    }
}

private struct MongoDBStorageKey: StorageKey {
    typealias Value = MongoDatabase
}

extension Application {
    public var mongoDB: MongoDatabase {
        get {
            storage[MongoDBStorageKey.self]!
        }
        set {
            storage[MongoDBStorageKey.self] = newValue
        }
    }
    
    // For Meow users only
    public var meow: MeowDatabase {
        MeowDatabase(mongoDB)
    }
    
    public func initializeMongoDB(connectionString: String) throws {
        self.mongoDB = try MongoDatabase.lazyConnect(connectionString, on: self.eventLoopGroup)
    }
}
