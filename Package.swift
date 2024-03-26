// swift-tools-version: 5.9
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
        .package(url: "https://github.com/openpoiesis/PoieticCore", branch: "main"),
        .package(url: "https://github.com/openpoiesis/PoieticFlows", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "PoieticServer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "PoieticCore", package: "PoieticCore"),
                .product(name: "PoieticFlows", package: "PoieticFlows"),
            ]
        ),
//        .testTarget(
//            name: "PoieticServerTests",
//            dependencies: ["PoieticServer"]),
    ]
)
