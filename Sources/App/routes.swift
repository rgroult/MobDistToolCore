import Vapor
import Swiftgger
import Authentication
import JWTAuth
import JWT

/// Register your application's routes here.
public func routes(_ router: Router, authenticateMiddleware:Middleware) throws {
    // Create builder.
    let openAPIBuilder = OpenAPIBuilder(
        title: "Mobile Distribution Tool",
        version: "3.0.0",
        description: "Open API reference of Mobile Distribution Tool.",
        authorizations: [.jwt(description: "You can get token from *login* action from *Users* controller.")]
    )
    //common datamodel
        _ = openAPIBuilder.add([APIObject(object: MessageDto( message: "message"))])
    
    /*
    // Basic "It works" example
    router.get { req -> String in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
*//*
    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
    */
    /*
    let server = try Server("mongodb://localhost:27017")
    let database = server["mobdisttool"]
    
    if server.isConnected {
        print("Connected successfully to server")
    }
    */
    /*
    let signer = JWTSigner.hs256(key: Data("secret".utf8))
    let signers = JWTSigners()
    signers.use(signer, kid: "1234")
    
    */
    let protected = router.grouped(authenticateMiddleware,JWTTokenPayload.guardAuthMiddleware())
    
    let usersController = UsersController(apiBuilder: openAPIBuilder)
    usersController.configure(with: router, and: protected)
    
    let appsController = ApplicationsController(apiBuilder: openAPIBuilder)
    appsController.configure(with: router, and: protected)
    
    //router.get("users",use:usersController.index)
   /* let authenticable = JWTAuthenticationMiddleware(MockPayload.self,signers:signers)*/
   /* let _ = router.group([authenticable,MockPayload.guardAuthMiddleware()]) { protectedRouter in
        protectedRouter.get("/v2/Users/apps",use:usersController.apps)
    }*/
    
    /*
    protected.get("/v2/Users/apps",use:usersController.apps)
    
    router.post("/v2/Users/login",use:usersController.login)
    
    router.get("apps",use:usersController.apps)
    router.get("app",use:usersController.app)
  //  router.get("test",use:usersController.test)
    router.get("artifacts",use:usersController.artifacts)
    router.get("find",use:usersController.findAppsForUser)
    */
    let artifactController = ArtifactsController()
    router.post("testupload",use:artifactController.uploadArtifact)

   
    //OpenAPI
    let document = openAPIBuilder.built()
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let openAPIJsonData = try encoder.encode(document)
    var openAPIJsonString = String(data: openAPIJsonData, encoding: .utf8)!
    openAPIJsonString = openAPIJsonString.replacingOccurrences(of: "\\/", with: "/")
    
    
    router.get("swagger.json") { req  in
        return openAPIJsonString
    }
}

