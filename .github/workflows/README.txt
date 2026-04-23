=== CI/CD для InterPrep ===

Настроены автоматические тесты на GitHub Actions.

ФАЙЛЫ:
- ci.yml - основной CI workflow (сборка + тесты)

ТРИГГЕРЫ:
- Push в ветки main, develop
- Pull Request в main, develop

ЧТО ЗАПУСКАЕТСЯ:
1. Сборка приложения
2. Unit-тесты (AuthFeatureTests, ChatFeatureTests, DiscoveryModuleTests, и др.)
3. UI-тесты (InterPrepUITests)
4. SwiftLint проверка кода

КАК ПРОВЕРИТЬ ЛОКАЛЬНО:

1. Установить зависимости:
   curl -Ls https://install.tuist.io | bash
   brew install swiftlint

2. Сгенерировать проект:
   cd InterPrep
   tuist generate

3. Запустить тесты:
   xcodebuild test \
     -workspace InterPrep.xcworkspace \
     -scheme InterPrep-Workspace \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

4. Проверить SwiftLint:
   swiftlint lint

КАК ПРОВЕРИТЬ В GITHUB:
1. Запушьте код в GitHub
2. Перейдите в Actions tab
3. Посмотрите статус workflow "CI"
4. Зеленая галочка ✅ = все тесты прошли
5. Красный крестик ❌ = есть ошибки (кликните для просмотра логов)

БЫСТРАЯ ПРОВЕРКА ПЕРЕД PUSH:
cd InterPrep && tuist generate
xcodebuild build -workspace InterPrep.xcworkspace -scheme InterPrep-Workspace
xcodebuild test -workspace InterPrep.xcworkspace -scheme InterPrep-Workspace
swiftlint lint
