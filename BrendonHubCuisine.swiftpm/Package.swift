// swift-tools-version: 5.9
import PackageDescription

#if canImport(AppleProductTypes)
  import AppleProductTypes

  let package = Package(
    name: "BrendonHubCuisine",
    defaultLocalization: "fr",
    platforms: [.iOS("17.0")],
    products: [
      .iOSApplication(
        name: "Hub Cuisine",
        targets: ["AppModule"],
        bundleIdentifier: "be.brendon.hubcuisine",
        displayVersion: "1.0.0",
        bundleVersion: "1",
        appIcon: .asset("AppIcon"),
        accentColor: .asset("AccentColor"),
        supportedDeviceFamilies: [.pad, .phone],
        supportedInterfaceOrientations: [
          .portrait, .landscapeLeft, .landscapeRight,
          .portraitUpsideDown(.when(deviceFamilies: [.pad])),
        ],
        capabilities: [
          .camera(
            purposeString: "Photographier une recette ou un plat, uniquement à votre demande.")
        ]
      )
    ],
    targets: [
      .executableTarget(
        name: "AppModule", path: ".",
        exclude: [
          "Tests", "Reference", "README_IPAD.md", "README_XCODE.md", "DECISIONS.md",
          "VALIDATION.md",
        ], sources: ["Sources"], resources: [.process("Resources")])
    ],
    swiftLanguageVersions: [.v5]
  )
#else
  // Allows the same business logic to be tested with an ordinary Swift toolchain.
  let package = Package(
    name: "HubCuisineCore",
    products: [.library(name: "HubCuisineCore", targets: ["HubCuisineCore"])],
    targets: [
      .target(name: "HubCuisineCore", path: "Sources/Core"),
      .testTarget(name: "HubCuisineCoreTests", dependencies: ["HubCuisineCore"], path: "Tests"),
    ]
  )
#endif
