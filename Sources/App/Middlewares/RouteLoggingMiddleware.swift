//
//  RouteLoggingMiddleware.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor

final class RouteLoggingMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        let logger = try request.make(Logger.self)
        
        let method = request.http.method
        //let path = request.http.url.path
        //let query = request.http.url.query
        //let reqString = "❕[\(method)]@\(path) with query:\(String(describing: query)) 🔍"
        var reqString = " 🔍 \(method)@ \(request.http.url.absoluteString)"
        if let size = request.http.body.count {
            reqString += " - Size:\(size)"
        }
        logger.info(reqString,file:"RouteLoggingMiddleware"/*,function: "", line: 0, column: 0*/)
        
        return try next.respond(to: request)
    }
}

extension RouteLoggingMiddleware: ServiceType {
    public static func makeService(for worker: Container) throws -> RouteLoggingMiddleware{
        return .init()
    }
}
