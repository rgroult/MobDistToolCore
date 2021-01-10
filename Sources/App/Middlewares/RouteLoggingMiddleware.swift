//
//  RouteLoggingMiddleware.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor

final class RouteLoggingMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let logger = request.logger// try request.make(Logger.self)
        
        let method = request.method
        //let path = request.http.url.path
        //let query = request.http.url.query
        //let reqString = "❕[\(method)]@\(path) with query:\(String(describing: query)) 🔍"
        var reqString = "👉 \(method)@ \(request.url.description)"
        if let size = request.headers[.contentLength].first /*  .body.count*/ {
            reqString += " - Size:\(size)"
        }
        logger.info(.init(stringLiteral:reqString),file:"RouteLoggingMiddleware"/*,function: "", line: 0, column: 0*/)
        logger.debug(" 🔍 Headers: \(request.headers.debugDescription)",file:"RouteLoggingMiddleware")
        logJsonBody(logger:logger,body: request.body, contentType: request.content.contentType)

        return next.respond(to: request)
            .do({[weak self] response in
                logger.info("👈 Response \(request.url.description), status \(response.status)",file:"RouteLoggingMiddleware")
                logger.debug(" 🔍 Headers: \(response.headers.debugDescription)",file:"RouteLoggingMiddleware")
                self?.logJsonBody(logger:logger, body: response.body, contentType: response.content.contentType)
            })
    }

    private func logJsonBody(logger:Logger, body:Response.Body, contentType:HTTPMediaType?){
        if let size = body.data?.count, contentType == .json && size < 1_000_000 { //< 1M
            logger.debug(" 🔍 Body: \(body.description)",file:"RouteLoggingMiddleware")
        }
    }
    
    private func logJsonBody(logger:Logger, body:Request.Body, contentType:HTTPMediaType?){
        if let size = body.data?.readableBytes, contentType == .json && size < 1_000_000 { //< 1M
            logger.debug(" 🔍 Body: \(body.description)",file:"RouteLoggingMiddleware")
        }
    }
}
/*
extension RouteLoggingMiddleware: ServiceType {
    public static func makeService(for worker: Container) throws -> RouteLoggingMiddleware{
        return .init()
    }
}*/
