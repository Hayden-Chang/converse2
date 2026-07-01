// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Converse",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Converse", targets: ["ConverseApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.13.0")
    ],
    targets: [
        .target(
            name: "ConverseCore",
            path: "Sources/ConverseCore"
        ),
        .executableTarget(
            name: "ConverseApp",
            dependencies: [
                "ConverseCore",
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources/ConverseApp"
        ),
        .testTarget(
            name: "ConverseCoreTests",
            dependencies: ["ConverseCore"],
            path: "Tests/ConverseCoreTests"
        ),
    ]
)
