Protobuf Schemas
================

This folder contains the canonical `.proto` schemas shared between the backend and the iOS client. Generate language-specific code into each platform’s own `*_Gen` folder.

Layout
- `proto/chat_stream.proto`: Envelope and payloads for binary WebSocket streaming.
- Python output: `backend/proto_gen/`
- Swift output: `iOS Client/ProtoGen/`

Generate Code

Prereqs
- Install `protoc` (Protocol Buffers compiler).
- Python runtime: `pip install protobuf` (and optionally `grpcio-tools` for `python -m grpc_tools.protoc`).
- Swift runtime: Install the SwiftProtobuf plugin (`brew install swift-protobuf`) which provides `protoc-gen-swift`.

Python (backend)
1. From repo root:
   - Using protoc directly:
     protoc \
       --proto_path=proto \
       --python_out=backend/proto_gen \
       proto/chat_stream.proto

   - Or using grpcio-tools:
     python -m grpc_tools.protoc \
       -I proto \
       --python_out=backend/proto_gen \
       proto/chat_stream.proto

Swift (iOS)
1. From repo root:
   protoc \
     --proto_path=proto \
     --swift_out="iOS Client/ProtoGen" \
     proto/chat_stream.proto

Notes
- Keep `.proto` schemas here; do not edit generated code by hand.
- If the backend can’t import `backend/proto_gen/chat_stream_pb2.py`, it falls back to an explicit error indicating you need to generate code.

