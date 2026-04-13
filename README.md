# InterPrep

Мобильное приложение-помощник для подготовки к собеседованиям.

## Основные возможности

- **AI-коуч**: Интерактивные сессии подготовки к собеседованиям с персонализированной обратной связью
- **Календарь**: Планирование и отслеживание сессий подготовки
- **Материалы**: Доступ к учебным материалам и вопросам для интервью
- **Профиль**: Управление резюме и отслеживание прогресса

## Технологии

- **Swift** — основной язык разработки
- **SwiftUI** — декларативный UI framework
- **Combine** — реактивное программирование (@Published, ObservableObject)
- **Swift Concurrency** — async/await, Actor для многопоточности
- **gRPC / Protocol Buffers** — бинарный протокол для связи с бэкендом
- **Redux-подобная архитектура** — однонаправленный поток данных (State → View → Input → Effect → Feedback)

## Требования

- iOS 17.0+
- Xcode 15.0+

## Установка

### 1. Установите зависимости

```bash
# Protocol Buffers компилятор и Swift плагин
brew install protobuf swift-protobuf

# Опционально: для полной генерации gRPC клиента
brew install grpc-swift
```

### 2. Клонируйте репозиторий

```bash
git clone <repository-url>
cd InterPrep
```

### 3. Сгенерируйте Proto модели (опционально)

```bash
cd InterPrep/NetworkV2/Proto
./generate.sh
```

> **Примечание:** Сгенерированные файлы уже включены в репозиторий. Генерация нужна только при изменении `.proto` файлов.

### 4. Откройте проект в Xcode

```bash
open InterPrep.xcodeproj
```

### 5. Соберите и запустите

Выберите симулятор или устройство и нажмите `Cmd+R`

## Архитектура

Проект использует Redux-подобную архитектуру с однонаправленным потоком данных, напоминающую TCA (The Composable Architecture).

### Основные компоненты

Каждый экран состоит из трех слоев:

#### 1. **Passive View** (SwiftUI)
"Глупые" представления, которые только отображают данные и не принимают решений.
- Получают данные через `Model` структуру
- Вызывают колбэки при действиях пользователя
- Не содержат бизнес-логики

```swift
DiscoveryView(model: Model(
    vacancies: [...],
    onVacancyTap: { vacancy in ... }
))
```

#### 2. **Container**
Связующий слой между View и Store.
- Управляет навигацией (sheets, navigation)
- Преобразует State в Model для View
- Отправляет Input в Store при действиях пользователя

```swift
DiscoveryContainer
  ├─ @StateObject store: Store
  ├─ makeModel() -> DiscoveryView.Model
  └─ Navigation (sheets, NavigationStack)
```

#### 3. **Store** (Бизнес-логика)
Мозг экрана, управляет состоянием и побочными эффектами.

Состоит из:
- **State** — неизменяемое состояние экрана
- **Input** — действия пользователя (enum)
- **Feedback** — результаты асинхронных операций (enum)
- **Effect** — побочные эффекты для выполнения (enum)
- **reduce()** — чистая функция, изменяющая State
- **EffectHandler** — выполняет асинхронные операции (actor)

### Поток данных

```
User Action → Input → reduce() → Effect → EffectHandler → Service → Backend
                ↓                                                        ↓
              State ← reduce() ← Feedback ← EffectHandler ← Response ←─┘
                ↓
            View Update
```

**Пример:**
1. Пользователь нажимает "Загрузить вакансии" → `Input.onAppear`
2. `reduce()` изменяет `state.isLoading = true` → возвращает `Effect.loadVacancies`
3. `EffectHandler` вызывает `vacancyService.fetchVacancies()`
4. Service делает gRPC запрос через `NetworkServiceV2`
5. Ответ возвращается как `Feedback.vacanciesLoaded([...])`
6. `reduce()` обновляет `state.vacancies` и `state.isLoading = false`
7. View автоматически перерисовывается

### Сетевой слой

#### NetworkServiceV2
Singleton-сервис для взаимодействия с бэкендом:
- **gRPC** (основной) — бинарный протокол через HTTP/2
- **HTTP/REST** (fallback) — резервный транспорт
- **Protocol Buffers** — сериализация данных

#### Кодогенерация
API-модели генерируются автоматически из `.proto` файлов:

