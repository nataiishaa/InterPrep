#!/bin/bash

echo "Настройка Tuist для модульной архитектуры"
echo ""

echo "1. Переключение на Xcode.app..."
sudo xcode-select -s /Applications/Xcode.app

if [ $? -eq 0 ]; then
    echo "Xcode.app выбран"
else
    echo "Ошибка при переключении на Xcode.app"
    exit 1
fi

echo ""
echo "2. Проверка установки Xcode..."
xcode-select -p

echo ""
echo "3. Очистка кеша Tuist..."
tuist clean

echo ""
echo "4. Генерация проекта с модулями..."
tuist generate

if [ $? -eq 0 ]; then
    echo ""
    echo "Проект успешно сгенерирован!"
    echo ""
    echo "Созданы модули: ArchitectureCore, DesignSystem, AuthFeature, OnboardingFeature, DiscoveryFeature, ResumeUploadFeature"
    echo ""
    echo "Откройте InterPrep.xcworkspace в Xcode"
else
    echo ""
    echo "Ошибка при генерации проекта"
    exit 1
fi
