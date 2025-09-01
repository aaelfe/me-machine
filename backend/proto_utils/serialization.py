from typing import List, Optional

try:
    from backend.proto_gen import chat_stream_pb2 as pb  # type: ignore
except Exception:
    try:
        # Fallback if running from backend package context
        from proto_gen import chat_stream_pb2 as pb  # type: ignore
    except Exception:
        pb = None  # Will be checked at runtime


class ProtobufUnavailable(RuntimeError):
    pass


def _require_pb() -> None:
    if pb is None:
        raise ProtobufUnavailable(
            "Protobuf code not found. Generate with protoc into backend/proto_gen (see proto/README.md)."
        )


def encode_chat_chunk(
    conversation_id: int,
    text: str,
    stream_id: Optional[str] = None,
    sequence: Optional[int] = None,
) -> bytes:
    _require_pb()
    env = pb.ChatStreamEnvelope(
        conversation_id=conversation_id,
        chunk=pb.ChatChunk(text=text),
    )
    if stream_id is not None:
        env.stream_id = stream_id
    if sequence is not None:
        env.sequence = sequence
    return env.SerializeToString()


def encode_chat_complete(
    conversation_id: int,
    full_text: str,
    suggestions: Optional[List[str]] = None,
    stream_id: Optional[str] = None,
    sequence: Optional[int] = None,
) -> bytes:
    _require_pb()
    complete = pb.ChatComplete(full_text=full_text)
    if suggestions:
        complete.suggestions.extend(suggestions)
    env = pb.ChatStreamEnvelope(
        conversation_id=conversation_id,
        complete=complete,
    )
    if stream_id is not None:
        env.stream_id = stream_id
    if sequence is not None:
        env.sequence = sequence
    return env.SerializeToString()


def encode_error(
    conversation_id: int,
    message: str,
    code: int = 500,
    stream_id: Optional[str] = None,
    sequence: Optional[int] = None,
) -> bytes:
    _require_pb()
    env = pb.ChatStreamEnvelope(
        conversation_id=conversation_id,
        error=pb.StreamError(code=code, message=message),
    )
    if stream_id is not None:
        env.stream_id = stream_id
    if sequence is not None:
        env.sequence = sequence
    return env.SerializeToString()

