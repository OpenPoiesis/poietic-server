// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PoieticServer",
    platforms: [.macOS("14")],
    products: [
        .executable(
            name: "poietic-server",
            targets: ["PoieticServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/openpoiesis/poietic-core", branch: "main"),
        .package(url: "https://github.com/openpoiesis/poietic-flows", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "PoieticServer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "PoieticCore", package: "poietic-core"),
                .product(name: "PoieticFlows", package: "poietic-flows"),
            ]
        ),
//        .testTarget(
//            name: "PoieticServerTests",
//            dependencies: ["PoieticServer"]),
    ]
)
