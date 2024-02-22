// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PoieticServer",
    platforms: [.macOS("13.3")],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "poietic-server",
            targets: ["PoieticServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/openpoiesis/PoieticCore", branch: "main"),
        .package(url: "https://github.com/openpoiesis/PoieticFlows", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.5.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "PoieticServer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Swifter", package: "swifter"),
                .product(name: "PoieticCore", package: "PoieticCore"),
                .product(name: "PoieticFlows", package: "PoieticFlows"),
            ]
        ),
//        .testTarget(
//            name: "PoieticServerTests",
//            dependencies: ["PoieticServer"]),
    ]
)
