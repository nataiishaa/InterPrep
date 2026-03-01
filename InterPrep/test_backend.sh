#!/bin/bash

echo "🔍 Тестирование бэкенда на http://193.124.33.223:9090"
echo ""

# Тест 1: gRPC reflection
echo "1️⃣ Проверка gRPC reflection:"
grpcurl -plaintext 193.124.33.223:9090 list 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ gRPC reflection работает"
else
    echo "❌ gRPC reflection не доступен (нужен grpcurl: brew install grpcurl)"
fi

echo ""

# Тест 2: HTTP POST с JSON
echo "2️⃣ Проверка HTTP + JSON:"
curl -X POST \
  http://193.124.33.223:9090/gateway.BackendGateway/Login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}' \
  -v 2>&1 | grep -E "HTTP|Content-Type"

echo ""

# Тест 3: HTTP POST с Protobuf
echo "3️⃣ Проверка HTTP + Protobuf:"
curl -X POST \
  http://193.124.33.223:9090/gateway.BackendGateway/Login \
  -H "Content-Type: application/x-protobuf" \
  -d '{"email":"test@test.com","password":"test123"}' \
  -v 2>&1 | grep -E "HTTP|Content-Type"

echo ""
echo "✅ Тест завершен"
