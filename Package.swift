// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var package = Package(
    name: "BMXSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BMXCore",
            targets: [ "BMXCore" ]),
        .library(
            name: "BMXCall",
            targets: [ "BMXCall" ]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.1")),
        .package(url: "https://github.com/OAuthSwift/OAuthSwift.git", .upToNextMajor(from: "2.2.0")),
        .package(url: "https://github.com/infinum/Japx.git", .upToNextMajor(from: "4.0.0")),
        .package(name: "TwilioVideo", url: "https://github.com/twilio/twilio-video-ios.git", .upToNextMinor(from: "5.1.0"))
    ],
    targets: [
        .target(
            name: "BMXCore",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "OAuthSwift", package: "OAuthSwift"),
                .product(name: "Japx", package: "Japx"),
                .product(name: "JapxAlamofire", package: "Japx"),
            ],
            path: "BMXCore"
        ),
        .target(
            name: "BMXCall",
            dependencies: ["BMXCore", "TwilioVideo"],
            path: "BMXCall"
        )
    ]
)