# Proto Layer

Этот слой содержит Protocol Buffers определения для API.

## Генерация Swift кода из .proto файлов

### Установка protoc

```bash
brew install protobuf swift-protobuf
```

### Генерация

```bash
cd InterPrep/NetworkV2/Proto

# Генерация Swift файлов (публичные типы для использования из фреймворка)
protoc \
  --proto_path=. \
  --swift_out=Generated \
  --swift_opt=Visibility=Public \
  gateway.proto

# Результат: Generated/gateway.pb.swift
```

### Автоматическая генерация при сборке

Добавьте Build Phase в Xcode:

```bash
#!/bin/bash

PROTO_DIR="${SRCROOT}/InterPrep/NetworkV2/Proto"
OUTPUT_DIR="${PROTO_DIR}/Generated"

mkdir -p "${OUTPUT_DIR}"

protoc \
  --proto_path="${PROTO_DIR}" \
  --swift_out="${OUTPUT_DIR}" \
  "${PROTO_DIR}"/*.proto
```

## Структура

```
Proto/
├── gateway.proto          # Основные API сообщения
├── Generated/             # Автогенерированные файлы
│   └── gateway.pb.swift
└── README.md
```

## Использование

```swift
import SwiftProtobuf

// Создание запроса
var request = Gateway_LoginRequest()
request.email = "test@example.com"
request.password = "password123"

// Сериализация в binary
let data = try request.serializedData()

// Сериализация в JSON (для отладки)
let json = try request.jsonString()

// Десериализация
let response = try Gateway_LoginResponse(serializedData: data)
```

## Преимущества Protobuf

- ✅ **Type-safe** - компилятор проверяет типы
- ✅ **Компактный** - бинарный формат меньше JSON
- ✅ **Быстрый** - быстрее парсинг чем JSON
- ✅ **Версионирование** - обратная совместимость
- ✅ **Кросс-платформенность** - один .proto для iOS/Android/Backend
