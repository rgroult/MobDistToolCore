//
//  ApplicationsController.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Foundation
import Vapor
import Swiftgger
import Meow

final class ApplicationsController:BaseController {
    
    init(apiBuilder:OpenAPIBuilder) {
        super.init(version: "v2", pathPrefix: "Applications", apiBuilder: apiBuilder)
    }
    
    func applications(_ req: Request) throws -> Future<[ApplicationDto]> {
        var platformFilter:Platform?
        if let platormString = try? req.query.get(String.self, at: "platorm") {
            guard let platform = Platform(rawValue:platormString) else {
                let error = Abort(.badRequest,reason: "Bad filter, values are [\(Platform.ios),\(Platform.android)]")
                throw error }
            platformFilter = platform
        }
        
        return try retrieveUser(from:req)
            .flatMap{user in
                guard let user = user else { throw Abort(.unauthorized)}
                return req.meow().flatMap({ context -> Future<[ApplicationDto]> in
                    let query:Query
                    if let platorm = platformFilter {
                        query = Query.valEquals(field: "platform", val: platorm.rawValue)
                    }else {
                        query = Query()
                    }
                    return context.find(MDTApplication.self,where:query)
                        .map(transform: { app  in
                            return ApplicationDto.create(from: app, content:app.isAdmin(user: user) ? .full : .light , in : context)
                        })
                        .getAllResults()
                        .flatMap {elements ->  Future<[ApplicationDto]> in
                            return elements.flatten(on: context)
                    }
                })
        }
    }
}
