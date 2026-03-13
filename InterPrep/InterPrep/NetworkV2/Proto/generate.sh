#!/bin/bash

# Script to generate Swift code from proto files

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROTO_DIR="$SCRIPT_DIR"
OUTPUT_DIR="$SCRIPT_DIR/Generated"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if protoc is installed
if ! command -v protoc &> /dev/null; then
    echo "Error: protoc is not installed"
    echo "Install it with: brew install protobuf"
    exit 1
fi

# Check if swift-protobuf plugin is installed
if ! command -v protoc-gen-swift &> /dev/null; then
    echo "Error: protoc-gen-swift is not installed"
    echo "Install it with: brew install swift-protobuf"
    exit 1
fi

echo "Generating Swift code from proto files..."

# Generate Swift code for all proto files with public visibility
protoc \
    --proto_path="$PROTO_DIR" \
    --swift_out="$OUTPUT_DIR" \
    --swift_opt=Visibility=Public \
    "$PROTO_DIR"/*.proto

# gRPC client: в проекте уже есть ручной Generated/gateway.grpc.swift (только Register/Login).
# Если нужен полный клиент по всем методам — раскомментируйте блок ниже и запустите с protoc-gen-grpc-swift в PATH (перезапишет gateway.grpc.swift).
# if command -v protoc-gen-grpc-swift &> /dev/null; then
#     protoc --proto_path="$PROTO_DIR" --grpc-swift_out="$OUTPUT_DIR" --plugin=protoc-gen-grpc-swift="$(command -v protoc-gen-grpc-swift)" "$PROTO_DIR"/gateway.proto
# fi

echo "✅ Swift code generated successfully in $OUTPUT_DIR"
