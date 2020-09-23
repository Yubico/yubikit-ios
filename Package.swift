// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "YubiKit",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "YubiKit",
            targets: ["YubiKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "YubiKit",
            path: "YubiKit/YubiKit",
            publicHeadersPath: "SPMHeaderLinks"),
        .testTarget(
            name: "YubikitTests",
            dependencies: ["YubiKit"],
            path: "Yubikit/YubiKitTests"),
    ]
)
