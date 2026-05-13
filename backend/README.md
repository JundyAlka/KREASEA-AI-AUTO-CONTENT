# KreaSea Backend — AI Orchestrator

Backend Node.js (Fastify) untuk KreaSea AI Content Studio.  
Semua API key AI tersimpan aman di server — tidak pernah dikirim ke Flutter.

## Arsitektur Singkat

```
Flutter App
    ↓ (Firebase JWT)
Fastify API Gateway  ← Port 3001
    ↓
┌─────────────────────────────────┐
│   Text Orchestrator             │  ← 5 Gemini key + fallback OpenAI
│   Image Orchestrator            │  ← 5 Stability AI key + fallback Replicate
│   Redis Cache (Upstash)         │  ← Response caching & key state
│   Firebase Admin SDK            │  ← Verifikasi JWT + Firestore quota
└─────────────────────────────────┘
```

## Setup Development

### 1. Install dependencies
```bash
cd backend
npm install
```

### 2. Konfigurasi environment
```bash
cp .env.example .env
# Edit .env — isi GEMINI_TEXT_KEY_1..5 dan STABILITY_IMAGE_KEY_1..5
```

### 3. Firebase Service Account
Di Firebase Console → Project Settings → Service Accounts → Generate new private key.  
Paste isi JSON ke `FIREBASE_SERVICE_ACCOUNT_JSON` di `.env` (satu baris).

### 4. Jalankan server
```bash
# Development (auto-restart on change)
npm run dev

# Production
npm start
```

### 5. Test health check
```bash
curl http://localhost:3001/api/v1/health
```

## Endpoint Utama

| Method | Endpoint | Fungsi |
|--------|----------|--------|
| GET | `/api/v1/health` | Health check (public) |
| POST | `/api/v1/content/generate` | Semua text AI |
| POST | `/api/v1/image/generate` | Image generation |
| POST | `/api/v1/hpp/calculate` | Kalkulator HPP |
| POST | `/api/v1/hpp/ai-advice` | AI saran harga |
| POST | `/api/v1/photo-analysis` | Analisis foto produk |
| GET | `/api/v1/admin/key-status` | Status key pool (admin only) |

## Multi-Key Orchestrator

- **Text**: 5 Gemini key → round-robin → cooldown 60s jika 429 → fallback OpenAI
- **Image**: 5 Stability AI key → round-robin → cooldown 1 jam jika credit habis → fallback Replicate
- **Cache**: Redis/in-memory, TTL per fitur (5–15 menit untuk text, 0 untuk DM replies)

## Deploy ke Railway

```bash
# Install Railway CLI
npm i -g @railway/cli

# Login & deploy
railway login
railway init
railway up

# Set semua env vars
railway vars set GEMINI_TEXT_KEY_1=AIza... GEMINI_TEXT_KEY_2=AIza...
```

## Struktur Folder

```
backend/
├── src/
│   ├── app.js                    ← Entry point
│   ├── config/
│   │   └── firebase-admin.js     ← Firebase SDK singleton
│   ├── orchestrators/
│   │   ├── text-orchestrator.js  ← 5 Gemini key manager
│   │   └── image-orchestrator.js ← 5 Stability AI key manager
│   ├── middleware/
│   │   ├── auth.js               ← Firebase JWT verify
│   │   └── rate-limit.js         ← Per-user daily quota
│   ├── routes/v1/
│   │   ├── content.js            ← Text generation endpoints
│   │   ├── image.js              ← Image generation endpoints
│   │   ├── hpp.js                ← HPP calculator
│   │   ├── photo-analysis.js     ← Gemini Vision
│   │   └── admin.js              ← Key monitoring (admin)
│   ├── cache/
│   │   └── redis.client.js       ← Redis + in-memory fallback
│   └── utils/
│       └── response.js           ← Standard response wrapper
├── .env.example
├── .gitignore
├── Dockerfile
├── docker-compose.yml
└── package.json
```
