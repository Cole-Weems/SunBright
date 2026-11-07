// swift-tools-version: 5.9
import PackageDescription

var dependencies: [Package.Dependency] = []
var products: [Product] = [
    .library(name: "SunBrightCore", targets: ["SunBrightCore"])
]
var targets: [Target] = [
    .target(name: "SunBrightCore"),
    .testTarget(name: "SunBrightCoreTests", dependencies: ["SunBrightCore"])
]

#if os(macOS)
dependencies.append(.package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.1"))
products.append(.executable(name: "SunBright", targets: ["SunBright"]))
targets.append(.executableTarget(
    name: "SunBright",
    dependencies: ["SunBrightCore", .product(name: "Sparkle", package: "Sparkle")],
    linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
))
targets.append(.testTarget(name: "SunBrightTests", dependencies: ["SunBright"]))
#endif

let package = Package(
    name: "SunBright",
    platforms: [.macOS(.v13)],
    products: products,
    dependencies: dependencies,
    targets: targets
)
