# InterPrep

## Технологии

- Swift
- SwiftUI
- gRPC / Protocol Buffers
- TCA (The Composable Architecture)

## Требования

- iOS 17.0+
- Xcode 15.0+

## Установка

1. Клонируйте репозиторий
2. Откройте `InterPrep.xcodeproj` в Xcode
3. Соберите и запустите проект

## Архитектура

Проект использует модульную архитектуру на основе TCA:
- **Screens**: Экраны приложения (Chat, Calendar, Materials, Profile)
- **Services**: Бизнес-логика и сетевые запросы
- **NetworkV2**: gRPC клиент и Protocol Buffers модели
- **UI**: Переиспользуемые UI-компоненты
