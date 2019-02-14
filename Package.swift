// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MobDistTool",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
    
        //🐈 MeowVapor
        .package(url: "https://github.com/OpenKitten/MeowVapor.git", from: "2.0.0"),
        
        .package(url: "https://github.com/mczachurski/Swiftgger.git", from: "1.2.1")
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", "Vapor","MeowVapor","Swiftgger"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)   

