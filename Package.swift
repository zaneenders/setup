// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "setup",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-subprocess.git", branch: "main",
            traits: [
                // "SubprocessSpan", // TODO Swift 6.2
                "SubprocessFoundation"
            ])
    ],
    targets: [
        .executableTarget(
            name: "setup",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess")
            ])
    ]
)
