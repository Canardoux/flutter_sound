// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_sound_advanced",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "flutter-sound-advanced", targets: ["flutter_sound_advanced"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_sound_core",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/flutter_sound_core")
            ],
            cxxSettings: [
                .headerSearchPath("include/flutter_sound_core")
            ],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("MediaPlayer"),
                .linkedFramework("UIKit"),
                .linkedFramework("AudioToolbox")
            ]
        ),
        .target(
            name: "flutter_sound_advanced",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "flutter_sound_core",
            ],
            exclude: [
                // Leftover Swift stub; SPM forbids mixed Swift + Objective-C++ in one target.
                "TaudioPlugin.swift",
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/flutter_sound_advanced")
            ],
            cxxSettings: [
                .headerSearchPath("include/flutter_sound_advanced")
            ]
        )
    ]
)
