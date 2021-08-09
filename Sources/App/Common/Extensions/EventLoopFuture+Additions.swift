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
    /// Adds a callback for handling this `Future`'s result if an error occurs.
    ///
    ///     futureString.do { string in
    ///         print(string)
    ///     }.catch { error in
    ///         print("oops: \(error)")
    ///     }
    ///
    /// - note: Will *only* be executed if an error occurs. Successful results will not call this handler.
    @discardableResult
    public func `catch`(_ callback: @escaping (Error) -> ()) -> EventLoopFuture<Value> {
        whenFailure(callback)
        return self
    }
}
