//
//  Codable+HTTPBodyConvertion.swift
//  AppTests
//
//  Created by Rémi Groult on 08/04/2019.
//

import Foundation
import Vapor
import XCTVapor

extension Encodable {
    //TO REMOVE
    public func convertToHTTPBody() throws -> Encodable {
        return self
        //fatalError("TODO")
        //return .init(data: try JSONEncoder().encode(self))
      // return try JSONEncoder().encode(self).convertToHTTPBody()
    }
    
    public func wait() -> Self {
        return self
    }
}

extension XCTHTTPResponse {
    public var http:XCTHTTPResponse {
        return  self
    }
}

extension ResponseType {
    public  var http:ResponseType {
        return  self
    }
}

extension ClientResponse {
    public  var bodyData:Data {
        guard var body = body else { return Data() }
        return body.readData(length: body.readableBytes) ?? Data()
    }
    public  var bodyCount:Int {
        return body?.readableBytes ?? 0
    }
}
