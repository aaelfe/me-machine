# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import voice, chat, conversations, auth, health

app = FastAPI(
    title="Me Machine API", 
    version="1.0.0",
    description="Daily check-in AI assistant with voice cloning"
)

# CORS middleware for iOS client
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["authentication"])
app.include_router(voice.router, prefix="/api/v1/voice", tags=["voice"])
app.include_router(chat.router, prefix="/api/v1/chat", tags=["chat"])
app.include_router(conversations.router, prefix="/api/v1/conversations", tags=["conversations"])
app.include_router(health.router, tags=["health"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)