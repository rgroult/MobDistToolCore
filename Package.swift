// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "MobDistTool",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.1"),

        // fix: https://forums.swift.org/t/logging-module-name-clash-in-vapor-3/25466
        .package(url: "https://github.com/IBM-Swift/LoggerAPI.git", .upToNextMinor(from: "1.8.0")),
        
        .package(url: "https://github.com/vapor-community/pagination.git", .upToNextMinor(from: "1.0.9")),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        //.package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.3.0"),
        
        // 🔏 JSON Web Token signing and verification (HMAC, RSA).
        //.package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
        
        // 🔏 JSON Web Token Middleware.
        .package(url: "https://github.com/asensei/vapor-auth-jwt", .upToNextMajor(from: "1.1.0")),
        
        // 👤 Authentication and Authorization framework for Fluent.
        //.package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
    
        //🐈 MeowVapor
        .package(url: "https://github.com/OpenKitten/MeowVapor.git", from: "2.0.0"),
        
        // open APi
        .package(url: "https://github.com/mczachurski/Swiftgger.git", from: "1.3.1"),
        
        //🔐 crypto
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "0.9.0")),
        
        //🔐 Swift wrapper for zxcvbn-c
        .package(url: "https://github.com/vzsg/zxcvbn-swift.git", .branch("master")),
        
        //✉️ email
        //.package(url: "https://github.com/IBM-Swift/Swift-SMTP", .upToNextMinor(from: "5.1.0"))
        .package(url: "https://github.com/rgroult/Swift-SMTP.git", .branch("master"))
        //.package(path: "../Swift-SMTP")
       
    ],
    targets: [
        .target(name: "App", dependencies: ["SwiftSMTP","JWTAuth", "Vapor","MeowVapor","Swiftgger","CryptoSwift", "Pagination","zxcvbn"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)   

