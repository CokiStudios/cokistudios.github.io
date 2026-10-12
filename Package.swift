// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CSIDKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CSIDKit",
            targets: ["CSIDKit"]
        ),
    ],
    dependencies: [
        // Zero external third-party dependencies: uses standard Foundation, CryptoKit, Security & AuthenticationServices
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "CSIDKit",
            dependencies: [],
            path: "CSIDKit-Swift/Sources/CSIDKit"
        ),
        .testTarget(
            name: "CSIDKitTests",
            dependencies: ["CSIDKit"],
            path: "CSIDKit-Swift/Tests/CSIDKitTests"
        ),
    ]
)
