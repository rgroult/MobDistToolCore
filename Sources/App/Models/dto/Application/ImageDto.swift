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
    private init?(from base64Image:String?){
        guard let base64Image = base64Image else { return nil }
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
    
    static func create(within eventLoop:EventLoop, base64Image:String?,alternateBase64:String? = nil) -> Future<ImageDto?> {
        let promise = eventLoop.newPromise(ImageDto?.self)
        
        /// Dispatch  work to happen on a background thread
        DispatchQueue.global().async {
            var imageDecoded = ImageDto(from: base64Image)
            if let alternateBase64 = alternateBase64, imageDecoded == nil {
                imageDecoded = ImageDto(from: alternateBase64)
            }
            promise.succeed(result: imageDecoded)
        }
        
        return promise.futureResult
    }
    static func create(for req:Request, base64Image:String?) -> Future<ImageDto?> {
        return create(within: req.eventLoop, base64Image: base64Image)
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
