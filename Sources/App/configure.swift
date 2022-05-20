//import FluentSQLite
import Vapor
import MongoKitten
import Meow
import JWTAuth
import JWT
import Logging

let signerIdentifier = "mdt_jwt_signer"

// Use this to avoid SEGFAULT on heavy load on HMAC : create new JWRTSigner every time, no reuse
/*struct MDT_Signers:JWTSignerRepository {
    let key:String
    
    public func signer() -> JWTSigner {
        return JWTSigner.hs256(key: Data(key.utf8))
    }
    public func get(kid: String, on worker: Container) throws -> Future<JWTSigner> {
        return worker.future(signer())
    }
    static func makeService(for container: Container) throws -> Self {
        throw "Unable to make empty service"
    }
}*/

var loggingSystemAlreadyBootstrapped = false

/// Called before your application initializes.
public func configure(_ app: Application) throws {
    //configuration
    
    let configuration:MdtConfiguration
    do {
        print("Loading Config")
        configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        print("config: \(configuration)")
    }catch {
        print("Unable to read configuration: \(error)")
        throw error
    }
    app.mdtConfiguration = configuration
    
    //Logging
    let mdtLogger = try MdtFileLogger(logDirectory: configuration.logDirectory, includeTimestamps: true)
    //force duplicate logging on startup
    mdtLogger.duplicateOnStandartOutput = true
    app.mdtLogger = mdtLogger //try .init(logDirectory: config.logDirectory, includeTimestamps: true)
    try app.appFileLogger().logLevel = configuration.logLevelAsLevel
    
    //need this for unittests because app restarted into test and LoggingSystem forbids 2 bootstrap
    if !loggingSystemAlreadyBootstrapped {
            loggingSystemAlreadyBootstrapped = true
        LoggingSystem.bootstrap { name in
            //print("REQUESTED \(name)")
            return mdtLogger
        }
    }
    //force reload of app logger
    app.logger = .init(label: app.logger.label)
    
//public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    //load config
   /* let configuration:MdtConfiguration
    do {
        print("Loading Config")
        configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        print("config: \(configuration)")
    }catch {
        print("Unable to read configuration: \(error)")
        throw error
    }
    app.mdtConfiguration = configuration*/
   
    /*
    try MdtFileLogger.initialize(logDirectory: configuration.logDirectory, includeTimestamps: true)
    MdtFileLogger.shared.logLevel = configuration.logLevelAsLevel
    services.register(Logger.self) { container throws -> MdtFileLogger in
        return MdtFileLogger.shared
    }*/
    
    
  /*  try MdtActivityFileLogger.initialize(logDirectory: configuration.logDirectory, includeTimestamps: true)
    services.register(ActivityLogger.self) { container throws -> MdtActivityFileLogger in
        return MdtActivityFileLogger.sharedActivity
    }*/
    app.activityLogger = try .init(logDirectory: configuration.logDirectory, includeTimestamps: true)
    
//app.grouped(<#T##path: PathComponent...##PathComponent#>)
   // config.prefer(MdtFileLogger.self, for: Logger.self)
    //logger
  /*  switch env {
    case .production: config.prefer(MdtFileLogger.self, for: Logger.self)
    default: config.prefer(PrintLogger.self, for: Logger.self)
    }*/
    
    //services.register(configuration)
    
    //email if needed
    if !configuration.automaticRegistration {
        guard let smtpConfig = configuration.smtpConfiguration else { throw "Smtp configuration needed if automaticRegistration is disabled" }
        let emailService = try EmailService(with: smtpConfig, externalServerUrl: configuration.serverUrl)
        //services.register(emailService)
        app.emailService = emailService
    }
    
    //Meow
    try app.initializeMongoDB(connectionString: configuration.mongoServerUrl.absoluteString)
  //  let meow = try MeowProvider(uri: configuration.mongoServerUrl.absoluteString,lazy: true)
   // try services.register(meow)
  /*
    // register Authentication provider
    let jwtProvider = JWTAuthProvider()
   // try! services.register(AuthenticationProvider())
    
    try services.register(jwtProvider)
    
    //JWT
   /* let signer = JWTSigner.hs256(key: Data("secret".utf8))
    let signers = JWTSigners()
    signers.use(signer, kid: signerIdentifier)
    services.register(signers)*/
    let mdtSigners = MDT_Signers(key: configuration.jwtSecretToken)
    services.register(mdtSigners)
    let authenticationMiddleware = JWTAuthenticationMiddleware(JWTTokenPayload.self,signers:mdtSigners)
    */
    app.jwt.signers.use(.hs256(key: configuration.jwtSecretToken))
    //// Create a route group that requires the TestUser JWT.
    //let secure = app.grouped(TestUser.authenticator(), TestUser.guardMiddleware())
    
    //Storage
    let storageProtocol:StorageServiceProtocol
    switch configuration.storageMode {
    case .local:
        //need to register instance of concrete class, not interface
        let storage = LocalStorageService()
        storageProtocol = storage
        app.storageService = storage
        //services.register(storage, as: StorageServiceProtocol.self)
        
    case .testing:
        //need to register instance of concrete class, not interface
        let storage = TestingStorageService()
        storageProtocol = storage
        app.storageService = storage
        //services.register(storage, as: StorageServiceProtocol.self)
    }
        //initialization
    if !(try storageProtocol.initializeStore(with: configuration.storageConfiguration ?? [:])) {
        throw "Unable to initialize storage"
    }
    // Register routes to the router
    //let router = EngineRouter.default()
    let router = app.routes
    //basePath
    BaseController.basePathPrefix = configuration.pathPrefix
    //let baseRouter = router.grouped(configuration.basePathPrefix)
    try routes(router,authenticateMiddleware: JWTTokenPayload.authenticator(),config:configuration)
   
    app.middleware.use(RouteLoggingMiddleware())
    app.middleware.use(FileMiddleware(publicDirectory: "Public"))
    //services.register(router, as: Router.self)
    //services.register(RouteLoggingMiddleware.self)
    
    // Register middleware
    /*
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(RouteLoggingMiddleware.self) // logging requests
    /*if !env.isRelease {
         middlewares.use(RouteLoggingMiddleware.self) // logging requests
    }*/
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    */
    
    //CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin,
                         HTTPHeaders.Name("x-mimetype"),HTTPHeaders.Name("x-sortidentifier"),HTTPHeaders.Name("x-metatags"),HTTPHeaders.Name("x-filename")]
    )
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(corsMiddleware)
    //middlewares.use(corsMiddleware)
    
    //middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    //services.register(middlewares)
   
    //custom config
    app.http.server.configuration.port = configuration.serverListeningPort
    app.http.server.configuration.hostname = "0.0.0.0"
    app.routes.defaultMaxBodySize = 2_000_000_000
    app.http.server.configuration.responseCompression = configuration.enableCompression ? .enabled : .disabled
    //var myServerConfig = NIOServerConfig.default()
    //myServerConfig.port = configuration.serverListeningPort
    //myServerConfig.hostname = "0.0.0.0"
   // myServerConfig.maxBodySize = 2_000_000_000
   // myServerConfig.supportCompression = configuration.enableCompression
   // services.register(myServerConfig)
    
    try boot(app)
    //print all availables routes
    app.logger.info("Available routes:\n \(app.routes.description)")
    
    //update duplicate logging
    switch app.environment {
    case .production: mdtLogger.duplicateOnStandartOutput = false
    default: mdtLogger.duplicateOnStandartOutput = true
    }
}
