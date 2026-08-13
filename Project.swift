import ProjectDescription

// macOS 15: floor for Xcode 26 hosts and for `Mutex` (Synchronization).
let deploymentTarget: DeploymentTargets = .macOS("15.0")

let project = Project(
    name: "Mirage",
    options: .options(
        automaticSchemesOptions: .enabled(
            targetSchemesGrouping: .notGrouped,
            codeCoverageEnabled: true
        )
    ),
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            // Explicit concurrency posture: nonisolated-by-default library code
            // (nothing here is UI-bound) with approachable-concurrency
            // upcoming features enabled.
            "SWIFT_DEFAULT_ACTOR_ISOLATION": "nonisolated",
            "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
        ]
    ),
    targets: [
        .target(
            name: "mirage",
            destinations: [.mac],
            product: .commandLineTool,
            bundleId: "dev.mirage.cli",
            deploymentTargets: deploymentTarget,
            buildableFolders: [
                "Sources/mirage"
            ],
            dependencies: [
                .target(name: "MirageCLI")
            ],
            metadata: .metadata(tags: ["tag:layer:entry"])
        ),
        .target(
            name: "MirageCLI",
            destinations: [.mac],
            product: .staticLibrary,
            bundleId: "dev.mirage.MirageCLI",
            deploymentTargets: deploymentTarget,
            buildableFolders: [
                "Sources/MirageCLI"
            ],
            dependencies: [
                .target(name: "MirageKit"),
                .external(name: "ArgumentParser"),
                .external(name: "Noora"),
            ],
            metadata: .metadata(tags: ["tag:layer:cli"])
        ),
        .target(
            name: "MirageKit",
            destinations: [.mac],
            product: .staticLibrary,
            bundleId: "dev.mirage.MirageKit",
            deploymentTargets: deploymentTarget,
            buildableFolders: [
                "Sources/MirageKit"
            ],
            metadata: .metadata(tags: ["tag:layer:kit"])
        ),
        .target(
            name: "MirageKitTesting",
            destinations: [.mac],
            product: .staticLibrary,
            bundleId: "dev.mirage.MirageKitTesting",
            deploymentTargets: deploymentTarget,
            buildableFolders: [
                "Sources/MirageKitTesting"
            ],
            dependencies: [
                .target(name: "MirageKit")
            ],
            metadata: .metadata(tags: ["tag:layer:kit"])
        ),
        .target(
            name: "MirageKitTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "dev.mirage.MirageKitTests",
            deploymentTargets: deploymentTarget,
            buildableFolders: [
                "Tests/MirageKitTests"
            ],
            dependencies: [
                .target(name: "MirageKit"),
                .target(name: "MirageKitTesting"),
            ],
            metadata: .metadata(tags: ["tag:layer:kit"])
        ),
        .target(
            name: "MirageCLITests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "dev.mirage.MirageCLITests",
            deploymentTargets: deploymentTarget,
            buildableFolders: [
                "Tests/MirageCLITests"
            ],
            dependencies: [
                .target(name: "MirageCLI"),
                .target(name: "MirageKitTesting"),
            ],
            metadata: .metadata(tags: ["tag:layer:cli"])
        ),
    ]
)
