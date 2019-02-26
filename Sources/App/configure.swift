import FluentSQLite
import Vapor
import MeowVapor
import JWTAuth
import JWT

let signerIdentifier = "mdt_jwt_signer"

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    //load config
    let configuration:MdtConfiguration
    do {
        print("Loading Config")
        configuration = try MdtConfiguration.loadConfig(from: nil, from: env)
        print("config: \(configuration)")
    }catch {
        print("Unable to read configuration: \(error)")
        throw error
    }
    
    services.register(Logger.self) { container throws -> MdtFileLogger in
         return try MdtFileLogger(logDirectory: configuration.logDirectory, includeTimestamps: true)
    }
    
    //logger
    switch env {
    case .production: config.prefer(MdtFileLogger.self, for: Logger.self)
    default: config.prefer(PrintLogger.self, for: Logger.self)
    }
    
    services.register(configuration)
    // Register providers first
   // try services.register(FluentSQLiteProvider())
    
    //Meow
    let meow = try MeowProvider(configuration.mongoServerUrl.absoluteString)
    try services.register(meow)
    
    // register Authentication provider
    let jwtProvider = JWTAuthProvider()
    
    try services.register(jwtProvider)
    
    //JWT
    let signer = JWTSigner.hs256(key: Data("secret".utf8))
    let signers = JWTSigners()
    signers.use(signer, kid: signerIdentifier)
    services.register(signers)
    let authenticationMiddleware = JWTAuthenticationMiddleware(JWTTokenPayload.self,signers:signers)
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router,authenticateMiddleware: authenticationMiddleware)
    services.register(router, as: Router.self)
    services.register(RouteLoggingMiddleware.self)
    
    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    if !env.isRelease {
         middlewares.use(RouteLoggingMiddleware.self) // logging requests
    }
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
   
    //custom config
    var myServerConfig = NIOServerConfig.default()
    myServerConfig.port = configuration.serverListeningPort
    myServerConfig.maxBodySize = 2_000_000_000
    services.register(myServerConfig)

    // Configure a SQLite database
    /*let sqlite = try SQLiteDatabase(storage: .memory)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)
*/
  
    // Configure migrations
    //var migrations = MigrationConfig()
//    migrations.add(model: Todo.self, database: .sqlite)
//    services.register(migrations)
}
