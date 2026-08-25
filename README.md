# SIKANUA — Nutrition & Fitness AI System

A complete full-stack AI application with:

- **PyTorch + FastAPI** backend (OpenAI-compatible `/v1/chat/completions`)
- **Next.js 15** web frontend (streaming chat UI)
- **Flutter** mobile frontend (iOS & Android)

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    SIKANUA SYSTEM                        │
│                                                          │
│  ┌─────────────┐     ┌─────────────┐   ┌─────────────┐  │
│  │  Flutter    │     │  Next.js 15 │   │  Any OpenAI │  │
│  │  Mobile App │     │  Web App    │   │  Client     │  │
│  └──────┬──────┘     └──────┬──────┘   └──────┬──────┘  │
│         │                   │                  │         │
│         └───────────────────┼──────────────────┘         │
│                             │                            │
│                    ┌────────▼────────┐                   │
│                    │  FastAPI Server │                   │
│                    │  :8000          │                   │
│                    │                 │                   │
│                    │  POST /v1/chat/ │                   │
│                    │  completions    │                   │
│                    │  GET  /v1/models│                   │
│                    │  POST /v1/plan  │                   │
│                    └────────┬────────┘                   │
│                             │                            │
│                    ┌────────▼────────┐                   │
│                    │  SikanuaNet     │                   │
│                    │  (PyTorch)      │                   │
│                    │                 │                   │
│                    │  UserEncoder    │                   │
│                    │  DietHead       │                   │
│                    │  FitnessHead    │                   │
│                    │  RiskHead       │                   │
│                    └─────────────────┘                   │
└──────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Option A — Docker Compose (Backend + Next.js)

```bash
git clone <repo>
cd sikanua
docker-compose up --build
```

- Web app:  http://localhost:3000  
- API docs: http://localhost:8000/docs

---

### Option B — Manual

#### 1. Backend (Python 3.11+)

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Verify it's running:
```bash
curl http://localhost:8000/
# {"service":"SIKANUA AI","version":"1.0.0","status":"ok"}
```

#### 2. Next.js Web Frontend

```bash
cd nextjs-frontend
npm install
npm run dev          # http://localhost:3000
```

Set the API URL via env if backend is not on localhost:
```bash
NEXT_PUBLIC_SIKANUA_API_URL=http://your-server:8000 npm run dev
```

#### 3. Flutter Mobile App

```bash
cd flutter-frontend
flutter pub get
flutter run          # connects to localhost:8000 by default
```

To change the backend URL, edit `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER:8000';
```

For Android emulator, use `http://10.0.2.2:8000` instead of localhost.  
For iOS simulator, `http://localhost:8000` works as-is.

---

## API Reference

The backend exposes an OpenAI-compatible API. You can point **any** OpenAI SDK
client at `http://localhost:8000` with model `sikanua-v1`.

### List models
```bash
curl http://localhost:8000/v1/models
```

### Chat completion (non-streaming)
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "sikanua-v1",
    "messages": [
      {
        "role": "user",
        "content": "Generate my plan:\n```json\n{\"age\":28,\"sex\":\"female\",\"height_cm\":165,\"weight_kg\":68,\"activity_level\":\"moderately_active\",\"goal\":\"weight_loss\",\"diet_style\":\"vegan\",\"training_days\":4,\"health_conditions\":{\"diabetes\":false}}\n```"
      }
    ],
    "stream": false
  }'
```

### Chat completion (streaming)
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"sikanua-v1","messages":[{"role":"user","content":"Generate plan: ```json\n{\"age\":30,\"sex\":\"male\",\"height_cm\":178,\"weight_kg\":85,\"activity_level\":\"very_active\",\"goal\":\"muscle_gain\",\"diet_style\":\"omnivore\",\"training_days\":5,\"health_conditions\":{}}\n```"}],"stream":true}'
```

### Direct plan endpoint (structured JSON response)
```bash
curl -X POST http://localhost:8000/v1/plan \
  -H "Content-Type: application/json" \
  -d '{
    "age": 35,
    "sex": "male",
    "height_cm": 180,
    "weight_kg": 90,
    "activity_level": "moderately_active",
    "goal": "weight_loss",
    "diet_style": "mediterranean",
    "training_days": 3,
    "health_conditions": { "hypertension": true }
  }'
