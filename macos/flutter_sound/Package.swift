// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_sound",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "flutter-sound",
            targets: ["flutter_sound"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_sound",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/flutter_sound",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
