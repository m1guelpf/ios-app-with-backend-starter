import ProjectDescription

let project = Project(
    name: "{{NAME}}",
    options: .options(
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    packages: [
        .remote(url: "https://github.com/kean/Pulse", requirement: .upToNextMajor(from: "5.1.2")),
        .remote(url: "https://github.com/Square/Valet", requirement: .upToNextMajor(from: "5.0.0")),
        .remote(url: "https://github.com/kudit/Device", requirement: .upToNextMajor(from: "2.6.0")),
    ],
    settings: .settings(
        base: SettingsDictionary()
            .marketingVersion("1.0")
            .currentProjectVersion("1")
            .automaticCodeSigning(devTeam: "LR4RJT6586")
    ),
    targets: [
        .target(
            name: "{{NAME}}",
            destinations: [.iPhone],
            product: .app,
            bundleId: "{{BUNDLE_PREFIX}}.{{NAME}}",
            infoPlist: "app/Info.plist",
            sources: ["app/**"],
            resources: ["app/Assets.xcassets", "app/Preview Content/**"],
            entitlements: .file(path: "app/{{NAME}}.entitlements"),
            dependencies: [
                .package(product: "Pulse"),
                .package(product: "Valet"),
                .package(product: "PulseUI"),
                .package(product: "PulseProxy"),
                .package(product: "Device Library"),
            ]
        ),
    ]
)
