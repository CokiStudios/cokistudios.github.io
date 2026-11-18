// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HiOPCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "CLoopingStageCore", targets: ["CLoopingStageCore"]),
        .library(name: "HiOPCore", targets: ["HiOPCore"])
    ],
    targets: [
        .target(
            name: "CLoopingStageCore",
            path: "Sources/CLoopingStageCore",
            sources: ["LoopingWasm.cpp", "LoopingAsmCore.S"],
            publicHeadersPath: "include",
            cxxSettings: [
                .define("LOOPING_NO_SUBPROCESS", to: "1")
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .target(
            name: "HiOPCore",
            dependencies: ["CLoopingStageCore"],
            path: "Sources/HiOPCore"
        ),
        .testTarget(
            name: "HiOPCoreTests",
            dependencies: ["HiOPCore"],
            path: "Tests/HiOPCoreTests"
        )
    ],
    cxxLanguageStandard: .cxx17
)
