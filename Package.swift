// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BDSManager",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BDSManager", targets: ["BDSManager"]),
    ],
    targets: [
        .executableTarget(
            name: "BDSManager",
            path: "BDSManager"
        ),
    ]
)
