// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Tegak",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Tegak", targets: ["Tegak"])],
    targets: [
        .target(name: "TegakCore"),
        .executableTarget(name: "Tegak", dependencies: ["TegakCore"]),
        .testTarget(name: "TegakCoreTests", dependencies: ["TegakCore"])
    ]
)
