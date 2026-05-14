#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROTO_DIR="$SCRIPT_DIR"
OUTPUT_DIR="$SCRIPT_DIR/Generated"

mkdir -p "$OUTPUT_DIR"

if ! command -v protoc &> /dev/null; then
    echo "Error: protoc is not installed"
    echo "Install it with: brew install protobuf"
    exit 1
fi

if ! command -v protoc-gen-swift &> /dev/null; then
    echo "Error: protoc-gen-swift is not installed"
    echo "Install it with: brew install swift-protobuf"
    exit 1
fi

echo "Generating Swift code from proto files..."

protoc \
    --proto_path="$PROTO_DIR" \
    --swift_out="$OUTPUT_DIR" \
    --swift_opt=Visibility=Public \
    "$PROTO_DIR"/*.proto

echo "✅ Swift code generated successfully in $OUTPUT_DIR"
