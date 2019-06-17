//
//  Application+Tests.swift
//  AppTests
//
//  Created by Rémi Groult on 22/02/2019.
//

import XCTest
import Vapor
import App

extension Application {
    static func runningAppTest(loadingEnv:Environment? = nil) throws -> Application {
        var config = Config.default()
        var env = loadingEnv ?? Environment.xcode
        var services = Services.default()
        try configure(&config, &env, &services)
        let app = try Application.asyncBoot(config: config, environment: env, services: services).wait()
        
        try app.asyncRun().wait()
        return app
    }
    
    static func runningTest(port: Int, configure: ((Router) throws -> ())?) throws -> Application {
        let router = EngineRouter.default()
        try configure?(router)
        var services = Services.default()
        services.register(router, as: Router.self)
        let serverConfig = NIOServerConfig(
            hostname: "localhost",
            port: port,
            backlog: 8,
            workerCount: 1,
            maxBodySize: 128_000,
            reuseAddress: true,
            tcpNoDelay: true, supportCompression: false,
            webSocketMaxFrameSize: 1 << 14
        )
        services.register(serverConfig)
        let app = try Application.asyncBoot(config: .default(), environment: .xcode, services: services).wait()
        try app.asyncRun().wait()
        return app
    }
    
    func clientTest(
        _ method: HTTPMethod,
        _ path: String,
        _ body: HTTPBody? = nil,
        token: String? = nil,
        beforeSend: (Request) throws -> () = { _ in },
        afterSend: (Response) throws -> ()
        ) throws {
        let config = try make(NIOServerConfig.self)
        let path = path.hasPrefix("/") ? path : "/\(path)"
        let req = Request(
            http: .init(method: method, url: "http://localhost:\(config.port)" + path),
            using: self
        )
        if let body = body {
            req.http.body = body
            req.http.contentType = .json
        }
        
        if let token = token {
            req.http.headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        
        try beforeSend(req)
        let res = try FoundationClient.default(on: self).send(req).wait()
        try afterSend(res)
    }
    
    func clientSyncTest (
        _ method: HTTPMethod,
        _ path: String,
        _ body: HTTPBody? = nil,
        _ query: [String: String]? = nil,
        token: String? = nil,
        beforeSend: (Request) throws -> () = { _ in },
        isAbsoluteUrl:Bool = false) throws -> Response {
        let config = try make(NIOServerConfig.self)
        let urlString:String
        if isAbsoluteUrl {
           urlString = path
        }else {
            let path = path.hasPrefix("/") ? path : "/\(path)"
            urlString = "http://localhost:\(config.port)" + path
        }
        let req = Request(
            http: .init(method: method, url: urlString),
            using: self
        )
        if let body = body {
            req.http.body = body
            req.http.contentType = .json
        }
        if let query = query {
            try req.query.encode(query)
        }
        if let token = token {
            req.http.headers.add(name: "Authorization", value: "Bearer \(token)")
        }
        try beforeSend(req)
        return  try FoundationClient.default(on: self).send(req).wait()
    }
    
    func clientTest(_ method: HTTPMethod, _ path: String, equals: String) throws {
        return try clientTest(method, path) { res in
            let bodyString = String(data: res.http.body.data ?? Data(), encoding: .ascii)
            XCTAssertEqual(bodyString, equals)
        }
    }
}
