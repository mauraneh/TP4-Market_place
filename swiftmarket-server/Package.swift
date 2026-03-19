// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swiftmarket-server",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Pinned to avoid the newer swift-configuration transitive dependency,
        // which fails to compile on some local toolchain setups.
        .package(url: "https://github.com/swift-server/async-http-client.git", exact: "1.30.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.119.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.10.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.7.1"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftmarketServer",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
            ]
        )
    ]
)
