// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-openapi-velox-serve",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OpenAPIVeloxServe",
            targets: ["OpenAPIVeloxServe"]),
    ],
    dependencies: [
        .package(url: "https://github.com/t089/velox-serve.git", branch: "routing"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OpenAPIVeloxServe",
            dependencies: [
                .product(name: "VeloxServe", package: "velox-serve"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            ]),
        .testTarget(
            name: "OpenAPIVeloxServeTests",
            dependencies: ["OpenAPIVeloxServe"]
        ),
    ]
)