```

---

## User Profile Schema

```json
{
  "age": 28,
  "sex": "female | male | other",
  "height_cm": 165,
  "weight_kg": 68,
  "activity_level": "sedentary | lightly_active | moderately_active | very_active | athlete",
  "goal": "weight_loss | maintenance | muscle_gain | performance | general_health",
  "diet_style": "omnivore | vegetarian | vegan | pescatarian | keto | mediterranean | halal | kosher",
  "meals_per_day": 3,
  "cooking_skill": "none | beginner | intermediate | advanced",
  "training_days": 3,
  "session_duration": "short | medium | long | extended",
  "budget": "low | moderate | high",
  "equipment_access": "none | home | full_gym | outdoor",
  "exercise_history": "none | beginner | intermediate | advanced",
  "sleep_hours": 7.0,
  "stress_level": 4,
  "water_litres": 2.0,
  "health_conditions": {
    "diabetes": false,
    "hypertension": false,
    "ckd": false,
    "celiac": false,
    "ibs": false,
    "pcos": false,
    "cardiac_history": false,
    "osteoporosis": false,
    "eating_disorder_recovery": false,
    "thyroid_condition": false,
    "high_cholesterol": false
  }
}
```

---

## PyTorch Model Details

**SikanuaNet** is a multi-head neural network:

| Component | Architecture | Output |
|-----------|-------------|--------|
| `UserProfileEncoder` | Linear → LayerNorm → GELU → Dropout (×2) → Linear | 64-dim embedding |
| `DietHead` | Linear(64→64) → GELU → Linear(64→32) → GELU → Linear(32→8) | 8 diet params |
| `FitnessHead` | Linear(64→64) → GELU → Linear(64→32) → GELU → Linear(32→6) | 6 fitness params |
| `RiskHead` | Linear(64→32) → GELU → Linear(32→3) → Sigmoid | 3 risk scores |

Input: 35-dimensional normalised user profile vector  
The model outputs are decoded by a rule-augmented generator that enforces
clinical constraints (sodium caps, GI limits, RPE ceilings, etc.)

---

## Project Structure

```
sikanua/
├── backend/
│   ├── main.py             # FastAPI app + PyTorch model
│   ├── requirements.txt
│   └── Dockerfile
│
├── nextjs-frontend/
│   ├── src/
│   │   ├── app/            # Next.js App Router
│   │   ├── components/     # Welcome, ProfileForm, ChatInterface
│   │   ├── lib/api.ts      # Streaming API client
│   │   ├── store/index.ts  # Zustand state
│   │   └── types/index.ts
│   ├── package.json
│   └── Dockerfile
│
├── flutter-frontend/
│   ├── lib/
│   │   ├── main.dart           # App entry + router
│   │   ├── models/             # UserProfile, ChatMessage
│   │   ├── services/           # ApiService (streaming)
│   │   ├── providers/          # AppProvider (ChangeNotifier)
│   │   ├── screens/            # WelcomeScreen, ProfileScreen, ChatScreen
│   │   ├── widgets/            # Shared UI components
│   │   └── theme/              # SikanuaTheme
│   └── pubspec.yaml
│
├── docker-compose.yml
└── README.md
```

---

## Use with Any OpenAI Client

Because the backend implements the OpenAI spec, you can use it with
any existing OpenAI SDK by just swapping the base URL:

```python
# Python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8000/v1", api_key="not-needed")
response = client.chat.completions.create(
    model="sikanua-v1",
    messages=[{"role": "user", "content": "Generate plan: ..."}],
    stream=True,
)
for chunk in response:
    print(chunk.choices[0].delta.content or "", end="", flush=True)
```

```javascript
// JavaScript / TypeScript
import OpenAI from 'openai';

const client = new OpenAI({ baseURL: 'http://localhost:8000/v1', apiKey: 'x' });
const stream = client.chat.completions.stream({
  model: 'sikanua-v1',
  messages: [{ role: 'user', content: 'Generate plan: ...' }],
});
for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content ?? '');
}
```
