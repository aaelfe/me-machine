# routers/auth.py
from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from config import supabase

router = APIRouter()
security = HTTPBearer()

class UserProfile(BaseModel):
    id: str
    email: Optional[str] = None
    created_at: datetime
    preferences: Optional[dict] = {}

class AuthResponse(BaseModel):
    user: UserProfile
    access_token: str
    refresh_token: str

class SignUpRequest(BaseModel):
    email: str
    password: str

class SignInRequest(BaseModel):
    email: str
    password: str

@router.post("/signup", response_model=AuthResponse)
async def signup(request: SignUpRequest):
    """Sign up new user"""
    try:
        # Use Supabase auth
        auth_response = supabase.auth.sign_up({
            "email": request.email,
            "password": request.password
        })
        
        if auth_response.user:
            # Create user profile (id will be set to auth user id via foreign key)
            profile_data = {
                "id": auth_response.user.id,
                "email": request.email
            }
            
            supabase.table("profiles").insert(profile_data).execute()
            
            return AuthResponse(
                user=UserProfile(**profile_data),
                access_token=auth_response.session.access_token,
                refresh_token=auth_response.session.refresh_token
            )
        else:
            raise HTTPException(status_code=400, detail="Failed to create user")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/login", response_model=AuthResponse)
async def login(request: SignInRequest):
    """Login user"""
    try:
        auth_response = supabase.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password
        })
        
        if auth_response.user:
            # Get user profile
            profile = supabase.table("profiles").select("*").eq(
                "id", auth_response.user.id
            ).execute()
            
            if profile.data:
                return AuthResponse(
                    user=UserProfile(**profile.data[0]),
                    access_token=auth_response.session.access_token,
                    refresh_token=auth_response.session.refresh_token
                )
            else:
                # Create profile if it doesn't exist
                profile_data = {
                    "id": auth_response.user.id,
                    "email": request.email,
                    "preferences": {}
                }
                supabase.table("profiles").insert(profile_data).execute()
                
                return AuthResponse(
                    user=UserProfile(**profile_data),
                    access_token=auth_response.session.access_token,
                    refresh_token=auth_response.session.refresh_token
                )
        else:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/refresh")
async def refresh_token(refresh_token: str):
    """Refresh access token"""
    try:
        auth_response = supabase.auth.refresh_session(refresh_token)
        
        return {
            "access_token": auth_response.session.access_token,
            "refresh_token": auth_response.session.refresh_token
        }
    
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

@router.post("/logout")
async def logout(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Logout user"""
    try:
        supabase.auth.sign_out()
        return {"message": "Logged out successfully"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/me", response_model=UserProfile)
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user profile"""
    try:
        # Verify token and get user
        user = supabase.auth.get_user(credentials.credentials)
        
        if user:
            profile = supabase.table("profiles").select("*").eq(
                "id", user.user.id
            ).execute()
            
            if profile.data:
                return UserProfile(**profile.data[0])
            else:
                raise HTTPException(status_code=404, detail="User profile not found")
        else:
            raise HTTPException(status_code=401, detail="Invalid token")
    
    except Exception as e:
        raise HTTPException(status_code=401, detail="Authentication failed")

# Dependency to get current user ID
async def get_current_user_id(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """Dependency to extract user ID from token"""
    try:
        user = supabase.auth.get_user(credentials.credentials)
        if user and user.user:
            return user.user.id
        else:
            raise HTTPException(status_code=401, detail="Invalid token")
    except Exception as e:
        raise HTTPException(status_code=401, detail="Authentication failed")

# WebSocket auth function
async def get_current_user_id_ws(token: str) -> str:
    """Extract user ID from token for WebSocket connections"""
    try:
        user = supabase.auth.get_user(token)
        if user and user.user:
            return user.user.id
        else:
            raise Exception("Invalid token")
    except Exception as e:
        raise Exception("Authentication failed")

# @router.put("/preferences")
# async def update_preferences(
#     preferences: dict,
#     user_id: str = Depends(get_current_user_id)
# ):
#     """Update user preferences"""
#     try:
#         result = supabase.table("profiles").update({
#             "preferences": preferences
#         }).eq("id", user_id).execute()
        
#         return {"message": "Preferences updated successfully"}
    
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))