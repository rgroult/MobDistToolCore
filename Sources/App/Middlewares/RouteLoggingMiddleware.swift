//
//  RouteLoggingMiddleware.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor

final class RouteLoggingMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let logger = try request.make(Logger.self)
        
        let method = request.http.method
        //let path = request.http.url.path
        //let query = request.http.url.query
        //let reqString = "❕[\(method)]@\(path) with query:\(String(describing: query)) 🔍"
        var reqString = "👉 \(method)@ \(request.http.url.absoluteString)"
        if let size = request.http.body.count {
            reqString += " - Size:\(size)"
        }
        logger.info(reqString,file:"RouteLoggingMiddleware"/*,function: "", line: 0, column: 0*/)
        logger.debug(" 🔍 Headers: \(request.http.headers.debugDescription)",file:"RouteLoggingMiddleware")
        logJsonBody(logger:logger,body: request.http.body, contentType: request.http.contentType)

        return try next.respond(to: request)
            .do({[weak self] response in
                logger.info("👈 Response \(request.http.url.absoluteString), status \(response.http.status)",file:"RouteLoggingMiddleware")
                logger.debug(" 🔍 Headers: \(response.http.headers.debugDescription)",file:"RouteLoggingMiddleware")
                self?.logJsonBody(logger:logger, body: response.http.body, contentType: response.http.contentType)
            })
    }

    private func logJsonBody(logger:Logger, body:HTTPBody, contentType:MediaType?){
        if let size = body.count, contentType == .json && size < 1_000_000 { //< 1M
            logger.debug(" 🔍 Body: \(body.debugDescription)",file:"RouteLoggingMiddleware")
        }
    }
}
/*
extension RouteLoggingMiddleware: ServiceType {
    public static func makeService(for worker: Container) throws -> RouteLoggingMiddleware{
        return .init()
    }
}*/
