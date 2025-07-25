# MeMachine iOS Setup Guide

## 🚀 Quick Setup

### 1. Install Dependencies

#### Add Supabase Swift SDK
1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Add: `https://github.com/supabase/supabase-swift`
4. Select the latest version

### 2. Configure Environment Variables

#### Copy Configuration Template
```bash
cd "iOS Client/iOS Client/Config"
cp Config.xcconfig.template Config.xcconfig
```

#### Update Your Secrets
Edit `Config.xcconfig` with your actual values:

```xcconfig
// Get these from: https://app.supabase.com/project/your-project/settings/api
SUPABASE_URL = https://your-actual-project-id.supabase.co
SUPABASE_ANON_KEY = your-actual-anon-key-here

// Your FastAPI backend URL
BACKEND_URL = http://localhost:8000
```

### 3. Add Config to Xcode Project

#### Link Configuration File to Xcode:
1. In Xcode, select your **project** (top of navigator)
2. Select your **target** (MeMachine)
3. Go to **Build Settings** tab
4. Search for "Configuration"
5. Under **User-Defined**, add:
   - `SUPABASE_URL` = `$(SUPABASE_URL)`
   - `SUPABASE_ANON_KEY` = `$(SUPABASE_ANON_KEY)`
   - `BACKEND_URL` = `$(BACKEND_URL)`

#### Or add to Info.plist:
Add these keys to your `Info.plist`:
```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
<key>BACKEND_URL</key>
<string>$(BACKEND_URL)</string>
```

### 4. Database Setup

#### Run Migrations
```bash
cd ../backend
supabase migration up
```

This will set up:
- ✅ Conversations and messages tables with realtime
- ✅ Profiles table with user management
- ✅ Row Level Security (RLS) policies
- ✅ Automatic profile creation on signup
- ✅ Proper indexes for performance

#### Start Your Backend
```bash
cd ../backend
python -m uvicorn main:app --reload
```

### 5. Build & Run

The app will validate your configuration on launch and show helpful error messages if anything is missing.

## 🔒 Security Notes

- ✅ `Config.xcconfig` is in `.gitignore` - your secrets won't be committed
- ✅ `Config.xcconfig.template` is committed - others can easily set up
- ✅ App validates configuration on launch with helpful error messages
- ✅ Supabase anon key is safe for client-side use (protected by RLS)

## 🏗️ Architecture

### Hybrid Approach:
- **Supabase Direct**: Conversations, Messages, Auth, Realtime
- **FastAPI Backend**: AI Processing, Voice, Complex Logic

### Benefits:
- ⚡ **Lightning fast** conversation loading
- 🔄 **Real-time updates** via Supabase
- 🤖 **AI processing** via your FastAPI backend
- 📱 **Offline support** built-in
- 🔐 **Secure** with Row Level Security

## 🐛 Troubleshooting

### Configuration Issues
If you see configuration errors:
1. Make sure `Config.xcconfig` exists and has real values
2. Verify the file is added to your Xcode project
3. Check that Info.plist has the environment variable references
4. Clean build folder: **Product → Clean Build Folder**

### Network Issues
- Make sure your FastAPI backend is running on the correct port
- Check that your Supabase URL is correct and accessible
- Verify your Supabase anon key is valid

### Build Issues
- Make sure Supabase Swift SDK is properly added
- Check that all files are added to your Xcode target
- Verify iOS deployment target compatibility

## 📱 Features

### Core Features
- ✅ Real-time conversations
- ✅ AI-powered chat responses  
- ✅ Dark mode support
- ✅ Optimistic UI updates
- ✅ Offline support
- ✅ Auto-scrolling messages
- ✅ Pull-to-refresh

### Authentication Features
- ✅ **Anonymous authentication** - Start chatting immediately
- ✅ **Email/password signup** - Create permanent accounts
- ✅ **Email/password signin** - Secure login
- ✅ **Password reset** - Forgot password recovery
- ✅ **User profiles** - Display names and avatars
- ✅ **Profile management** - Edit profile information
- ✅ **Secure sessions** - Automatic token refresh
- ✅ **Account upgrade** - Convert anonymous to permanent account

### Security Features
- ✅ **Row Level Security (RLS)** - Database-level security
- ✅ **Automatic profile creation** - Seamless user onboarding
- ✅ **Secure token management** - Handled by Supabase
- ✅ **Data isolation** - Users only see their own data

## 🔧 Development

### Mock Mode
If your backend isn't running, the app gracefully falls back to mock data for development.

### Realtime Testing
Open multiple simulators or devices to test real-time message synchronization.

### Debug Configuration
The app logs configuration status on launch - check the console for validation messages.