// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MobDistTool",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        
        // 🔏 JSON Web Token signing and verification (HMAC, RSA).
        //.package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
        
        // 🔏 JSON Web Token Middleware.
        .package(url: "https://github.com/asensei/vapor-auth-jwt", .upToNextMajor(from: "1.0.0")),
        
        // 👤 Authentication and Authorization framework for Fluent.
        //.package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
    
        //🐈 MeowVapor
        .package(url: "https://github.com/OpenKitten/MeowVapor.git", from: "2.0.0"),
        
        // open APi
        .package(url: "https://github.com/mczachurski/Swiftgger.git", from: "1.2.1"),
        
        //🔐 crypto
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "0.9.0"))
    ],
    targets: [
        .target(name: "App", dependencies: ["JWTAuth","FluentSQLite", "Vapor","MeowVapor","Swiftgger","CryptoSwift"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)   

