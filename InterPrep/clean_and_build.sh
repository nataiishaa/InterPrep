#!/bin/bash

echo "Очистка кеша Xcode..."
echo ""

osascript -e 'quit app "Xcode"' 2>/dev/null

echo "Xcode закрыт"
echo ""

echo "Удаляем DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData
echo "DerivedData удален"
echo ""

echo "Удаляем кеш Xcode..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode
echo "Кеш удален"
echo ""

cd "$(dirname "$0")"

echo "Директория проекта: $(pwd)"
echo ""

echo "Очистка завершена!"
echo ""
echo "Теперь:"
echo "1. Откройте Xcode"
echo "2. Откройте InterPrep.xcodeproj"
echo "3. Product -> Clean Build Folder (Shift + Cmd + K)"
echo "4. Product -> Build (Cmd + B)"
echo ""
