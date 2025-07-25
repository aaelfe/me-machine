# routers/conversations.py
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from config import supabase
from .auth import get_current_user_id

router = APIRouter()

class ConversationResponse(BaseModel):
    id: int  # Will be converted from bigint by Pydantic
    user_id: str
    created_at: datetime

@router.post("/", response_model=ConversationResponse)
async def create_conversation(
    user_id: str = Depends(get_current_user_id)
):
    """Create new conversation"""
    try:
        conversation_data = {
            "user_id": user_id
        }
        
        result = supabase.table("conversations").insert(conversation_data).execute()
        
        return result.data[0]
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/", response_model=List[ConversationResponse])
async def list_conversations(
    limit: int = 50,
    user_id: str = Depends(get_current_user_id)
):
    """List user's conversations"""
    try:
        result = supabase.table("conversations").select("*").eq(
            "user_id", user_id
        ).order("created_at", desc=True).limit(limit).execute()
        
        return result.data
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{conversation_id}", response_model=ConversationResponse)
async def get_conversation(
    conversation_id: int,
    user_id: str = Depends(get_current_user_id)
):
    """Get specific conversation"""
    try:
        result = supabase.table("conversations").select("*").eq(
            "id", conversation_id
        ).eq("user_id", user_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Conversation not found")
        
        return result.data[0]
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{conversation_id}")
async def delete_conversation(
    conversation_id: int,
    user_id: str = Depends(get_current_user_id)
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
    user_id: str = Depends(get_current_user_id)
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