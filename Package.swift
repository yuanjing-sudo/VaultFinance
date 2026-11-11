// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "VaultFinance",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "VaultFinance", targets: ["VaultFinance"]),
    ],
    targets: [
        .target(
            name: "VaultFinance",
            path: "Sources/VaultFinance"
        ),
    ]
)
