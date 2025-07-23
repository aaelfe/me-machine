# config.py
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

class Settings:
    SUPABASE_URL = os.environ.get("SUPABASE_URL")
    SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
    OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
    
    def __post_init__(self):
        if not all([self.SUPABASE_URL, self.SUPABASE_KEY]):
            raise ValueError("Missing required environment variables")

settings = Settings()
supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)