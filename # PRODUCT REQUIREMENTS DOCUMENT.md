# PRODUCT REQUIREMENTS DOCUMENT  
**Backend System – KreaSea AI Content Studio**

**Versi:** 1.0  
**Tanggal:** 12 Mei 2026  
**Author:** Grok (Academic Success Partner & Full-Stack Consultant)  
**Status:** Final – Siap Implementasi  
**Platform:** Flutter Mobile App + Firebase + Multi-AI Providers  
**Tujuan Dokumen:** Memberikan spesifikasi lengkap, arsitektur, dan instruksi implementasi backend yang aman, scalable, maintainable, dan kompatibel dengan aplikasi KreaSea yang sudah ada.

---

## 1. RINGKASAN EKSEKUTIF & CATATAN KRITIS

**Tujuan Backend**
- Menjadi **single secure entry point** untuk semua client (Flutter Mobile App, Admin Dashboard, Bio Link static pages).
- Mengintegrasikan **multi-AI providers** dengan intelligence (auto-switch key jika rate-limit/quota habis).
- **Keamanan maksimal**: Tidak ada API key AI yang pernah bocor ke client-side.
- Mendukung seluruh fitur dari arsitektur existing (lihat gambar “Arsitektur KREASEA APP.png”) dan fitur tambahan v1.0 (PRD Fitur Tambahan).
- Siap skalabilitas hingga ribuan user aktif.

**Improvement Wajib dari Arsitektur Existing**
- Single API key per provider → rentan downtime & biaya tak terkendali.
- Semua AI call **WAJIB** melalui backend (tidak boleh hardcode key di Flutter).
- Belum ada AI Orchestrator untuk auto-switch & fallback.
- Codebase harus modular agar mudah ditambahkan fitur baru tanpa rewrite besar.

**Instruksi Khusus untuk AI Dev Agent**
Anda **boleh dan diharapkan** melakukan penyesuaian sesuai codebase aplikasi existing (Flutter + Firebase + Node.js/FastAPI yang sudah ada).  
- Sesuaikan dengan fitur & menu yang sudah berjalan (Caption Generator, Image Generator, Content Planner, Content Library, dll).  
- Jangan hapus endpoint yang sudah ada.  
- Prioritaskan kompatibilitas 100% dengan arsitektur yang sudah digambar di “Arsitektur KREASEA APP.png”.  
- Gunakan dokumen ini sebagai blueprint, bukan rigid template.

---

## 2. ARSITEKTUR BACKEND YANG DIREKOMENDASIKAN

