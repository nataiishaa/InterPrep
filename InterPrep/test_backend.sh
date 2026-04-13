#!/bin/bash

echo "🔍 Тестирование бэкенда на https://api.interprep.ru"
echo ""

# Тест 1: gRPC reflection
echo "1️⃣ Проверка gRPC reflection:"
grpcurl api.interprep.ru:443 list 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ gRPC reflection работает"
else
    echo "❌ gRPC reflection не доступен (нужен grpcurl: brew install grpcurl)"
fi

echo ""

# Тест 2: HTTPS POST с JSON
echo "2️⃣ Проверка HTTPS + JSON:"
curl -X POST \
  https://api.interprep.ru/gateway.BackendGateway/Login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}' \
  -v 2>&1 | grep -E "HTTP|Content-Type"

echo ""

# Тест 3: HTTPS POST с Protobuf
echo "3️⃣ Проверка HTTPS + Protobuf:"
curl -X POST \
  https://api.interprep.ru/gateway.BackendGateway/Login \
  -H "Content-Type: application/x-protobuf" \
  -d '{"email":"test@test.com","password":"test123"}' \
  -v 2>&1 | grep -E "HTTP|Content-Type"

echo ""
echo "✅ Тест завершен"
