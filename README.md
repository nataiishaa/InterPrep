# InterPrep

[![CI](https://github.com/nataiishaa/InterPrep/workflows/CI/badge.svg)](https://github.com/nataiishaa/InterPrep/actions/workflows/ci.yml)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Tuist](https://img.shields.io/badge/Tuist-managed-blue.svg)](https://tuist.io)

iOS-приложение-помощник для поиска работы.

## Возможности

- **Чат с карьерным консультантом** — помощь в подготовке к собеседованиям, разбор резюме, подготовка к конкретной вакансии
- **Поиск вакансий** — агрегатор вакансий с избранным
- **Управление резюме** — загрузка, парсинг и анализ резюме
- **Календарь** — планирование собеседований, уведомления, синхронизация с CalDAV
- **Документы** — хранилище файлов и заметок для подготовки
- **Профиль** — статистика, настройки, история собеседований
- **Офлайн-режим** — кеширование данных, очередь отложенных операций

## Технологии

| Область | Стек |
|---------|------|
| UI | SwiftUI, iOS 17+ |
| Архитектура | Store + Reducer + EffectHandler (TCA-подобная) |
| Сеть | gRPC (grpc-swift), Protocol Buffers (swift-protobuf) |
| Модульность | Tuist (16 таргетов) |
| Тесты | XCTest, SnapshotTesting |
| CI | GitHub Actions (build, unit/UI-тесты, SwiftLint) |

## Архитектура

### Модули

```
                          InterPrep (App)
                     ┌───────┼───────────────┐
                     │       │               │
              ┌──────┴──┐  ┌─┴──────┐  ┌─────┴─────┐
              │ Feature  │  │Feature │  │  Feature   │
              │ modules  │  │modules │  │  modules   │
              └──┬───┬──┘  └┬───┬───┘  └──┬────┬───┘
                 │   │      │   │         │    │
    ┌────────────┴───┴──────┴───┴─────────┴────┴──────┐
    │  ArchitectureCore  NetworkService  DesignSystem  │
    │  CacheService  NotificationService  NetworkMon.  │
    └─────────────────────┬───────────────────────────┘
                          │
                   SwiftProtobuf, GRPC
```

**Feature-модули:** AuthFeature, OnboardingFeature, ChatFeature, DiscoveryModule, CalendarFeature, ProfileFeature, DocumentsFeature, ResumeUploadFeature, VacancyCardFeature

**Инфраструктурные модули:** ArchitectureCore, NetworkService, DesignSystem, CacheService, NotificationService, NetworkMonitorService

### Поток данных (внутри каждого экрана)

```
User Action → Input → reduce(state, input) → Effect
                          │                      │
                        State              EffectHandler
                          │                (async: сеть, кеш)
                     View Update                 │
                          │                      │
                          └── reduce(state, feedback) ←┘
```

- **State** — структура, описывающая состояние экрана
- **reduce()** — чистая функция, обновляет State и возвращает Effect
- **EffectHandler** — actor, выполняет асинхронную работу (сеть, кеш, файлы)
- **Container** — связывает Store и SwiftUI View
- **View + Model** — пассивное отображение данных

### Сеть

Клиент общается с единым бекенд-сервисом `BackendGateway` (Go) через два транспорта:

- **gRPC (HTTP/2, TLS)** — основной, через grpc-swift
- **HTTPS + Protobuf** — запасной, через URLSession

Контракт описан в `.proto` файлах → кодогенерация Swift-типов через `protoc`.

### Офлайн-режим

- `NWPathMonitor` для отслеживания состояния сети
- Файловый кеш для календаря, документов, профиля (`CacheManager`)
- Очередь отложенных операций (`OfflineSyncManager`)
- Оптимистичный UI при потере связи

## Структура проекта

```
InterPrep/
├── InterPrep/
│   ├── Project.swift              # Tuist-манифест
│   ├── InterPrep/
│   │   ├── InterPrepApp.swift     # Точка входа
│   │   ├── AppGraph.swift         # Composition root (DI)
│   │   ├── Architecture/          # ArchitectureCore: Store, State, EffectHandler
│   │   ├── NetworkV2/             # NetworkService: gRPC, Protobuf, токены
│   │   │   └── Proto/            # .proto файлы + Generated/
│   │   ├── DesignSystem/          # Цвета, тема
│   │   ├── Services/              # CacheManager, NetworkMonitor, Notifications
│   │   ├── Components/            # TabBar, OfflineBanner
│   │   └── Screens/
│   │       ├── Auth/              # Регистрация, логин, сброс пароля
│   │       ├── Onboarding/        # Онбординг
│   │       ├── Discovery/         # Поиск вакансий
│   │       ├── Chat/              # Чат с карьерным консультантом
│   │       ├── Calendar/          # Календарь + CalDAV
│   │       ├── Documents/         # Хранилище документов
│   │       ├── Profile/           # Профиль и настройки
│   │       ├── ResumeUpload/      # Загрузка резюме
│   │       └── VacancyCard/       # Карточка вакансии
│   └── InterPrepTests/            # Unit + Snapshot тесты
└── .github/workflows/ci.yml       # CI pipeline
```

## Как запустить

### Требования

- macOS 14+, Xcode 16+
- [mise](https://mise.jdx.dev/) (для управления Tuist)
- protobuf + swift-protobuf (для кодогенерации proto)

### Установка и запуск

```bash
git clone https://github.com/nataiishaa/InterPrep.git
cd InterPrep/InterPrep

# Установить Tuist через mise
curl -sSf https://mise.run | sh
mise install

# Установить protobuf (если нужно перегенерировать proto)
brew install protobuf swift-protobuf

# Сгенерировать Xcode-проект и открыть
mise exec -- tuist generate
open InterPrep.xcworkspace
```

## Тесты

Unit-тесты для State/reducer каждого экрана, snapshot-тесты UI, UI-тесты основных флоу.

```bash
cd InterPrep

mise exec -- tuist generate

# Unit-тесты
xcodebuild test-without-building \
  -workspace InterPrep.xcworkspace \
  -scheme InterPrep-Workspace \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Линтер
brew install swiftlint
swiftlint lint
```

### Кодогенерация Proto

```bash
cd InterPrep/InterPrep/NetworkV2/Proto
./generate.sh
```
