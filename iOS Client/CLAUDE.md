# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
- **Build in Xcode**: Open `MeMachine.xcodeproj` and use Cmd+B to build
- **Run app**: Use Cmd+R in Xcode or select a simulator/device and run
- **Clean build**: Product → Clean Build Folder in Xcode

### Testing
- **Run unit tests**: Cmd+U in Xcode or select the test target
- **UI tests**: Run the `MeMachineUITests` target
- **Test files**: Unit tests in `iOS ClientTests/`, UI tests in `iOS ClientUITests/`

### Setup Commands
```bash
# Initial setup (run from iOS Client directory)
cd "iOS Client/iOS Client/Config"
cp Config.xcconfig.template Config.xcconfig
# Edit Config.xcconfig with actual Supabase credentials

# Backend setup (if working with backend)
cd ../backend
supabase migration up
python -m uvicorn main:app --reload
```

## Architecture Overview

### Core Architecture Pattern
**Hybrid Supabase + FastAPI Backend Approach:**
- **Supabase Direct**: Authentication, conversations/messages storage, real-time subscriptions
- **FastAPI Backend**: AI processing, complex business logic, chat responses

### Key Services Architecture

1. **AuthService** (`Services/AuthService.swift`)
   - Singleton service managing all authentication state
   - Handles Supabase auth (email/password, OAuth placeholders)
   - Manages user profiles and session state
   - Publishes auth state changes to the app

2. **SupabaseService** (`Services/SupabaseService.swift`) 
   - Manages conversations and messages data layer
   - Delegates actual API calls to APIService for backend communication
   - Handles real-time subscriptions (currently using polling fallback)
   - Coordinates between Supabase storage and FastAPI processing

3. **APIService** (`Services/APIService.swift`)
   - HTTP client for FastAPI backend communication
   - Handles bearer token auth with Supabase sessions
   - Manages conversations CRUD and chat message processing
   - Backend endpoints: `/api/v1/conversations/`, `/api/v1/chat/message`

### Data Flow Pattern
```
User Input → View → SupabaseService → APIService → FastAPI Backend
                                   ↘ Supabase DB (via realtime)
```

### Configuration Management
- **SupabaseConfig.swift**: Hardcoded Supabase credentials and backend URL
- **Config.xcconfig + template**: Environment-based config (currently unused but setup exists)
- **SecretsManager.swift**: Additional secrets management utilities

### View Architecture
- **SwiftUI MVVM pattern** with `@StateObject` services
- **AuthView hierarchy**: `AuthView` → `SignInView`/`SignUpView`/`ProfileView`
- **Main app flow**: `ContentView` → `ConversationListView` → `ConversationDetailView`
- **Component-based**: Reusable components in `Views/Components/`

### Models
- **AuthUser**: User authentication model wrapping Supabase User
- **Conversation**: Chat conversation with metadata and message relationships  
- **Message**: Individual chat messages with role (user/assistant) and content

### Key Dependencies
- **Supabase Swift SDK**: Authentication, database, and realtime functionality
- **SwiftUI + Combine**: UI framework and reactive programming
- **Foundation URLSession**: HTTP networking for backend API calls

### Authentication Flow
1. App launches → `AuthService` checks existing session
2. User signs in → Supabase auth → `AuthService` updates state
3. Auth state change → `SupabaseService` receives user context
4. `APIService` uses Supabase session tokens for backend auth

### Development Notes
- Mock data fallback when backend is unavailable
- Real-time subscriptions currently use polling (RealtimeV2 API issues noted)
- Configuration validation on app launch with helpful error messages
- Hybrid architecture allows offline conversation viewing with online AI processing