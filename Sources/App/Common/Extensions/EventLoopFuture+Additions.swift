//
//  File.swift
//  
//
//  Created by gogetta on 30/12/2020.
//

import Vapor

extension EventLoopFuture {
    /// Adds a callback for handling this `EventLoopFuture`'s result when it becomes available.
    ///
    ///     futureString.do { string in
    ///         print(string)
    ///     }
    ///
    public func `do`(_ callback: @escaping (Value) -> ()) -> EventLoopFuture<Value> {
        whenSuccess(callback)
        return self
    }
}
