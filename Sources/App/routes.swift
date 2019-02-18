import Vapor
import Swiftgger
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Create builder.
    let openAPIBuilder = OpenAPIBuilder(
        title: "Mobile Distribution Tool",
        version: "3.0.0",
        description: "Open API reference of Mobile Distribution Tool.",
        authorizations: [.jwt(description: "You can get token from *login* action from *Users* controller.")]
    )
    
    // Basic "It works" example
    router.get { req -> String in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
    
    /*
    let server = try Server("mongodb://localhost:27017")
    let database = server["mobdisttool"]
    
    if server.isConnected {
        print("Connected successfully to server")
    }
    */
   
    let usersController = UsersController(apiBuilder: openAPIBuilder)
    router.get("users",use:usersController.index)
/*    let protectedGroup = router.group([GuardAuthenticationMiddleware]) { router in
        router.get("apps",use:usersController.apps)
    }*/
    
    router.get("app",use:usersController.app)
    router.get("test",use:usersController.test)
    router.get("artifacts",use:usersController.artifacts)
    router.get("find",use:usersController.findAppsForUser)
    
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
