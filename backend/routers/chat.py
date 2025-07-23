# routers/chat.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from config import supabase, settings
import openai

router = APIRouter()

# Set OpenAI API key
openai.api_key = settings.OPENAI_API_KEY

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
    user_id: str  # TODO: Get from auth dependency
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
        response = await openai.ChatCompletion.acreate(
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
    user_id: str  # TODO: Get from auth dependency
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