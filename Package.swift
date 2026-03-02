// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacRoutine",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MacRoutine",
            path: "Sources/MacRoutine",
            exclude: ["Info.plist"]  // Info.plist is not supported as SPM resource
        ),
    ]
)
