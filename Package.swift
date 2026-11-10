// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sela",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Sela", targets: ["Sela"])],
    targets: [
        .target(name: "SelaCore"),
        .executableTarget(name: "Sela", dependencies: ["SelaCore"]),
        .testTarget(name: "SelaCoreTests", dependencies: ["SelaCore"])
    ]
)
