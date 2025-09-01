# Repository Guidelines

## Project Structure & Modules
- `backend/`: FastAPI service (`main.py`), middleware, and API routers in `routers/` (`auth.py`, `chat.py`, `voice.py`, `health.py`).
- `backend/supabase/`: Supabase project config and `migrations/`.
- `iOS Client/`: SwiftUI app (`iOS Client/…`), services, models, and views.
- `iOS ClientTests/` and `iOS ClientUITests/`: XCTest targets.

## Build, Test, and Dev Commands
- Backend: create env and run API
  - `cd backend && python -m venv .venv && source .venv/bin/activate`
  - `pip install -r requirements.txt`
  - `uvicorn main:app --reload` (serves FastAPI on `http://127.0.0.1:8000`).
- Supabase (optional, if using local DB):
  - `cd backend && supabase migration up` to apply migrations.
- iOS app:
  - Open `MeMachine.xcodeproj` in Xcode and Run.
  - CLI test: `xcodebuild -project "iOS Client/MeMachine.xcodeproj" -scheme "iOS Client" -destination 'platform=iOS Simulator,name=iPhone 15' test`.

## Coding Style & Naming
- Python: PEP 8, 4‑space indents, snake_case modules and functions; keep routers small and focused.
- Swift: Follow Swift API Design Guidelines; PascalCase types, camelCase properties/functions; prefer SwiftUI MVVM as used.
- Formatting: Xcode’s default formatter for Swift; for Python, follow PEP 8 (Black/Ruff are not configured).

## Testing Guidelines
- iOS: Place unit tests in `iOS ClientTests/` and UI tests in `iOS ClientUITests/`. Name tests `FeatureNameTests.swift`. Run from Xcode or with `xcodebuild … test`.
- Backend: If adding tests, place under `backend/tests/` and use FastAPI’s `TestClient` (pytest is not yet configured). Keep handlers pure and dependency‑inject external services when possible.

## Commit & Pull Requests
- Commits: concise, imperative mood (e.g., "Add auth middleware", "Fix chat streaming") to match history.
- PRs must include:
  - Summary, scope, and rationale; link related issues.
  - Screenshots/video for iOS UI changes; sample requests for backend endpoints.
  - Local verification steps (e.g., `uvicorn` run, simulator device).

## Security & Configuration
- Backend uses env vars: `SUPABASE_URL`, `SUPABASE_KEY`, `OPENAI_API_KEY` (dotenv supported). Create `backend/.env` and never commit secrets.
- iOS config: prefer `Config.xcconfig` (see `iOS Client/SETUP.md`) or Info.plist keys (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `BACKEND_URL`). Do not commit real keys.
- CORS in dev is wide open; restrict `allow_origins` for production.

