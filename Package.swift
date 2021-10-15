// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "MobDistTool",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.8.0")),
        //.package(url: "https://github.com/vapor/fluent.git", .upToNextMajor(from: "4.0.0")),

        // fix: https://forums.swift.org/t/logging-module-name-clash-in-vapor-3/25466
        //.package(url: "https://github.com/IBM-Swift/LoggerAPI.git", .upToNextMinor(from: "1.8.0")),
        
       // .package(url: "https://github.com/vapor-community/pagination.git", .upToNextMinor(from: "1.0.9")),
        .package(url: "https://github.com/vapor/fluent.git", .upToNextMajor(from: "4.0.0")),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        //.package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.3.0"),
        
        // 🔏 JSON Web Token signing and verification (HMAC, RSA).
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        
        // 🔏 JSON Web Token Middleware.
        .package(name:"JWTAuth", url: "https://github.com/asensei/vapor-auth-jwt", .upToNextMajor(from: "2.0.0")),
        
        // 👤 Authentication and Authorization framework for Fluent.
        //.package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
    
        
        //🐈 MongoKitten
        //.package(url: "https://github.com/OpenKitten/MeowVapor.git", from: "2.0.0"),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", from: "6.0.0"),
        
        // open APi
        .package(url: "https://github.com/mczachurski/Swiftgger.git", from: "1.3.1"),
        
        //🔐 crypto
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.0")),
        
        //🔐 Swift wrapper for zxcvbn-c
        .package(name: "zxcvbn", url: "https://github.com/vzsg/zxcvbn-swift.git", .branch("master")),
        
        //✉️ email
        //.package(url: "https://github.com/IBM-Swift/Swift-SMTP", .upToNextMinor(from: "5.1.0"))
        .package(name:"SwiftSMTP", url: "https://github.com/rgroult/Swift-SMTP.git", .branch("master")),
        //.package(path: "../Swift-SMTP")
        
        // 🧪 Test BDD
        .package(url: "https://github.com/Tyler-Keith-Thompson/CucumberSwift",.upToNextMinor(from: "3.3.6"))
       
    ],
    targets: [
        .target(name: "App", dependencies: ["SwiftSMTP","JWTAuth",
                                            .product(name: "Vapor", package: "vapor"),
                                            .product(name: "Fluent", package: "fluent"),
                                            .product(name: "JWT", package: "jwt"),
                                            .product(name: "Meow", package: "MongoKitten"),
                                            "MongoKitten","Swiftgger","CryptoSwift","zxcvbn"]),
        .target(name: "Run", dependencies: ["App"]),
        .target(name: "TestsToolkit", dependencies: ["App"],path: "Tests/TestsToolkit"),
        .testTarget(
            name: "CucumberAppTests",
            dependencies: ["App", "TestsToolkit", .product(name: "XCTVapor", package: "vapor"), "CucumberSwift"],
            resources: [.copy("Features")]
        ),
        .testTarget(name: "AppTests",dependencies: ["TestsToolkit", "App",.product(name: "XCTVapor", package: "vapor"), "CucumberSwift"])
    ]
)   

