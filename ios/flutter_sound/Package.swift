// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_sound",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "flutter-sound",
            targets: ["flutter_sound"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/Canardoux/flutter_sound_core.git",
            revision: "e26e592fa4c40c89a13cf630920df915f9303852"
        )
    ],
    targets: [
        .target(
            name: "flutter_sound",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(
                    name: "flutter-sound-core",
                    package: "flutter_sound_core"
                ),
                "flutter_sound_privacy"
            ],
            path: "Sources/flutter_sound",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("AVFoundation")
            ]
        ),
        .target(
            name: "flutter_sound_privacy",
            path: "Sources/flutter_sound_privacy",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
