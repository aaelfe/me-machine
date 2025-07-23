# routers/voice.py
from fastapi import APIRouter, File, UploadFile, HTTPException, Form
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import uuid
import os
from config import supabase, settings

router = APIRouter()

class VoiceCloneResponse(BaseModel):
    id: int  # Changed to int to match bigint
    name: str
    elevenlabs_voice_id: Optional[str]
    is_active: bool
    created_at: datetime

class VoiceMessageRequest(BaseModel):
    text: str
    voice_clone_id: Optional[int] = None
    conversation_id: Optional[int] = None

@router.post("/message")
async def send_voice_message(
    audio: UploadFile = File(...),
    conversation_id: Optional[int] = Form(None),
    user_id: str = Form(...)  # TODO: Get from auth dependency
):
    """Process voice message: STT -> LLM -> TTS pipeline"""
    try:
        # TODO: Implement STT (Speech-to-Text)
        # - Save uploaded audio file
        # - Send to OpenAI Whisper or similar service
        # - Extract text from audio
        
        # TODO: Process through LLM
        # - Send text to OpenAI GPT with daily check-in context
        # - Generate appropriate response
        
        # TODO: Generate TTS response
        # - Use user's voice clone if available
        # - Generate audio response
        # - Save audio file
        
        # Placeholder response
        return {
            "message": "Voice processing not yet implemented",
            "conversation_id": conversation_id or 1,  # Placeholder
            "audio_url": None
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/audio/{audio_id}")
async def get_audio_file(audio_id: str):
    """Download generated audio file"""
    try:
        # TODO: Retrieve audio file from storage
        # For now, return placeholder
        raise HTTPException(status_code=404, detail="Audio file not found")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/clone", response_model=VoiceCloneResponse)
async def create_voice_clone(
    voice_samples: List[UploadFile] = File(...),
    voice_name: str = Form(...),
    user_id: str = Form(...)  # TODO: Get from auth dependency
):
    """Upload voice samples to create voice clone"""
    try:
        # TODO: Implement ElevenLabs voice cloning
        # - Save uploaded voice samples
        # - Send to ElevenLabs API for voice cloning
        # - Store voice clone ID in database
        
        # Create voice clone record
        voice_clone_data = {
            "user_id": user_id,
            "name": voice_name,
            "elevenlabs_voice_id": None,  # Will be set after ElevenLabs processing
            "is_active": True
        }
        
        result = supabase.table("voice_clones").insert(voice_clone_data).execute()
        
        return result.data[0]
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/clones", response_model=List[VoiceCloneResponse])
async def list_voice_clones(
    user_id: str  # TODO: Get from auth dependency
):
    """List user's voice clones"""
    try:
        result = supabase.table("voice_clones").select("*").eq(
            "user_id", user_id
        ).eq("is_active", True).execute()
        
        return result.data
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/clones/{voice_clone_id}")
async def delete_voice_clone(
    voice_clone_id: int,  # Changed to int
    user_id: str  # TODO: Get from auth dependency
):
    """Delete a voice clone"""
    try:
        # Soft delete - mark as inactive
        result = supabase.table("voice_clones").update({
            "is_active": False
        }).eq("id", voice_clone_id).eq("user_id", user_id).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Voice clone not found")
        
        return {"message": "Voice clone deleted successfully"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/synthesize")
async def synthesize_speech(
    request: VoiceMessageRequest,
    user_id: str  # TODO: Get from auth dependency
):
    """Convert text to speech using user's voice clone"""
    try:
        # TODO: Implement TTS with voice cloning
        # - Get user's active voice clone
        # - Send text to ElevenLabs with voice ID
        # - Return audio file
        
        return {
            "message": "Text-to-speech not yet implemented",
            "audio_url": None
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))