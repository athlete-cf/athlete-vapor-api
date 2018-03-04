// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "athlete-api",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0-rc.1.1"),
        
        // 🔵 Swift ORM (queries, models, relations, etc) built on PostgreSQL.
        .package(url: "https://github.com/vapor/fluent-postgresql.git", .exact("1.0.0-rc.1.1")),
        
        .package(url: "https://github.com/vapor/jwt.git", .exact("3.0.0-rc.1")),
    ],
    targets: [
        .target(name: "App", dependencies: [
            "FluentPostgreSQL",
            "Vapor",
            "JWT"
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)

