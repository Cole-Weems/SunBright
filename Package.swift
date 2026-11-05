// swift-tools-version: 5.9
import PackageDescription

var products: [Product] = [
    .library(name: "SunBrightCore", targets: ["SunBrightCore"])
]
var targets: [Target] = [
    .target(name: "SunBrightCore"),
    .testTarget(name: "SunBrightCoreTests", dependencies: ["SunBrightCore"])
]

#if os(macOS)
products.append(.executable(name: "SunBright", targets: ["SunBright"]))
targets.append(.executableTarget(name: "SunBright", dependencies: ["SunBrightCore"]))
#endif

let package = Package(
    name: "SunBright",
    platforms: [.macOS(.v13)],
    products: products,
    targets: targets
)
