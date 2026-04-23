#!/bin/bash

# Быстрая проверка перед коммитом (без полной сборки)

echo "🚀 Быстрая проверка..."
echo ""

# 1. SwiftLint
if command -v swiftlint &> /dev/null; then
    echo "📝 SwiftLint..."
    swiftlint lint
    if [ $? -eq 0 ]; then
        echo "✅ SwiftLint OK"
    else
        echo "❌ SwiftLint нашел проблемы"
        echo "   Попробуйте: swiftlint lint --fix"
        exit 1
    fi
else
    echo "⚠️  SwiftLint не установлен (пропускаем)"
fi

echo ""

# 2. Проверка, что проект генерируется
echo "🏗️  Проверка Tuist..."
cd InterPrep
tuist generate > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Tuist generate OK"
else
    echo "❌ Tuist generate failed"
    exit 1
fi

cd ..
echo ""
echo "✨ Быстрая проверка пройдена!"
echo "   Можно коммитить и пушить"
