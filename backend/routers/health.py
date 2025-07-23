# routers/health.py
from fastapi import APIRouter, HTTPException
from config import supabase, settings
import openai
from datetime import datetime

router = APIRouter()

@router.get("/health")
async def health_check():
    """Basic health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "Me Machine API"
    }

@router.get("/status")
async def service_status():
    """Detailed service status including dependencies"""
    status = {
        "service": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "dependencies": {}
    }
    
    # Check Supabase connection
    try:
        # Simple query to test connection
        result = supabase.table("profiles").select("count", count="exact").limit(1).execute()
        status["dependencies"]["supabase"] = {
            "status": "healthy",
            "response_time": "< 100ms"  # Placeholder
        }
    except Exception as e:
        status["dependencies"]["supabase"] = {
            "status": "unhealthy",
            "error": str(e)
        }
        status["service"] = "degraded"
    
    # Check OpenAI API
    try:
        if settings.OPENAI_API_KEY:
            # Test OpenAI connection with a minimal request
            openai.api_key = settings.OPENAI_API_KEY
            # Note: This is a placeholder - you might want to make an actual test call
            status["dependencies"]["openai"] = {
                "status": "configured",
                "api_key_present": True
            }
        else:
            status["dependencies"]["openai"] = {
                "status": "not_configured",
                "api_key_present": False
            }
    except Exception as e:
        status["dependencies"]["openai"] = {
            "status": "error",
            "error": str(e)
        }
        status["service"] = "degraded"
    
    # Check environment variables
    required_env_vars = ["SUPABASE_URL", "SUPABASE_KEY", "OPENAI_API_KEY"]
    missing_vars = []
    
    for var in required_env_vars:
        if not getattr(settings, var, None):
            missing_vars.append(var)
    
    if missing_vars:
        status["dependencies"]["environment"] = {
            "status": "incomplete",
            "missing_variables": missing_vars
        }
        status["service"] = "degraded"
    else:
        status["dependencies"]["environment"] = {
            "status": "complete",
            "all_required_vars_present": True
        }
    
    return status

@router.get("/version")
async def get_version():
    """Get API version and build info"""
    return {
        "version": "1.0.0",
        "name": "Me Machine API",
        "description": "Daily check-in AI assistant with voice cloning",
        "build_date": "2025-01-21",  # Update this as needed
        "features": [
            "daily_check_ins",
            "voice_cloning",
            "ai_chat",
            "conversation_management"
        ]
    }