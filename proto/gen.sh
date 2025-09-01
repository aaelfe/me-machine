#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
PROTO_DIR="$ROOT_DIR/proto"
PY_OUT="$ROOT_DIR/backend/proto_gen"
SWIFT_OUT="$ROOT_DIR/iOS Client/ProtoGen"

echo "Generating Python..."
if python -c "import grpc_tools.protoc" >/dev/null 2>&1; then
  python -m grpc_tools.protoc -I "$PROTO_DIR" --python_out="$PY_OUT" "$PROTO_DIR/chat_stream.proto"
else
  protoc -I "$PROTO_DIR" --python_out="$PY_OUT" "$PROTO_DIR/chat_stream.proto"
fi

echo "Generating Swift..."
protoc -I "$PROTO_DIR" --swift_out="$SWIFT_OUT" "$PROTO_DIR/chat_stream.proto"

echo "Done."

