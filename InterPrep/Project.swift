import ProjectDescription

let project = Project(
    name: "InterPrep",
    packages: [
        .remote(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            requirement: .upToNextMajor(from: "1.15.0")
        ),
        .remote(
            url: "https://github.com/apple/swift-protobuf.git",
            requirement: .upToNextMajor(from: "1.28.0")
        ),
        .remote(
            url: "https://github.com/apple/swift-log.git",
            requirement: .upToNextMajor(from: "1.5.0")
        ),
        .remote(
            url: "https://github.com/apple/swift-nio.git",
            requirement: .upToNextMajor(from: "2.62.0")
        ),
        .remote(
            url: "https://github.com/grpc/grpc-swift.git",
            requirement: .exact("1.23.0")  // 1.26+ требует Swift Tools 6.1; при 6.0.3 используем 1.23
        )
    ],
    settings: .settings(
        base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0"
        ]
    ),
    targets: [
        // MARK: - App Target
        
        .target(
            name: "InterPrep",
            destinations: .iOS,
            product: .app,
            bundleId: "com.interprep.app",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:],
                    "CFBundleDisplayName": "InterPrep",
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": false,
                        "UISceneConfigurations": [:]
                    ],
                    "NSAppTransportSecurity": [
                        "NSExceptionDomains": [
                            "193.124.33.223": [
                                "NSTemporaryExceptionAllowsInsecureHTTPLoads": true,
                                "NSTemporaryExceptionMinimumTLSVersion": "TLSv1.0"
                            ]
                        ]
                    ]
                ]
            ),
            sources: [
                "InterPrep/InterPrepApp.swift",
                "InterPrep/AppGraph.swift",
                "InterPrep/ContentView.swift",
                "InterPrep/Services/AuthServiceImpl.swift",
                "InterPrep/Services/ResumeServiceImpl.swift",
                "InterPrep/Services/VacancyServiceImpl.swift",
                "InterPrep/Services/ChatServiceImpl.swift",
                "InterPrep/Services/CalendarServiceImpl.swift",
                "InterPrep/Components/Navigation/MainTabView.swift",
                "InterPrep/Components/Navigation/ResumeProfileDetailView.swift",
                "InterPrep/Components/Navigation/TabBarView.swift",
                "InterPrep/Components/Navigation/TabBarButton.swift",
                "InterPrep/Components/Navigation/TabBarLayout.swift",
                "InterPrep/Components/Navigation/TabBar+Colors.swift",
                "InterPrep/Components/Navigation/TabBarPreview.swift",
                "InterPrep/Components/Navigation/TabItem.swift"
            ],
            resources: [
                "InterPrep/Assets.xcassets/**",
                "InterPrep/Preview Content/**"
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .target(name: "NetworkService"),
                .target(name: "DiscoveryModule"),
                .target(name: "VacancyCardFeature"),
                .target(name: "AuthFeature"),
                .target(name: "OnboardingFeature"),
                .target(name: "ResumeUploadFeature"),
                .target(name: "CalendarFeature"),
                .target(name: "ProfileFeature"),
                .target(name: "DocumentsFeature"),
                .target(name: "ChatFeature")
            ]
        ),
        
        // MARK: - Architecture Core
        
        .target(
            name: "ArchitectureCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.architecture.core",
            sources: [
                "InterPrep/Architecture/Core/**",
                "InterPrep/Architecture/Utilities/**"
            ],
            dependencies: []
        ),
        
        
        // MARK: - Network Service
        
        .target(
            name: "NetworkService",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.network",
            sources: [
                "InterPrep/NetworkV2/**/*.swift"
            ],
            dependencies: [
                .package(product: "SwiftProtobuf"),
                .package(product: "GRPC"),
                .package(product: "Logging"),
                .package(product: "NIOCore"),
                .package(product: "NIOHTTP2")
            ]
        ),
        
        // MARK: - Design System
        
        .target(
            name: "DesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.designsystem",
            sources: [
                "InterPrep/DesignSystem/Colors.swift",
                "InterPrep/DesignSystem/ThemeManager.swift",
                "InterPrep/DesignSystem/ThemePreview.swift"
            ],
            resources: [
                "InterPrep/Assets.xcassets/**"
            ],
            dependencies: []
        ),
        
        // MARK: - Discovery Module (Base)
        
        .target(
            name: "DiscoveryModule",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.modules.discovery",
            sources: [
                .glob("InterPrep/Screens/Discovery/**", excluding: ["InterPrep/Screens/Discovery/README.md"])
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .sdk(name: "WebKit", type: .framework)
            ]
        ),
        
        // MARK: - Auth Feature
        
        .target(
            name: "AuthFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.features.auth",
            sources: [
                "InterPrep/Screens/Auth/**"
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem")
            ]
        ),
        
        // MARK: - Onboarding Feature
        
        .target(
            name: "OnboardingFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.features.onboarding",
            sources: [
                "InterPrep/Screens/Onboarding/**"
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem")
            ]
        ),
        
        // MARK: - Vacancy Card Feature
        
        .target(
            name: "VacancyCardFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.features.vacancycard",
            sources: [
                "InterPrep/Screens/VacancyCard/**"
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .target(name: "DiscoveryModule")
            ]
        ),
        
        // MARK: - Resume Upload Feature
        
        .target(
            name: "ResumeUploadFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.features.resumeupload",
            sources: [
                .glob("InterPrep/Screens/ResumeUpload/**", excluding: ["InterPrep/Screens/ResumeUpload/README.md"])
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .target(name: "NetworkService")
            ]
        ),
        
        // MARK: - Calendar Feature
        
        .target(
            name: "CalendarFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.features.calendar",
            sources: [
                "InterPrep/Screens/Calendar/**"
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem")
            ]
        ),
        
        // MARK: - Profile Feature
        
        .target(
            name: "ProfileFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.features.profile",
            sources: [
                "InterPrep/Screens/Profile/**"
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .target(name: "CalendarFeature"),
                .target(name: "NetworkService"),
                .package(product: "SwiftProtobuf"),
                .package(product: "GRPC"),
                .package(product: "Logging"),
                .package(product: "NIOCore"),
                .package(product: "NIOHTTP2")
            ]
        ),
        
        // MARK: - Documents Feature
        
        .target(
            name: "DocumentsFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.features.documents",
            sources: [
                "InterPrep/Screens/Documents/**"
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .target(name: "NetworkService")
            ]
        ),
        
        // MARK: - Chat Feature
        
        .target(
            name: "ChatFeature",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.features.chat",
            sources: [
                "InterPrep/Screens/Chat/**"
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem")
            ]
        ),
        
        // MARK: - Tests
        
        .target(
            name: "InterPrepTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.interprep.app.tests",
            sources: [
                "InterPrepTests/**"
            ],
            dependencies: [
                .target(name: "InterPrep"),
                .target(name: "AuthFeature"),
                .target(name: "OnboardingFeature")
            ]
        ),
        
        .target(
            name: "InterPrepUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.interprep.app.uitests",
            sources: [
                "InterPrepUITests/**"
            ],
            dependencies: [
                .target(name: "InterPrep")
            ]
        ),
        
        // MARK: - Feature Tests
        
        .target(
            name: "AuthFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.interprep.features.auth.tests",
            sources: [
                "InterPrepTests/AuthFeatureTests/**",
                "InterPrepTests/SnapshotTestingKit/**"
            ],
            dependencies: [
                .target(name: "AuthFeature"),
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .package(product: "SnapshotTesting")
            ]
        ),
        
        .target(
            name: "OnboardingFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.interprep.features.onboarding.tests",
            sources: [
                "InterPrepTests/OnboardingFeatureTests/**",
                "InterPrepTests/SnapshotTestingKit/**"
            ],
            dependencies: [
                .target(name: "OnboardingFeature"),
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .package(product: "SnapshotTesting")
            ]
        ),
        
        .target(
            name: "DiscoveryModuleTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.interprep.modules.discovery.tests",
            sources: [
                "InterPrepTests/DiscoveryFeatureTests/**",
                "InterPrepTests/SnapshotTestingKit/**"
            ],
            dependencies: [
                .target(name: "DiscoveryModule"),
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .package(product: "SnapshotTesting")
            ]
        ),
        
        .target(
            name: "ResumeUploadFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.interprep.features.resumeupload.tests",
            sources: [
                "InterPrepTests/ResumeUploadFeatureTests/**",
                "InterPrepTests/SnapshotTestingKit/**"
            ],
            dependencies: [
                .target(name: "ResumeUploadFeature"),
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .package(product: "SnapshotTesting")
            ]
        ),
        
        .target(
            name: "ChatFeatureTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.interprep.features.chat.tests",
            sources: [
                "InterPrepTests/ChatFeatureTests/**",
                "InterPrepTests/SnapshotTestingKit/**"
            ],
            dependencies: [
                .target(name: "ChatFeature"),
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .package(product: "SnapshotTesting")
            ]
        )
    ]
)
