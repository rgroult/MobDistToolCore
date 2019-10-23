//
//  ActivityController+OpenAPIBuilder.swift
//  App
//
//  Created by Rémi Groult on 22/10/2019.
//

import Foundation
import Swiftgger

extension ActivityController:APIBuilderControllerProtocol {
    func generateOpenAPI(apiBuilder: OpenAPIBuilder) {
        _ = apiBuilder.add(
        APIController(name: pathPrefix,
                      description: "Controller for Monitoring",
                      actions: [
                        //Metrics Summary
                        APIAction(method: .get, route: generateRoute(Verb.summary.uri),
                                  summary: "Summary",
                                  description: "Retrieve system metrics summary",
                                  responses: [
                                    APIResponse(code: "200", description: "All applications", object: MetricsSummaryDto.self),
                                    APIResponse(code: "500", description: "Internal Error"),
                                    APIResponse(code: "401", description: "Authentication error Error"),
                                    APIResponse(code: "400", description: "Request error")
                            ],
                                  authorization: true
                        ),
                        //Logs activity
                        APIAction(method: .get, route: generateRoute(Verb.logsActivity.uri),
                                  summary: "Logs",
                                  description: "Retrieve System Logs",
                                  parameters:[ APIParameter(name: "lines", parameterLocation:.query, description: "Number of last lines (default: 150)", required: false)],
                                  responses: [
                                    APIResponse(code: "200", description: "All applications", object: MessageDto.self),
                                    APIResponse(code: "500", description: "Internal Error"),
                                    APIResponse(code: "401", description: "Authentication error Error"),
                                    APIResponse(code: "400", description: "Request error")
                            ],
                                  authorization: true
                        ),
                        //Logs activity
                        APIAction(method: .get, route: generateRoute(Verb.trackingActivity.uri),
                                  summary: "Activity",
                                  description: "Retrieve System Tracking Activity",
                                  parameters:[ APIParameter(name: "lines", parameterLocation:.query, description: "Number of last lines (default: 150)", required: false)],
                                  responses: [
                                    APIResponse(code: "200", description: "All applications", object: MessageDto.self),
                                    APIResponse(code: "500", description: "Internal Error"),
                                    APIResponse(code: "401", description: "Authentication error Error"),
                                    APIResponse(code: "400", description: "Request error")
                            ],
                                  authorization: true
                        )]
            )
        )
        _ = apiBuilder.add([
                        APIObject(object: MetricsSummaryDto.sample()),
                        ])
    }
}
