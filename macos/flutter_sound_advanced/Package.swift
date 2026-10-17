// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_sound_advanced",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "flutter-sound-advanced", targets: ["flutter_sound_advanced"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_sound_advanced",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
