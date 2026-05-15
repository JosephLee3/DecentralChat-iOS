// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DecentralChatCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "DecentralChatCore",
            targets: ["DecentralChatCore"]
        )
    ],
    targets: [
        .target(
            name: "DecentralChatCore"
        ),
        .testTarget(
            name: "DecentralChatCoreTests",
            dependencies: ["DecentralChatCore"]
        )
    ]
)
