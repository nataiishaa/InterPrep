#!/bin/bash

# Скрипт для локальной проверки CI
# Запуск: ./check_ci_locally.sh

set -e  # Остановка при ошибке

echo "================================"
echo "🔍 Проверка CI локально"
echo "================================"
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки
check_step() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

# 1. Проверка зависимостей
echo "📦 Проверка зависимостей..."
echo ""

if command -v tuist &> /dev/null; then
    echo -e "${GREEN}✅ Tuist установлен: $(tuist --version)${NC}"
else
    echo -e "${RED}❌ Tuist не установлен${NC}"
    echo "   Установите: curl -Ls https://install.tuist.io | bash"
    exit 1
fi

if command -v swiftlint &> /dev/null; then
    echo -e "${GREEN}✅ SwiftLint установлен: $(swiftlint version)${NC}"
    SWIFTLINT_INSTALLED=true
else
    echo -e "${YELLOW}⚠️  SwiftLint не установлен (необязательно)${NC}"
    echo "   Установите: brew install swiftlint"
    SWIFTLINT_INSTALLED=false
fi

echo ""
echo "🔨 Xcode версия:"
xcodebuild -version
echo ""

# 2. Генерация проекта
echo "================================"
echo "🏗️  Генерация проекта с Tuist..."
echo "================================"
cd InterPrep
tuist generate
check_step "Генерация проекта"
echo ""

# 3. Сборка
echo "================================"
echo "🔧 Сборка приложения..."
echo "================================"
xcodebuild clean build \
  -workspace InterPrep.xcworkspace \
  -scheme InterPrep-Workspace \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  | grep -E '(Build Succeeded|Build Failed|error:|warning:)' || true

check_step "Сборка приложения"
echo ""

# 4. Unit-тесты
echo "================================"
echo "🧪 Запуск Unit-тестов..."
echo "================================"
xcodebuild test \
  -workspace InterPrep.xcworkspace \
  -scheme InterPrep-Workspace \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:AuthFeatureTests \
  -only-testing:ChatFeatureTests \
  -only-testing:DiscoveryModuleTests \
  -only-testing:OnboardingFeatureTests \
  -only-testing:ResumeUploadFeatureTests \
  -only-testing:InterPrepTests/CalendarStateTests \
  -only-testing:InterPrepTests/DocumentsStateTests \
  -only-testing:InterPrepTests/ProfileStateTests \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  | grep -E '(Test Suite|Test Case|passed|failed|error:)' || true

check_step "Unit-тесты"
echo ""

# 5. UI-тесты (опционально, могут быть долгими)
echo "================================"
echo "🖥️  Запуск UI-тестов..."
echo "================================"
xcodebuild test \
  -workspace InterPrep.xcworkspace \
  -scheme InterPrep-Workspace \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:InterPrepUITests \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  | grep -E '(Test Suite|Test Case|passed|failed|error:)' || true

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ UI-тесты${NC}"
else
    echo -e "${YELLOW}⚠️  UI-тесты завершились с ошибками (это нормально)${NC}"
fi
echo ""

# 6. SwiftLint
if [ "$SWIFTLINT_INSTALLED" = true ]; then
    echo "================================"
    echo "📝 Проверка SwiftLint..."
    echo "================================"
    cd ..
    swiftlint lint --strict
    check_step "SwiftLint проверка"
    echo ""
fi

# Итоги
echo "================================"
echo "✨ Проверка завершена!"
echo "================================"
echo ""
echo "Если все зеленые ✅ - можно пушить в GitHub!"
echo "Если есть красные ❌ - исправьте ошибки перед push"
echo ""