```mermaid
graph TD
    A[Client: Flutter / Admin Dashboard] -->|HTTPS + JWT| B[API Gateway]
    B --> C[Authentication & Rate Limiting]
    B --> D[Request Validation & Prompt Orchestration]
    B --> E[AI Orchestrator Layer]
    E --> F[Multi-Key Manager + Fallback]
    F --> G[Gemini API / Stability AI / Claude / GPT]
    E --> H[Redis Cache]
    B --> I[Backend Services]
    I --> J[Auth & Profile]
    I --> K[Content AI Service]
    I --> L[Image Generation Service]
    I --> M[Business Tools HPP / GMaps / Bio Link / dll]
    I --> N[Quota, Billing, Notification]
    I --> O[Content Library & Planner]
    J & K & L & M & N & O --> P[Firebase Firestore + Storage + FCM]
    P --> Q[Midtrans / Xendit]
    B --> R[Logging, Monitoring, Sentry]
Stack Teknologi yang Direkomendasikan









































LayerTeknologiAlasan UtamaAPI GatewayFastAPI (Python) atau Node.jsAsync, dokumentasi otomatis, rate-limit built-inServicesFastAPI modular / NestJSType safety & maintainability tinggiAI OrchestratorDedicated module di FastAPICentralisasi key rotation & fallbackCacheRedisQuota & response cachingDatabaseFirebase Firestore + RedisRealtime + performaQueueCelery / BullMQBackground jobsObservabilitySentry + Prometheus + GrafanaWajib untuk KP & productionDeploymentDocker + Railway / Fly.io / GCPMudah scale
Prioritas Implementasi (untuk AI Dev Agent)

AI Orchestrator + Multi-Key Manager (paling kritis).
API Gateway + Auth middleware.
Endpoint fitur inti (content/generate, image/generate, hpp/calculate, dll).
Integrasi dengan Firebase existing.


3. MULTI-API KEY MANAGEMENT (Fitur Baru – PRIORITAS TINGGI)
Requirement

Minimal 3–5 API key per provider (Gemini, Stability, Claude, GPT).
Auto-switch jika rate-limit / quota habis / error 429/5xx.
Semua key disimpan hanya di backend (environment + secret manager).

Data Model (Firestore + Redis)
JSON// Collection: ai_providers
{
  "provider": "gemini",
  "keys": [
    { 
      "key_id": "g1", 
      "encrypted_value": "...", 
      "status": "active", 
      "quota_remaining": 95000, 
      "last_used": "timestamp" 
    }
  ],
  "priority_order": ["g1", "g2", "g3"],
  "fallback_provider": "claude"
}
Alur Orchestrator (wajib diimplementasikan)

Client panggil endpoint → Gateway validasi JWT + user quota.
Orchestrator ambil key aktif dari Redis.
Kirim request ke AI.
Jika error 429 → tandai key cooldown, ambil key berikutnya, retry (max 3x).
Jika semua key gagal → fallback ke provider lain.
Update quota di background.

Acceptance Criteria

Tidak ada API key yang pernah terkirim ke Flutter.
Retry & fallback selesai < 5 detik.
Admin dashboard bisa melihat usage per key (tanpa menampilkan nilai key).


4. SECURITY & COMPLIANCE (WAJIB)

Firebase Auth + custom JWT (15 menit expiry).
Rate limiting per user & global.
Input validation ketat (Pydantic / Zod).
Firestore Security Rules yang ketat.
CORS + HTTPS via Cloudflare.
Semua AI call melalui backend.
Audit log untuk action penting.


5. API DESIGN STANDARDS
Standard Response Wrapper (semua endpoint):
JSON{
  "success": true,
  "data": { ... },
  "error": null,
  "meta": { "timestamp": "..." }
}
Contoh Endpoint Penting yang Harus Ada

POST /api/v1/content/generate
POST /api/v1/image/generate
POST /api/v1/hpp/calculate
POST /api/v1/gmaps/optimize
POST /api/v1/biolink/create
POST /api/v1/photo-analysis
GET /api/v1/ai/orchestrator/status (admin only)

Versioning: /api/v1/...

6. ERROR HANDLING, LOGGING, MONITORING

Centralized error middleware.
Graceful fallback untuk semua AI call.
Structured logging ke Sentry.
Alert jika quota critical atau error rate > 5%.


7. DEPLOYMENT & MAINTAINABILITY

Docker + Docker Compose untuk development.
CI/CD GitHub Actions.
Environment: dev, staging, production.
Codebase modular (folder per service).
OpenAPI/Swagger documentation otomatis.


8. NEXT STEPS & CHECKLIST UNTUK AI DEV AGENT
Langkah yang Harus Dilakukan (berurutan)

Review seluruh dokumen existing (arsitektur gambar, PRD Fitur Tambahan, Panduan KP).
Setup AI Orchestrator + Multi-Key Manager terlebih dahulu.
Integrasikan dengan Firebase & endpoint yang sudah ada.
Implementasikan endpoint baru sesuai PRD Fitur Tambahan.
Tambahkan rate limiting, caching, dan Sentry.
Buat dokumentasi backend/README.md + Swagger.
Test end-to-end dengan Flutter app yang existing.
Deploy ke staging dan berikan akses testing.

Catatan Akhir untuk AI Dev Agent
Anda memiliki kebebasan penuh untuk menyesuaikan teknis (FastAPI/Node.js) selama tetap sesuai dengan arsitektur existing dan menjaga keamanan. Prioritaskan kompatibilitas dengan aplikasi Flutter yang sudah berjalan. Jika ada konflik, dokumentasikan dan beri rekomendasi.