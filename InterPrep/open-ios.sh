#!/bin/bash
set -e
cd "$(dirname "$0")"

# Prefer Mise-managed Tuist (version in .mise.toml) for Swift 6.0 compatibility.
# Homebrew's latest Tuist is built with Swift 6.2 and fails with Xcode 16.0.
if command -v mise &>/dev/null && mise which tuist &>/dev/null 2>&1; then
  echo "Используется Tuist из Mise ($(mise current tuist 2>/dev/null || true))"
  TUIST_CMD="mise exec -- tuist"
elif command -v tuist &>/dev/null; then
  TUIST_CMD="tuist"
else
  echo "Tuist не установлен. Рекомендуется Mise (совместимость со Swift 6.0):"
  echo "  mise install   # установит версию из .mise.toml"
  echo "Или Homebrew (может потребовать Xcode с Swift 6.2):"
  echo "  brew install tuist"
  exit 1
fi

echo "Генерация Xcode-проекта..."
$TUIST_CMD generate

WORKSPACE="InterPrep.xcworkspace"
if [[ -d "$WORKSPACE" ]]; then
  echo "Открываю $WORKSPACE в Xcode..."
  open "$WORKSPACE"
else
  PROJECT="InterPrep.xcodeproj"
  if [[ -d "$PROJECT" ]]; then
    echo "Открываю $PROJECT в Xcode..."
    open "$PROJECT"
  else
    echo "Ошибка: не найден .xcworkspace или .xcodeproj после tuist generate"
    exit 1
  fi
fi
