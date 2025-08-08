from fastapi import Request
from config import supabase

async def supabase_auth_middleware(request: Request, call_next):
    # Extract token if present
    if auth_header := request.headers.get("authorization"):
        token = auth_header.replace("Bearer ", "")
        # Set auth on your existing global supabase client
        supabase.postgrest.auth(token)
    
    response = await call_next(request)
    return response