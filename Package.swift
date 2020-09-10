// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Yubikit",
    products: [
        .library(
            name: "Yubikit",
            targets: ["Yubikit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Yubikit",
            path: "Yubikit/Yubikit"),
        .testTarget(
            name: "YubikitTests",
            dependencies: ["Yubikit"],
            path: "YubikitFullStackTests"),
    ]
)
