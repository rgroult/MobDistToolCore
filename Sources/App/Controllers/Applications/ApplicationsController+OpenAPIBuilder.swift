//
//  ApplicationsController+OpenAPIBuilder.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Foundation
import Swiftgger

extension ApplicationsController:APIBuilderControllerProtocol {
    
    func generateOpenAPI(apiBuilder:OpenAPIBuilder){
        //add api controller
        _ = apiBuilder.add(
            APIController(name: pathPrefix,
                          description: "Controller for Aplications",
                          actions: [
                            APIAction(method: .get, route: generateRoute(Verb.applications.rawValue),
                                      summary: "Apps",
                                      description: "Retrieve Applications",
                                      parameters: [
                                        APIParameter(name: "platorm", parameterLocation:.query, description: "Filter by platorm", required: false)
                                    ],
                                      responses: [
                                        APIResponse(code: "200", description: "All applications", object: ApplicationDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            )
                ]
            )
        )
        _ = apiBuilder.add([APIObject(object: ApplicationDto.sample())])
    }
}
