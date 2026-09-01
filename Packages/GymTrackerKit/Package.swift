// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GymTrackerKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "GymTrackerKit", targets: ["GymTrackerKit"])
    ],
    targets: [
        .target(name: "GymTrackerKit")
    ]
)
