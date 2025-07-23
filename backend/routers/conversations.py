# routers/conversations.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from config import supabase

router = APIRouter()

class ConversationResponse(BaseModel):
    id: int  # Changed to int to match bigint in schema
    user_id: str
    created_at: datetime
    message_count: int

@router.post("/", response_model=ConversationResponse)
async def create_conversation(
    user_id: str  # TODO: Get from auth dependency
):
    """Create new conversation"""
    try:
        conversation_data = {
            "user_id": user_id
        }
        
        result = supabase.table("conversations").insert(conversation_data).execute()
        
        # Get message count (0 for new conversation)
        response_data = result.data[0]
        response_data["message_count"] = 0
        
        return response_data
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[ConversationResponse])
async def list_conversations(
    user_id: str,  # TODO: Get from auth dependency
    limit: int = 50
):
    """List user's conversations"""
    try:
        result = supabase.table("conversations").select("*").eq(
            "user_id", user_id
        ).order("created_at", desc=True).limit(limit).execute()
        
        # Get message counts for each conversation
        conversations = []
        for conv in result.data:
            # Get message count for this conversation
            msg_count = supabase.table("messages").select("id", count="exact").eq(
                "conversation_id", conv["id"]
            ).execute()
            
            conv["message_count"] = msg_count.count or 0
            conversations.append(conv)
        
        return conversations
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{conversation_id}", response_model=ConversationResponse)
async def get_conversation(
    conversation_id: int,
    user_id: str  # TODO: Get from auth dependency
):
    """Get specific conversation"""
    try:
        result = supabase.table("conversations").select("*").eq(
            "id", conversation_id
        ).eq("user_id", user_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Conversation not found")
        
        conversation = result.data[0]
        
        # Get actual message count
        msg_count = supabase.table("messages").select("id", count="exact").eq(
            "conversation_id", conversation_id
        ).execute()
        
        conversation["message_count"] = msg_count.count or 0
        
        return conversation
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{conversation_id}")
async def delete_conversation(
    conversation_id: int,
    user_id: str  # TODO: Get from auth dependency
):
    """Delete conversation and all its messages"""
    try:
        # Messages will be deleted automatically due to CASCADE constraint
        result = supabase.table("conversations").delete().eq(
            "id", conversation_id
        ).eq("user_id", user_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Conversation not found")
        
        return {"message": "Conversation deleted successfully"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{conversation_id}/messages")
async def get_conversation_messages(
    conversation_id: int,
    user_id: str  # TODO: Get from auth dependency
):
    """Get all messages in a conversation"""
    try:
        # First verify user owns this conversation
        conv_result = supabase.table("conversations").select("id").eq(
            "id", conversation_id
        ).eq("user_id", user_id).execute()
        
        if not conv_result.data:
            raise HTTPException(status_code=404, detail="Conversation not found")
        
        # Get messages
        result = supabase.table("messages").select("*").eq(
            "conversation_id", conversation_id
        ).order("created_at", desc=False).execute()
        
        return {"conversation_id": conversation_id, "messages": result.data}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))