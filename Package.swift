// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Leezi",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Leezi",
            path: "Sources/Leezi"
        )
    ]
)
