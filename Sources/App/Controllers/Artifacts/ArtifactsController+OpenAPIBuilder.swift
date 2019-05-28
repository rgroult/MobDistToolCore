//
//  ArtifactsController+OpenAPIBuilder.swift
//  App
//
//  Created by Rémi Groult on 08/04/2019.
//

import Foundation
import Swiftgger

extension ArtifactsController:APIBuilderControllerProtocol {
    
    func generateOpenAPI(apiBuilder:OpenAPIBuilder){
        //add api controller
        let verb = Verb.artifacts(apiKeyPathName: "apiKey", branchPathName: "branch", versionPathName: "version", namePathName: "artifactName")
        _ = apiBuilder.add(
            APIController(name: pathPrefix,
                          description: "Controller for Artifacts provisionning",
                          actions: [
                            APIAction(method: .post, route: generateRoute(verb.uri),
                                      summary: "Create Artifact",
                                      description: "Create artifact with apiKey",
                                      parameters: [
                                        APIParameter(name: "apiKey", parameterLocation:.path, description: "Api Key", required: true),
                                        APIParameter(name: "branch", parameterLocation:.path, description: "Branch name (ex: master,release,...)", required: true),
                                        APIParameter(name: "version", parameterLocation:.path, description: "Artifact version (ex:X.Y.Z)", required: true),
                                        APIParameter(name: "artifactName", parameterLocation:.path, description: "Artifact name (ex:prod,demo,...)", required: true),
                                        APIParameter(name: "x-mimetype", parameterLocation:.header, description: "Artifact content Type [IPA:application/octet-stream ipa] [APK:application/vnd.android.package-archive]", required: true),
                                        
                                        //Additionals headers
                                        APIParameter(name: "X_MDT_filename", parameterLocation:.header, description: "Artifact filename", required: false),
                                        APIParameter(name: "X_MDT_sortIdentifier", parameterLocation:.header, description: "Sort identifier for identifiant, if not provided, version is used", required: false),
                                        APIParameter(name: "X_MDT_metaTags", parameterLocation:.header, description: "Additional metatags for this Artifact", required: false)
                                ],
                                      request: APIRequest(object: Data.self, description: "Artifact binary",contentType:"application/octet-stream"),
                                      responses: [
                                        APIResponse(code: "200", description: "Artifact created", object: ApplicationDto.self),
                                        APIResponse(code: "500", description: "Internal Error"),
                                        APIResponse(code: "401", description: "Authentication error Error"),
                                        APIResponse(code: "400", description: "Request error")
                                ],
                                      authorization: false
                            )
                ]
            )
        )
        _ = apiBuilder.add([APIObject(object: ArtifactDto.sample())])
    }
}
