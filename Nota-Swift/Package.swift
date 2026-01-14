// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Nota",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Nota", targets: ["Nota"])
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "Nota",
            dependencies: [],
            path: "Sources",
            resources: [
                .copy("../icons")
            ]
        )
    ]
)