```bash
cd InterPrep/NetworkV2/Proto
./generate.sh
```

**Что генерируется:**
- `*.pb.swift` — Swift структуры для всех сообщений (8 файлов, ~340 KB кода)
- `gateway.grpc.swift` — gRPC клиент с методами API
- Type-safe модели с поддержкой сериализации/десериализации

**Преимущества:**
- Единый источник истины (.proto файлы синхронизированы с бэкендом)
- Type-safety — ошибки типов на этапе компиляции
- Автодополнение в Xcode для всех полей API
- Обратная совместимость при изменении API

**Пример использования:**

```swift
// Proto файл (coach.proto):
// message AskRequest {
//   optional string conversation_id = 1;
//   string question = 2;
// }

// Сгенерированный Swift код:
var request = Coach_AskRequest()
request.conversationID = "conv_123"
request.question = "Как подготовиться к собеседованию?"

// Type-safe, автодополнение работает, компилятор проверяет типы
let result = await networkService.ask(
    conversationId: request.conversationID,
    question: request.question
)
```

#### Возможности:
- Автоматическое обновление токенов при 401
- Retry с экспоненциальной задержкой при сбоях сети
- Ожидание восстановления соединения (`waitsForConnectivity`)
- Локальное кэширование токенов (UserDefaults)
- Кэширование фото профиля на диске

#### Services
Изолируют бизнес-логику от сетевых деталей:
- `AuthService` — регистрация, логин, сброс пароля
- `ResumeService` — работа с резюме (с кэшированием статуса)
- `VacancyService` — поиск вакансий, избранное
- `ChatService` — AI-коуч через gRPC streaming
- `DocumentService` — загрузка/скачивание файлов
- `CalendarService` — управление событиями

### Структура проекта

```
InterPrep/
├── Architecture/Core/          # Redux-подобная архитектура
│   ├── Store.swift            # Реактивный Store с @Published state
│   ├── EffectHandler.swift    # Протокол для побочных эффектов
│   └── State.swift            # FeatureState протокол
├── Screens/                   # Экраны приложения
│   ├── Discovery/
│   │   ├── DiscoveryView.swift           # Passive View
│   │   ├── DiscoveryView+Model.swift     # View Model (данные + колбэки)
│   │   ├── DiscoveryContainer.swift      # Навигация + связь Store↔View
│   │   └── Impl/
│   │       ├── DiscoveryState.swift      # State + Input/Feedback/Effect
│   │       ├── DiscoveryEffectHandler.swift  # Асинхронная логика
│   │       └── DiscoveryStore.swift      # Typealias Store
│   ├── Chat/
│   ├── Calendar/
│   ├── Documents/
│   └── Profile/
├── Services/                  # Бизнес-логика
│   ├── AuthServiceImpl.swift
│   ├── ResumeServiceImpl.swift
│   ├── VacancyServiceImpl.swift
│   ├── ChatServiceImpl.swift
│   └── ...
├── NetworkV2/                 # Сетевой слой
│   ├── NetworkService.swift   # Главный сервис (gRPC + HTTP)
│   ├── Core/
│   │   ├── AsyncNetworkService.swift  # HTTP клиент с retry
│   │   ├── TokenStorage.swift         # Хранение токенов
│   │   └── ProtoRequest.swift         # Request builder
│   ├── Proto/                 # Protocol Buffers
│   │   ├── *.proto            # API схемы (auth, user, coach, jobs, etc.)
│   │   ├── generate.sh        # Скрипт генерации Swift кода
│   │   └── Generated/         # Автогенерированные *.pb.swift файлы
│   └── Extensions/            # Factory методы для запросов
└── Components/                # UI-компоненты
    └── Navigation/
        └── MainTabView.swift  # Главная навигация
```

### Преимущества архитектуры

1. **Тестируемость** — вся логика в чистых функциях `reduce()` и изолированных `EffectHandler`
2. **Предсказуемость** — любое изменение UI — следствие изменения State
3. **Переиспользуемость** — View не зависят от Store, легко использовать в Preview
4. **Отладка** — весь поток данных прослеживается через Input/Effect/Feedback
5. **Масштабируемость** — легко добавлять новые экраны по шаблону
6. **Изоляция** — Services скрывают детали сети, EffectHandler изолирует async код
