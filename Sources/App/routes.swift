import Vapor
import Swiftgger
import Authentication
import JWTAuth
import JWT

/// Register your application's routes here.
public func routes(_ baseRouter: Router, authenticateMiddleware:Middleware,config:MdtConfiguration) throws {
    
    let router = baseRouter.grouped(BaseController.basePathPrefix)
    
    // Create builder.
    let openAPIBuilder = OpenAPIBuilder(
        title: "Mobile Distribution Tool",
        version: "3.0.0",
        description: "Open API reference of Mobile Distribution Tool.",
        authorizations: [.jwt(description: "You can get token from *login* action from *Users* controller.")]
    )
    //common datamodel
        _ = openAPIBuilder.add([APIObject(object: MessageDto( message: "message"))])
    
    router.get("/status") { req in
        return ["name":"MobileDistributionTool Core", "version" : MDT_Version ]
    }
    //add status swagger
    openAPIBuilder.add(
        APIController(name: "",
                      description: "Status",
                      actions: [
                        APIAction(method: .get, route: "\(BaseController.basePathPrefix)/status",
                                  summary: "Status",
                                  description: "Retrieve Server status and version",
                                  responses: [
                                    APIResponse(code: "200", description: "Info"),
                            ],
                                  authorization: false
                        )
            ]
    ))
    
    
    let protected = router.grouped(authenticateMiddleware,JWTTokenPayload.guardAuthMiddleware())
    
    let usersController = UsersController(apiBuilder: openAPIBuilder)
    usersController.configure(with: router, and: protected)
    
    let appsController = ApplicationsController(apiBuilder: openAPIBuilder,externalUrl: config.serverUrl)
    appsController.configure(with: router, and: protected)
    
    let artifactController = ArtifactsController(apiBuilder: openAPIBuilder)
    artifactController.configure(with: router, and: protected)
    //router.post("testupload",use:artifactController.uploadArtifact)
    
    let activityController = ActivityController(apiBuilder: openAPIBuilder)
    activityController.configure(with: router, and: protected)

   
    //OpenAPI
    let document = openAPIBuilder.built()
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let openAPIJsonData = try encoder.encode(document)
    var openAPIJsonString = String(data: openAPIJsonData, encoding: .utf8)!
    openAPIJsonString = openAPIJsonString.replacingOccurrences(of: "\\/", with: "/")
    
    
    baseRouter.get("/swagger/swagger.json") { req  in
        return openAPIJsonString
    }
}

