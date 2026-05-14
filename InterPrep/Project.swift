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
            url: "https://github.com/grpc/grpc-swift.git",
            requirement: .upToNextMajor(from: "1.21.0")
        ),
        .remote(
            url: "https://github.com/appmetrica/appmetrica-sdk-ios",
            requirement: .upToNextMajor(from: "5.0.0")
        )
    ],
    settings: .settings(
        base: [
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0"
        ]
    ),
    targets: [

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
                    "NSUserNotificationsUsageDescription": "Приложение использует уведомления для напоминаний о предстоящих собеседованиях и событиях в календаре",
                    "NSPhotoLibraryUsageDescription": "Приложение использует доступ к фотогалерее для загрузки фотографии профиля"
                ]
            ),
            sources: [
                "InterPrep/InterPrepApp.swift",
                "InterPrep/AppDelegate.swift",
                "InterPrep/AppGraph.swift",
                "InterPrep/ContentView.swift",
                "InterPrep/Config/Secrets.swift",
                "InterPrep/Services/VacancyService.swift",
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
                "InterPrep/PrivacyInfo.xcprivacy"
            ],
            dependencies: [
                .target(name: "ArchitectureCore"),
                .target(name: "DesignSystem"),
                .target(name: "NetworkService"),
                .target(name: "NotificationService"),
                .target(name: "CacheService"),
                .target(name: "NetworkMonitorService"),
                .target(name: "AnalyticsService"),
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

        .target(
            name: "NetworkService",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.network",
            sources: [
                "InterPrep/NetworkV2/**/*.swift",
                "InterPrep/Services/SessionManager.swift"
            ],
            dependencies: [
                .package(product: "SwiftProtobuf"),
                .package(product: "GRPC")
            ]
        ),

        .target(
            name: "DesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.designsystem",
            sources: [
                "InterPrep/DesignSystem/Colors.swift",
                "InterPrep/DesignSystem/ThemeManager.swift",
                "InterPrep/DesignSystem/ThemePreview.swift",
                "InterPrep/DesignSystem/NoConnectionView.swift",
                "InterPrep/DesignSystem/OfflineBanner.swift"
            ],
            resources: [
                "InterPrep/Assets.xcassets/**"
            ],
            dependencies: []
        ),

        .target(
            name: "AnalyticsService",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.analytics",
            sources: [
                "InterPrep/Services/Analytics/*.swift"
            ],
            dependencies: [
                .package(product: "AppMetricaCore")
            ]
        ),

        .target(
            name: "NotificationService",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.notification",
            sources: [
                "InterPrep/Services/NotificationManager.swift"
            ],
            dependencies: []
        ),

        .target(
            name: "CacheService",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.cache",
            sources: [
                "InterPrep/Services/CacheManager.swift",
                "InterPrep/Services/AreasCache.swift"
            ],
            dependencies: [
                .target(name: "NetworkService")
            ]
        ),

        .target(
            name: "NetworkMonitorService",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.interprep.networkmonitor",
            sources: [
                "InterPrep/Services/NetworkMonitor.swift",
                "InterPrep/Services/OfflineSyncManager.swift"
            ],
            dependencies: [
                .target(name: "CacheService"),
                .target(name: "NetworkService")
            ]
        ),

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
                .target(name: "CacheService"),
                .target(name: "NetworkService"),
                .target(name: "NetworkMonitorService"),
                .target(name: "AnalyticsService"),
                .sdk(name: "WebKit", type: .framework)
            ]
        ),

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
                .target(name: "DesignSystem"),
                .target(name: "NetworkService"),
                .target(name: "CacheService"),
                .target(name: "ResumeUploadFeature"),
                .target(name: "AnalyticsService")
            ]
        ),

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
                .target(name: "NetworkService"),
                .target(name: "DiscoveryModule"),
                .target(name: "AnalyticsService")
            ]
        ),

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
                .target(name: "DesignSystem"),
                .target(name: "NetworkService"),
                .target(name: "NotificationService"),
                .target(name: "CacheService"),
                .target(name: "NetworkMonitorService"),
                .target(name: "AnalyticsService")
            ]
        ),

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
                .target(name: "AuthFeature"),
                .target(name: "CalendarFeature"),
                .target(name: "NetworkService"),
                .target(name: "NotificationService"),
                .target(name: "CacheService"),
                .target(name: "NetworkMonitorService"),
                .target(name: "AnalyticsService")
            ]
        ),

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
                .target(name: "NetworkService"),
                .target(name: "CacheService"),
                .target(name: "NetworkMonitorService"),
                .target(name: "AnalyticsService")
            ]
        ),

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
                .target(name: "DesignSystem"),
                .target(name: "DiscoveryModule"),
                .target(name: "NetworkMonitorService"),
                .target(name: "AnalyticsService")
            ]
        ),

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
                .target(name: "OnboardingFeature"),
                .target(name: "ChatFeature"),
                .target(name: "CalendarFeature"),
                .target(name: "DocumentsFeature"),
                .target(name: "ProfileFeature"),
                .target(name: "VacancyCardFeature"),
                .target(name: "DiscoveryModule"),
                .package(product: "SnapshotTesting")
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
                .target(name: "DiscoveryModule"),
                .package(product: "SnapshotTesting")
            ]
        )
    ]
)
