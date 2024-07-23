// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "JWTSecurityLab",
    dependencies: [
        .package(url: "https://github.com/tomieq/BootstrapStarter", branch: "master"),
        .package(url: "https://github.com/tomieq/swifter", branch: "develop"),
        .package(url: "https://github.com/tomieq/Template.swift.git", exact: "1.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "JWTSecurityLab",
            dependencies: [
                .product(name: "BootstrapTemplate", package: "BootstrapStarter"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "Template", package: "Template.swift")
            ])
    ]
)
