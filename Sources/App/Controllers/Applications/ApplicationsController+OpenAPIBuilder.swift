//
//  ApplicationsController+OpenAPIBuilder.swift
//  App
//
//  Created by Rémi Groult on 20/02/2019.
//

import Foundation
import Swiftgger
import Pagination

extension ApplicationsController:APIBuilderControllerProtocol {
    
    func generateOpenAPI(apiBuilder:OpenAPIBuilder){
        //add api controller
        _ = apiBuilder.add(
            APIController(name: pathPrefix,
                          description: "Controller for Aplications",
                          actions: [
                            //All apps
                            APIAction(method: .get, route: generateRoute(Verb.allApplications.uri),
                                      summary: "Apps",
                                      description: "Retrieve Applications",
                                      parameters:generatePaginationParameters(sortby: Array(sortFields.keys), searchByField: "name")
                                            +
                                            [APIParameter(name: "platform", parameterLocation:.query, description: "Filter by platorm -  [\(Platform.android),\(Platform.ios)]", required: false)],
                                      responses: [
                                        APIResponse(code: "200", description: "All applications", object: Paginated<ApplicationSummaryDto>.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            //Favorites apps
                            APIAction(method: .get, route: generateRoute(Verb.favoritesApp.uri),
                                      summary: "Favorites Apps",
                                      description: "Retrieve user favorites Applications",
                                      responses: [
                                        APIResponse(code: "200", description: "Favorites applications", object: [ApplicationSummaryDto].self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            //Manage App
                            APIAction(method: .post, route: generateRoute(Verb.allApplications.uri),
                                      summary: "Create App",
                                      description: "Create new Application",
                                      request: APIRequest(object: ApplicationCreateDto.self, description: "App info."),
                                      responses: [
                                        APIResponse(code: "200", description: "application created", object: ApplicationDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            APIAction(method: .put, route: generateRoute(Verb.specificApp(pathName: "uuid").uri),
                                      summary: "Update App",
                                      description: "Update new Application",
                                      parameters: [
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true)
                                ],
                                      request: APIRequest(object: ApplicationUpdateDto.self, description: "App info."),
                                responses: [
                                    APIResponse(code: "200", description: "applications updated", object: ApplicationDto.self),
                                    APIResponse(code: "500", description: "Internal Error"),
                                    APIResponse(code: "401", description: "Authentication error Error"),
                                    APIResponse(code: "400", description: "Request error")
                                ],
                                authorization: true
                            ),
                            APIAction(method: .get, route: generateRoute(Verb.specificAppIcon(pathName: "uuid").uri),
                                      summary: "Application icon",
                                      description: "Retrieve Application icon",
                                      parameters: [
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true)
                                ],
                                      responses: [
                                        APIResponse(code: "200", description: "applications updated", object: Data.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: false
                            ),
                            APIAction(method: .get, route: generateRoute(Verb.specificApp(pathName: "uuid").uri),
                                      summary: "Get App Detail",
                                      description: "Get all Application Info",
                                      parameters: [
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true)
                                ],
                                      responses: [
                                        APIResponse(code: "200", description: "applications updated", object: ApplicationDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            APIAction(method: .delete, route: generateRoute(Verb.specificApp(pathName: "uuid").uri),
                                      summary: "Delete App",
                                      description: "Delete existing Application",
                                      parameters: [
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true)
                                ],
                                      responses: [
                                        APIResponse(code: "200", description: "sucess", object: MessageDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            //Admins
                            APIAction(method: .put, route: generateRoute(Verb.specificAppAdmins(pathName: "uuid", email:"email").uri),
                                      summary: "Add admin Users",
                                      description: "Add admin user for this Application",
                                      parameters: [
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true),
                                        APIParameter(name: "email", parameterLocation:.path, description: "Admin email", required: true)
                                ],
                                      responses: [
                                        APIResponse(code: "200", description: "applications updated", object: MessageDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            APIAction(method: .delete, route: generateRoute(Verb.specificAppAdmins(pathName: "uuid", email:"email").uri),
                                      summary: "Delete admin Users",
                                      description: "Delete admin user for this Application",
                                      parameters: [
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true),
                                        APIParameter(name: "email", parameterLocation:.path, description: "Admin email", required: true)
                                ],
                                      responses: [
                                        APIResponse(code: "200", description: "applications updated", object: MessageDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            //App versions
                            APIAction(method: .get, route: generateRoute(Verb.specificAppVersions(pathName: "uuid").uri),
                                      summary: "Application versions",
                                      description: "Retrieve versions for specified app",
                                      parameters: generatePaginationParameters(sortby: Array(artifactsSortFields.keys), searchByField: nil) +
                                        [
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true),
                                        APIParameter(name: "branch", parameterLocation:.query, description: "Specific branch", required: false)
                                ],//artifactsSortFields
                                      responses: [
                                        APIResponse(code: "200", description: "applications versions", object: Paginated<ArtifactDto>.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            //App versions grouped
                            APIAction(method: .get, route: generateRoute(Verb.specificAppVersionsGrouped(pathName: "uuid").uri),
                                      summary: "Application versions grouped",
                                      description: "Retrieve grouped versions for specified app",
                                      parameters: generatePaginationParameters(sortby: Array(artifactsSortFields.keys), searchByField: nil) +
                                        [
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true),
                                        APIParameter(name: "branch", parameterLocation:.query, description: "Specific branch", required: false)
                                ],//artifactsSortFields
                                      responses: [
                                        APIResponse(code: "200", description: "applications versions", object: Paginated<ArtifactGroupedDto>.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            //App versions latest
                            APIAction(method: .get, route: generateRoute(Verb.specificAppLatestVersions(pathName: "uuid").uri),
                                      summary: "Application latest versions",
                                      description: "Retrieve latest versions for specified app",
                                      parameters:generatePaginationParameters(sortby: Array(artifactsSortFields.keys), searchByField: nil) +
                                        [
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true)
                                ],
                                      responses: [
                                        APIResponse(code: "200", description: "applications latest versions", object: Paginated<ArtifactDto>.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: true
                            ),
                            //App max version
                            APIAction(method: .get, route: generateRoute(Verb.maxVersion(pathName: "uuid", branch: "branch", versionName: "name").uri),
                                      summary: "Max Version",
                                      description: "Retrieve max version off application for name and specific branch",
                                      parameters:[
                                        APIParameter(name: "uuid", parameterLocation:.path, description: "Application uuid", required: true),
                                        APIParameter(name: "branch", parameterLocation:.path, description: "Application branch", required: true),
                                        APIParameter(name: "name", parameterLocation:.path, description: "Artifact name", required: true),
                                        APIParameter(name: "ts", parameterLocation:.query, description: "Timestamp of url signaure", required: true),
                                        APIParameter(name: "hash", parameterLocation:.query, description: "Hash of url signature with secret", required: true)
                                ],
                                      responses: [
                                        APIResponse(code: "200", description: "Max Artifact Version", object: MaxVersionArtifactDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: false
                            )
                ]
            )
        )
        _ = apiBuilder.add([APIObject(object: ApplicationDto.sample()),
                            APIObject(object: ApplicationSummaryDto.sample()),
                            APIObject(object: ApplicationUpdateDto.sample()),
                            APIObject(object: ApplicationCreateDto.sample()),
                            APIObject(object: MaxVersionArtifactDto.sample()),
                            APIObject(object: Paginated.sample(obj: ApplicationSummaryDto.sample())),
                            APIObject(object: Paginated.sample(obj: ArtifactDto.sample())),
                            APIObject(object: Paginated.sample(obj: ArtifactGroupedDto.sample()))
            ])
    }
}
