//
//  ImageDto.swift
//  App
//
//  Created by Rémi Groult on 07/10/2019.
//

import Foundation
import Vapor

struct ImageDto {
    let contentType:String
    let data:Data
    init?(from base64Image:String){
        //TO DO : Performance
        //format: data:image/png;base64,iVBORw0K
        let pattern = "^data:(.*);base64,(.*)"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = regex?.matches(in: base64Image, options: [], range: NSMakeRange(0, base64Image.count))
        guard let match = matches?.first else { return nil}
        guard  match.numberOfRanges == 3 else { return nil}
        guard let contentTypeRange = Range(match.range(at: 1)) else { return nil}
        guard let imageData = Range(match.range(at: 2)) else { return nil}
        //contentType
        contentType = String(base64Image.prefix(contentTypeRange.endIndex).dropFirst(contentTypeRange.startIndex))
        //data
        guard let decodeData = Data(base64Encoded: String(base64Image.dropFirst(imageData.startIndex))) else { return nil}
        data = decodeData
    }
}

extension ImageDto: ResponseEncodable {
    func encode(for req: Request) throws -> EventLoopFuture<Response> {
        //TO DO : Performance
        var response = HTTPResponse(status: .ok, body:HTTPBody(data: data))
        response.headers.add(name: .contentType, value: contentType)
        return req.eventLoop.newSucceededFuture(result: Response(http: response, using: req.privateContainer))
     //   return response
        //throw "Not implemteted"
    }
}
