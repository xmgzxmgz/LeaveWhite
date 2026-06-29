// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "LeaveWhite",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LeaveWhite", targets: ["LeaveWhite"]),
        .library(name: "LeaveWhiteCore", targets: ["LeaveWhiteCore"])
    ],
    targets: [
        .target(
            name: "LeaveWhiteCore"
        ),
        .executableTarget(
            name: "LeaveWhite",
            dependencies: ["LeaveWhiteCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "LeaveWhiteCoreTests",
            dependencies: ["LeaveWhiteCore"]
        )
    ]
)
