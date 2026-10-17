// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BalanceCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "BalanceCore", targets: ["BalanceCore"])],
    targets: [
        .target(name: "BalanceCore", path: "DailyBalance/Models", exclude: ["PersistentModels.swift"], sources: ["Domain.swift"]),
        .testTarget(name: "BalanceCoreTests", dependencies: ["BalanceCore"], path: "CoreTests")
    ]
)
