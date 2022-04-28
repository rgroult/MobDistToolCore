//
//  Application+Tests.swift
//  AppTests
//
//  Created by Rémi Groult on 22/02/2019.
//

import XCTest
import XCTVapor
import Vapor
import App
@testable import App

public let nilBody:String? = nil
public typealias RequestType = ClientRequest //XCTHTTPRequest
public typealias ResponseType = ClientResponse //XCTHTTPResponse
public typealias Application = Vapor.Application

extension Application {
   /* static func runningAppTest(loadingEnv:Environment? = nil) throws -> Application {
        var config = Config.default()
        var env = loadingEnv ?? Environment.xcode
        var services = Services.default()
        try configure(&config, &env, &services)
        let app = try Application.asyncBoot(config: config, environment: env, services: services).wait()
        
        try app.asyncRun().wait()
        return app
    }*/
    
    public static func runningAppTest(loadingEnv:Environment? = nil) throws -> Application {
        var env = loadingEnv ?? Environment.xcode
        let app = try Application(env)
        try configure(app)
        try app.start()
        //return try app.testable(method: .running(port: 8081))
        
        return app
    }
    
    /*static func runningTest(port: Int, configure: ((Router) throws -> ())?) throws -> Application {
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
    }*/
    public func clientTest(
        _ method: HTTPMethod,
        _ path: String,
        _ query: [String: String]? = nil,
        token: String? = nil,
        beforeSend: (inout RequestType) throws -> () = { _ in },
        afterSend: (ResponseType) throws -> ()
        ) throws {
        try clientTest(method, path, nilBody, token: token, beforeSend: {req in
            if let query = query {
                try req.query.encode(query)
            }
            try beforeSend(&req)
        }, afterSend: afterSend)
    }
    public func clientTest<T:Content>(
        _ method: HTTPMethod,
        _ path: String,
        _ body: T?,
        token: String? = nil,
        beforeSend: (inout RequestType) throws -> () = { _ in },
        afterSend: (ResponseType) throws -> ()
        ) throws {
        
        let mdtConfig = try appConfiguration()
        let requestUri:String
        if let url = URL(string: path) , url.scheme != nil { //absolute Url
            requestUri = url.absoluteString
        }else {
            let path = path.hasPrefix("/") ? path : "/\(path)"
            requestUri = "http://0.0.0.0:\(mdtConfig.serverListeningPort)/" + mdtConfig.pathPrefix + path
            //requestUri = mdtConfig.pathPrefix + path
        }
        /*
        let beforeRequest:((inout RequestType) throws -> Void) = {req in
            if  let body = body {
                try req.content.encode(body)
                req.headers.contentType = .json
            }
            if let token = token {
                req.headers.add(name: "Authorization", value: "Bearer \(token)")
            }
            try beforeSend(&req)
        }
        */
        let response = try client.send(method, to: .init(string: requestUri)){req in
            if  let body = body {
                try req.content.encode(body)
                req.headers.contentType = .json
            }
            if let token = token {
                req.headers.add(name: "Authorization", value: "Bearer \(token)")
            }
            try beforeSend(&req)
           // print("BODY : \(req.body?.string)")
        }.wait()
        
        try afterSend(response)
        /*
        if needExternalAccess {
            client.send(method, to: .init(string: requestUri)){req in
                if  let body = body {
                    try req.content.encode(body)
                    req.headers.contentType = .json
                }
                if let token = token {
                    req.headers.add(name: "Authorization", value: "Bearer \(token)")
                }
            }
            //client.get(.init(path: requestUri))
            
            let testApp = try testable(method: .running(port: mdtConfig.serverListeningPort))
            try testApp.test(method, requestUri,beforeRequest:beforeRequest, afterResponse:{ res in try afterSend(res) })
        }   else {
            try test(method, requestUri,beforeRequest:beforeRequest, afterResponse:{ res in try afterSend(res) })
        }*/
        
        /*
        let requestPath:String
        if let url = URL(string: path) , url.host == "localhost", url.port == mdtConfig.serverListeningPort { //truncate host
            requestPath = url.path
        }else {
            let path = path.hasPrefix("/") ? path : "/\(path)"
            requestPath = mdtConfig.pathPrefix + path
        }
       */
        
      //  let testApp = try testable(method: .running(port: mdtConfig.serverListeningPort))
        /*
        try test(method,requestPath , beforeRequest: { req in
            if  let body = body {
                try req.content.encode(body)
                req.headers.contentType = .json
            }
            if let token = token {
                req.headers.add(name: "Authorization", value: "Bearer \(token)")
            }
            try beforeSend(&req)
          //  print("BODY : \(req.body.string)")
            
        }, afterResponse: { res in
            try afterSend(res)
        })
        */
        /*
        let config = try make(NIOServerConfig.self)
        let path = path.hasPrefix("/") ? path : "/\(path)"
        let mdtConfig = try make(MdtConfiguration.self)
        let req = Request(
            http: .init(method: method, url: "http://0.0.0.0:\(config.port)" + mdtConfig.pathPrefix + path),
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
        */
    }
    public func clientSyncTest (
        _ method: HTTPMethod,
        _ path: String,
        _ query: [String: String]? = nil,
        token: String? = nil,
        beforeSend: (inout RequestType) throws -> () = { _ in },
        isAbsoluteUrl:Bool = false) throws -> ResponseType {
        return try clientSyncTest(method, path, nilBody,query,token: token, beforeSend:beforeSend)
    }
    
    public func clientSyncTest<T:Content> (
        _ method: HTTPMethod,
        _ path: String,
        _ body: T?,
        _ query: [String: String]? = nil,
        token: String? = nil,
        beforeSend: (inout RequestType) throws -> () = { _ in },
        isAbsoluteUrl:Bool = false) throws -> ResponseType {
        
        var response:ResponseType!
        try clientTest(method, path, body, token: token, beforeSend: { req in
            if let query = query {
                try req.query.encode(query)
            }
            try beforeSend(&req)
        }) {res  in
            response = res
        }
        
        return response
    
        /*
        let config = try make(NIOServerConfig.self)
        let mdtConfig = try make(MdtConfiguration.self)
        let urlString:String
        if isAbsoluteUrl {
           urlString = path
        }else {
            let path = path.hasPrefix("/") ? path : "/\(path)"
            urlString = "http://0.0.0.0:\(config.port)" + mdtConfig.pathPrefix + path
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
        */
    }
    
    public func clientTest(_ method: HTTPMethod, _ path: String, equals: String) throws {
        fatalError("TODO")
        /*
        return try clientTest(method, path) { res in
            let bodyString = String(data: res.http.body.data ?? Data(), encoding: .ascii)
            XCTAssertEqual(bodyString, equals)
        }*/
    }
    
    
}
