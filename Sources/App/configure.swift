//import FluentSQLite
import Vapor
import MongoKitten
import Meow
import JWTAuth
import JWT

let signerIdentifier = "mdt_jwt_signer"

// Use this to avoid SEGFAULT on heavy load on HMAC : create new JWRTSigner every time, no reuse
struct MDT_Signers:JWTSignerRepository {
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
}

/// Called before your application initializes.
public func configure(_ app: Application) throws {
//public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    //load config
    let configuration:MdtConfiguration
    do {
        print("Loading Config")
        configuration = try MdtConfiguration.loadConfig(from: nil, from: app.environment)
        print("config: \(configuration)")
    }catch {
        print("Unable to read configuration: \(error)")
        throw error
    }
    /*
    try MdtFileLogger.initialize(logDirectory: configuration.logDirectory, includeTimestamps: true)
    MdtFileLogger.shared.logLevel = configuration.logLevelAsLevel
    services.register(Logger.self) { container throws -> MdtFileLogger in
        return MdtFileLogger.shared
    }*/
    app.mdtLogger = try .init(logDirectory: configuration.logDirectory, includeTimestamps: true)
    
  /*  try MdtActivityFileLogger.initialize(logDirectory: configuration.logDirectory, includeTimestamps: true)
    services.register(ActivityLogger.self) { container throws -> MdtActivityFileLogger in
        return MdtActivityFileLogger.sharedActivity
    }*/
    app.activityLogger = try .init(logDirectory: configuration.logDirectory, includeTimestamps: true)
    
//app.grouped(<#T##path: PathComponent...##PathComponent#>)
   // config.prefer(MdtFileLogger.self, for: Logger.self)
    //logger
    switch env {
    case .production: config.prefer(MdtFileLogger.self, for: Logger.self)
    default: config.prefer(PrintLogger.self, for: Logger.self)
    }
    
    services.register(configuration)
    
    //email if needed
    if !configuration.automaticRegistration {
        guard let smtpConfig = configuration.smtpConfiguration else { throw "Smtp configuration needed if automaticRegistration is disabled" }
        let emailService = try EmailService(with: smtpConfig, externalServerUrl: configuration.serverUrl)
        services.register(emailService)
    }
    
    //Meow
    let meow = try MeowProvider(uri: configuration.mongoServerUrl.absoluteString,lazy: true)
    try services.register(meow)
    
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
    
    //Storage
    let storageProtocol:StorageServiceProtocol
    switch configuration.storageMode {
    case .local:
        //need to register instance of concrete class, not interface
        let storage = LocalStorageService()
        storageProtocol = storage
        services.register(storage, as: StorageServiceProtocol.self)
        
    case .testing:
        //need to register instance of concrete class, not interface
        let storage = TestingStorageService()
        storageProtocol = storage
        services.register(storage, as: StorageServiceProtocol.self)
    }
        //initialization
    if !(try storageProtocol.initializeStore(with: configuration.storageConfiguration ?? [:])) {
        throw "Unable to initialize storage"
    }
    // Register routes to the router
    let router = EngineRouter.default()
    //basePath
    BaseController.basePathPrefix = configuration.pathPrefix
    //let baseRouter = router.grouped(configuration.basePathPrefix)
    try routes(router,authenticateMiddleware: authenticationMiddleware,config:configuration)
    services.register(router, as: Router.self)
    services.register(RouteLoggingMiddleware.self)
    
    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(RouteLoggingMiddleware.self) // logging requests
    /*if !env.isRelease {
         middlewares.use(RouteLoggingMiddleware.self) // logging requests
    }*/
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    
    
    //CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin,
                         HTTPHeaderName("x-mimetype"),HTTPHeaderName("x-sortidentifier"),HTTPHeaderName("x-metatags"),HTTPHeaderName("x-filename")]
    )
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    middlewares.use(corsMiddleware)
    
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response

    services.register(middlewares)
   
    //custom config
    app.http.server.configuration.port = configuration.serverListeningPort
    app.http.server.configuration.hostname = "0.0.0.0"
    app.routes.defaultMaxBodySize = 2_000_000_000
    app.http.server.configuration.responseCompression = .enabled
    //var myServerConfig = NIOServerConfig.default()
    //myServerConfig.port = configuration.serverListeningPort
    //myServerConfig.hostname = "0.0.0.0"
   // myServerConfig.maxBodySize = 2_000_000_000
   // myServerConfig.supportCompression = configuration.enableCompression
   // services.register(myServerConfig)
}
