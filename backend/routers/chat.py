# routers/chat.py
from fastapi import APIRouter, HTTPException, Depends, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from config import supabase, settings
from .auth import get_current_user_id, get_current_user_id_ws
import openai
import json
from typing import cast

try:
    # Optional import; endpoint will error with guidance if not generated
    from proto_utils.serialization import (
        encode_chat_chunk,
        encode_chat_complete,
        encode_error,
        ProtobufUnavailable,
    )
except Exception:
    encode_chat_chunk = None  # type: ignore
    encode_chat_complete = None  # type: ignore
    encode_error = None  # type: ignore
    class ProtobufUnavailable(RuntimeError):
        ...

router = APIRouter()

# Initialize OpenAI client
client = openai.OpenAI(api_key=settings.OPENAI_API_KEY)

class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[int] = None
    return_audio: bool = False
    context_type: Optional[str] = "check_in"  # "check_in", "general", "reflection"

class ChatResponse(BaseModel):
    message: str
    conversation_id: int
    audio_url: Optional[str] = None
    suggestions: Optional[List[str]] = None

@router.post("/message", response_model=ChatResponse)
async def send_text_message(
    request: ChatRequest,
    user_id: str = Depends(get_current_user_id)
):
    """Send text message and get AI response"""
    try:
        conversation_id = request.conversation_id
        
        # Create new conversation if none provided
        if not conversation_id:
            conv_result = supabase.table("conversations").insert({
                "user_id": user_id
            }).execute()
            conversation_id = conv_result.data[0]["id"]
        else:
            # Verify user owns this conversation
            conv_check = supabase.table("conversations").select("id").eq(
                "id", conversation_id
            ).eq("user_id", user_id).execute()
            
            if not conv_check.data:
                raise HTTPException(status_code=404, detail="Conversation not found")
        
        # Get conversation context
        context_messages = await get_conversation_messages(conversation_id)
        
        # Get user's recent check-ins for context
        user_context = await get_user_context(user_id)
        
        # Build system prompt based on context type
        system_prompt = build_system_prompt(request.context_type, user_context)
        
        # Prepare messages for OpenAI
        messages = [{"role": "system", "content": system_prompt}]
        
        # Add conversation history
        for msg in context_messages:
            role = "assistant" if msg["role"] == "ai" else "user"
            messages.append({"role": role, "content": msg["content"]})
        
        # Add current user message
        messages.append({"role": "user", "content": request.message})
        
        # Get AI response
        response = client.chat.completions.create(
            model="gpt-4",
            messages=messages,
            max_tokens=500,
            temperature=0.7
        )
        
        ai_message = response.choices[0].message.content
        
        # Save both messages to database
        await save_messages(conversation_id, [
            {"role": "user", "content": request.message},
            {"role": "ai", "content": ai_message}
        ])
        
        # Generate suggestions for follow-up
        suggestions = generate_suggestions(request.context_type, ai_message)
        
        return ChatResponse(
            message=ai_message,
            conversation_id=conversation_id,
            audio_url=None,  # TODO: Implement TTS if return_audio=True
            suggestions=suggestions
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/conversation/{conversation_id}")
async def get_conversation(
    conversation_id: int,
    user_id: str = Depends(get_current_user_id)
):
    """Get conversation history"""
    try:
        # Verify user owns this conversation
        conv_result = supabase.table("conversations").select("*").eq(
            "id", conversation_id
        ).eq("user_id", user_id).execute()
        
        if not conv_result.data:
            raise HTTPException(status_code=404, detail="Conversation not found")
        
        # Get messages
        messages = await get_conversation_messages(conversation_id)
        
        return {
            "conversation": conv_result.data[0],
            "messages": messages
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def get_conversation_messages(conversation_id: int) -> List[dict]:
    """Get messages for a conversation"""
    try:
        result = supabase.table("messages").select("*").eq(
            "conversation_id", conversation_id
        ).order("created_at", desc=False).execute()
        
        return result.data
    except Exception:
        return []

async def get_user_context(user_id: str) -> dict:
    """Get user context for personalized responses"""
    try:
        # Get recent check-ins
        recent_check_ins = supabase.table("daily_check_ins").select("*").eq(
            "user_id", user_id
        ).order("date", desc=True).limit(7).execute()
        
        # Get user's voice clone info
        voice_clones = supabase.table("voice_clones").select("*").eq(
            "user_id", user_id
        ).eq("is_active", True).execute()
        
        return {
            "recent_check_ins": recent_check_ins.data,
            "has_voice_clone": len(voice_clones.data) > 0,
            "check_in_streak": len(recent_check_ins.data)
        }
    
    except Exception as e:
        return {}

def build_system_prompt(context_type: str, user_context: dict) -> str:
    """Build system prompt based on context"""
    base_prompt = """You are an AI assistant that represents the user's best self. You're designed to help with daily check-ins, self-reflection, and personal growth. 
    
    Your personality should be:
    - Supportive and encouraging
    - Thoughtful and reflective
    - Like talking to your wisest, most caring self
    - Focused on growth and self-improvement
    
    """
    
    if context_type == "check_in":
        base_prompt += """
        You're helping the user with their daily check-in. Ask thoughtful questions about:
        - How they're feeling today
        - What went well recently
        - What challenges they're facing
        - Goals they want to work on
        - Reflections on their progress
        
        Keep responses conversational and personal.
        """
    
    elif context_type == "reflection":
        base_prompt += """
        You're helping the user reflect on their experiences and growth. 
        Focus on deeper questions and insights about patterns, progress, and personal development.
        """
    
    # Add user context
    if user_context.get("recent_check_ins"):
        recent_moods = [ci.get("mood_score") for ci in user_context["recent_check_ins"][:3]]
        base_prompt += f"\n\nRecent mood pattern: {', '.join(recent_moods)}"
    
    if user_context.get("check_in_streak", 0) > 1:
        base_prompt += f"\n\nThe user has been consistent with check-ins ({user_context['check_in_streak']} recent entries). Acknowledge this positively."
    
    return base_prompt

async def save_messages(conversation_id: int, messages: List[dict]):
    """Save messages to database"""
    try:
        message_data = []
        for msg in messages:
            message_data.append({
                "conversation_id": conversation_id,
                "role": msg["role"],
                "content": msg["content"]
            })
        
        supabase.table("messages").insert(message_data).execute()
    except Exception as e:
        print(f"Error saving messages: {e}")

def generate_suggestions(context_type: str, ai_message: str) -> List[str]:
    """Generate follow-up suggestions based on context"""
    if context_type == "check_in":
        return [
            "Tell me more about that",
            "How can I support you with this?",
            "What's one small step you could take?",
            "How does this compare to yesterday?"
        ]
    
    return [
        "Can you elaborate on that?",
        "What would you like to explore next?",
        "How are you feeling about this?"
    ]

@router.websocket("/ws")
async def websocket_chat_endpoint(websocket: WebSocket, token: str = None):
    """WebSocket endpoint for streaming chat responses"""
    await websocket.accept()
    
    try:
        # Get auth token from query parameter or headers
        auth_token = token
        if not auth_token and "authorization" in websocket.headers:
            auth_token = websocket.headers["authorization"].replace("Bearer ", "")
        
        # Try to get token from first message if not in headers/query
        if not auth_token:
            try:
                data = await websocket.receive_text()
                message_data = json.loads(data)
                auth_token = message_data.get("auth_token")
                if not auth_token:
                    await websocket.send_json({
                        "type": "error",
                        "error": "Authentication required"
                    })
                    await websocket.close()
                    return
            except Exception:
                await websocket.send_json({
                    "type": "error",
                    "error": "Authentication required"
                })
                await websocket.close()
                return
            
        # Validate user
        try:
            user_id = await get_current_user_id_ws(auth_token)
        except Exception as e:
            await websocket.send_json({
                "type": "error", 
                "error": "Invalid authentication"
            })
            await websocket.close()
            return
        
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            try:
                message_data = json.loads(data)
                print(f"Received WebSocket data. Message text: {message_data["message"]}")
            except json.JSONDecodeError as e:
                print(f"JSON decode error: {e}")
                await websocket.send_json({
                    "type": "error",
                    "error": f"Invalid JSON format: {str(e)}"
                })
                continue
            
            # Process streaming chat
            await handle_streaming_chat(
                websocket=websocket,
                user_id=user_id,
                message=message_data.get("message"),
                conversation_id=message_data.get("conversation_id"),
                context_type=message_data.get("context_type", "check_in")
            )
            
    except WebSocketDisconnect:
        print("WebSocket client disconnected")
    except Exception as e:
        print(f"WebSocket error: {e}")
        # Only try to send error if websocket is still open
        if websocket.client_state.name == 'CONNECTED':
            try:
                await websocket.send_json({
                    "type": "error",
                    "error": str(e)
                })
            except Exception as send_error:
                print(f"Failed to send error message: {send_error}")
        try:
            await websocket.close()
        except:
            pass

async def handle_streaming_chat(
    websocket: WebSocket,
    user_id: str,
    message: str,
    conversation_id: Optional[int] = None,
    context_type: str = "check_in"
):
    """Handle streaming chat conversation"""
    try:
        # Create new conversation if none provided
        if not conversation_id:
            conv_result = supabase.table("conversations").insert({
                "user_id": user_id
            }).execute()
            conversation_id = conv_result.data[0]["id"]
        else:
            # Verify user owns this conversation
            conv_check = supabase.table("conversations").select("id").eq(
                "id", conversation_id
            ).eq("user_id", user_id).execute()
            
            if not conv_check.data:
                await websocket.send_json({
                    "type": "error",
                    "error": "Conversation not found"
                })
                return
        
        # Get conversation context
        context_messages = await get_conversation_messages(conversation_id)
        
        # Get user's recent check-ins for context
        user_context = await get_user_context(user_id)
        
        # Build system prompt based on context type
        system_prompt = build_system_prompt(context_type, user_context)
        
        # Prepare messages for OpenAI
        messages = [{"role": "system", "content": system_prompt}]
        
        # Add conversation history
        for msg in context_messages:
            role = "assistant" if msg["role"] == "ai" else "user"
            messages.append({"role": role, "content": msg["content"]})
        
        # Add current user message
        messages.append({"role": "user", "content": message})
        
        # Save user message first
        await save_messages(conversation_id, [
            {"role": "user", "content": message}
        ])
        
        # Stream AI response
        full_response = ""
        stream = client.chat.completions.create(
            model="gpt-4",
            messages=messages,
            max_tokens=500,
            temperature=0.7,
            stream=True
        )
        
        for chunk in stream:
            if chunk.choices[0].delta.content:
                chunk_content = chunk.choices[0].delta.content
                full_response += chunk_content
                
                # Send chunk to client
                await websocket.send_json({
                    "type": "message_chunk",
                    "chunk": chunk_content,
                    "conversation_id": conversation_id
                })
        
        # Save AI response to database
        await save_messages(conversation_id, [
            {"role": "ai", "content": full_response}
        ])
        
        # Send completion message
        await websocket.send_json({
            "type": "message_complete",
            "message": full_response,
            "conversation_id": conversation_id
        })


@router.websocket("/ws-bin")
async def websocket_chat_proto_endpoint(websocket: WebSocket, token: str = None):
    """WebSocket endpoint that streams protobuf binary frames.

    Requires generated Python module at `backend/proto_gen/chat_stream_pb2.py`.
    See proto/README.md for generation instructions.
    """
    await websocket.accept()

    # Quick guard: ensure protobuf helpers are available
    if encode_chat_chunk is None or encode_chat_complete is None or encode_error is None:
        await websocket.send_bytes(b"")  # trigger client read
        await websocket.close(code=1011)
        return

    try:
        # Get auth token from query parameter or headers
        auth_token = token
        if not auth_token and "authorization" in websocket.headers:
            auth_token = websocket.headers["authorization"].replace("Bearer ", "")

        # Try to get token from first message if not in headers/query
        if not auth_token:
            try:
                data = await websocket.receive_text()
                message_data = json.loads(data)
                auth_token = message_data.get("auth_token")
                if not auth_token:
                    await websocket.close(code=1008)
                    return
            except Exception:
                await websocket.close(code=1008)
                return

        # Validate user
        try:
            user_id = await get_current_user_id_ws(cast(str, auth_token))
        except Exception:
            await websocket.close(code=1008)
            return

        while True:
            # Receive message from client (JSON for request envelope)
            data = await websocket.receive_text()
            try:
                message_data = json.loads(data)
            except json.JSONDecodeError as e:
                # Send protobuf error then continue
                try:
                    err_bytes = encode_error(
                        conversation_id=0,
                        message=f"Invalid JSON: {str(e)}",
                        code=400,
                    )
                    await websocket.send_bytes(err_bytes)
                except ProtobufUnavailable:
                    pass
                continue

            # Process streaming chat (same as JSON endpoint but binary out)
            conversation_id = message_data.get("conversation_id")
            context_type = message_data.get("context_type", "check_in")
            message = message_data.get("message")

            # Create or validate conversation
            if not conversation_id:
                conv_result = supabase.table("conversations").insert({
                    "user_id": user_id
                }).execute()
                conversation_id = conv_result.data[0]["id"]
            else:
                conv_check = supabase.table("conversations").select("id").eq(
                    "id", conversation_id
                ).eq("user_id", user_id).execute()
                if not conv_check.data:
                    err_bytes = encode_error(
                        conversation_id=0,
                        message="Conversation not found",
                        code=404,
                    )
                    await websocket.send_bytes(err_bytes)
                    continue

            # Context + messages
            context_messages = await get_conversation_messages(conversation_id)
            user_context = await get_user_context(user_id)
            system_prompt = build_system_prompt(context_type, user_context)

            messages = [{"role": "system", "content": system_prompt}]
            for msg in context_messages:
                role = "assistant" if msg["role"] == "ai" else "user"
                messages.append({"role": role, "content": msg["content"]})
            messages.append({"role": "user", "content": message})

            # Save user message first
            await save_messages(conversation_id, [
                {"role": "user", "content": message}
            ])

            # Stream OpenAI response and send protobuf chunks
            full_response = ""
            seq = 0
            stream = client.chat.completions.create(
                model="gpt-4",
                messages=messages,
                max_tokens=500,
                temperature=0.7,
                stream=True,
            )

            for chunk in stream:
                if chunk.choices[0].delta.content:
                    part = chunk.choices[0].delta.content
                    full_response += part
                    seq += 1
                    try:
                        bytes_msg = encode_chat_chunk(
                            conversation_id=conversation_id,
                            text=part,
                            sequence=seq,
                        )
                        await websocket.send_bytes(bytes_msg)
                    except ProtobufUnavailable:
                        # If protobuf generation isn't available, abort
                        await websocket.close(code=1011)
                        return

            # Save AI response
            await save_messages(conversation_id, [
                {"role": "ai", "content": full_response}
            ])

            # Send completion message
            try:
                done_bytes = encode_chat_complete(
                    conversation_id=conversation_id,
                    full_text=full_response,
                    suggestions=generate_suggestions(context_type, full_response),
                    sequence=seq + 1,
                )
                await websocket.send_bytes(done_bytes)
            except ProtobufUnavailable:
                await websocket.close(code=1011)
                return

    except WebSocketDisconnect:
        pass
    except Exception as e:
        try:
            if encode_error:
                err = encode_error(conversation_id=0, message=str(e), code=500)
                await websocket.send_bytes(err)
        finally:
            try:
                await websocket.close(code=1011)
            except Exception:
                pass
        
    except Exception as e:
        print(f"Streaming chat error: {e}")
        if websocket.client_state.name == 'CONNECTED':
            try:
                await websocket.send_json({
                    "type": "error",
                    "error": str(e)
                })
            except Exception as send_error:
                print(f"Failed to send streaming error: {send_error}")
