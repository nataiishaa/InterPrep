import ProjectDescription

let config = Config(
    compatibleXcodeVersions: ["16.0", "26.1"],
    swiftVersion: "6.0",
    generationOptions: .options(
        resolveDependenciesWithSystemScm: false,
        disablePackageVersionLocking: false
    )
)
