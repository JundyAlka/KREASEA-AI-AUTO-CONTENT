# PRODUCT REQUIREMENTS DOCUMENT

**KreaSea — AI Content Studio untuk UMKM**  
**Fitur Tambahan & Sistem Expand Menu**

## Informasi Dokumen

| Informasi       | Detail                                      |
|-----------------|---------------------------------------------|
| Versi Dokumen   | 1.0                                         |
| Tanggal         | Maret 2026                                  |
| Author          | Jundy Alka — Founder & Product Lead         |
| Dev Target      | Muhaimin — Tech Lead                        |
| Platform        | Flutter (Android & iOS)                     |
| Status          | Draft — Siap untuk Development              |
| Cakupan PRD     | 11 Fitur Baru + Sistem Expand Menu Home     |

## 📌 Cara Menggunakan Dokumen Ini

Setiap fitur memiliki: Deskripsi, User Story, Spesifikasi Fungsional, Alur Backend, API Endpoint, Prompt AI, Error Handling, dan Acceptance Criteria. Dokumen ini adalah instruksi lengkap untuk developer — tidak perlu interpretasi tambahan.

---

## BAGIAN 0 — SISTEM HOME & EXPAND MENU

### 0.1 Konsep Tampilan Home

Halaman beranda (home) KreaSea menampilkan maksimal 6 fitur teratas secara default. Jika jumlah fitur melebihi 6, tampil tombol **'Lihat Semua Fitur'** di bagian bawah grid. Saat diklik, section menu expand menampilkan semua fitur dalam grid scrollable.

### 0.2 Spesifikasi Widget Home Menu

| Properti          | Nilai                                                                 |
|-------------------|-----------------------------------------------------------------------|
| Grid layout       | 2 kolom, 3 baris = 6 item tampil default                              |
| Item per baris    | 2                                                                     |
| Max item default  | 6 (urutan sesuai `priority_order` di Firestore)                       |
| Tombol expand     | `'Lihat Semua Fitur →'` muncul jika total fitur > 6                   |
| Animasi expand    | `AnimatedContainer` slide-down, durasi 300ms                          |
| State expand      | Disimpan di local state (tidak persist ke Firestore)                  |
| Icon badge        | Setiap item bisa punya badge: `'Baru'`, `'Pro'`, `'Soon'`             |

### 0.3 Data Model Menu di Firestore

```json
// Collection: app_features
{
  "id": "hpp_calculator",
  "name": "Kalkulator HPP",
  "icon": "calculate",
  "color": "#1A56DB",
  "route": "/features/hpp",
  "priority_order": 1,
  "is_visible": true,
  "badge": "Baru",
  "is_coming_soon": false,
  "required_plan": "free",
  "created_at": "Timestamp"
}
```

### 0.4 Flutter Implementation Notes

- Gunakan `StreamBuilder` dari Firestore collection `app_features` untuk data menu yang bisa diupdate real-time tanpa update app
- Sort berdasarkan `priority_order` ascending
- Filter `is_visible == true`
- Widget: `FeatureGridItem` — card dengan icon, label, badge, dan ripple effect
- Expand button: hanya render jika total item > 6
- Expanded state: tampilkan semua item dalam `GridView.builder` dengan `NeverScrollableScrollPhysics` (scroll oleh parent)

---

## FITUR 1 — KALKULATOR HPP & HARGA JUAL

### 🎯 Overview

Membantu pelaku UMKM menghitung Harga Pokok Produksi (HPP) secara akurat, kemudian AI merekomendasikan harga jual optimal berdasarkan margin yang dipilih dan analisis pasar sederhana.

### 1.1 User Story

- Sebagai pelaku UMKM, saya ingin menghitung HPP produk saya dengan mudah agar saya tahu modal sebenarnya
- Sebagai pelaku UMKM, saya ingin mendapat rekomendasi harga jual dari AI agar saya tidak rugi dan tetap kompetitif
- Sebagai pelaku UMKM, saya ingin melihat proyeksi laba jika saya jual sekian unit per bulan

### 1.2 Spesifikasi Fungsional

**Input Form — 3 Kategori Biaya**

| Kategori       | Field Input                  | Tipe Data          | Contoh                     |
|----------------|------------------------------|--------------------|----------------------------|
| Bahan Baku     | Nama bahan, Qty, Satuan, Harga/satuan | Text + Number     | Tepung 500g Rp 8.000      |
| Tenaga Kerja   | Deskripsi, Jam kerja, Upah/jam       | Number            | Dekorasi 2 jam @ Rp 25.000|
| Biaya Overhead | Listrik, Gas, Sewa, Kemasan, dll     | Number            | Gas Rp 3.000/batch        |
| Jumlah Produksi| Berapa unit dihasilkan dari input di atas | Number       | 12 pcs per batch          |

**Output yang Ditampilkan**

- HPP per unit = (Total Bahan Baku + Total TK + Total Overhead) / Jumlah Produksi
- Slider margin keuntungan: 10% / 20% / 30% / 40% / Custom %
- Harga jual rekomendasi per tier margin
- Proyeksi laba bersih: input 'target jual X unit/bulan' → tampil laba bulanan
- Tombol **'Minta Saran AI'** → AI analisis apakah harga kompetitif + saran positioning

### 1.3 Backend & Kalkulasi

**Endpoint**

`POST /api/hpp/calculate`  
Authorization: Bearer {token}

**Request Body:**

```json
{
  "bahan_baku": [
    {"nama":"Tepung","qty":500,"satuan":"gram","harga_satuan":16}
  ],
  "tenaga_kerja": [
    {"deskripsi":"Membuat adonan","jam":1,"upah_per_jam":25000}
  ],
  "overhead": [
    {"nama":"Gas","biaya":3000},
    {"nama":"Kemasan","biaya":2000}
  ],
  "jumlah_produksi": 12
}
```

**Response:**

```json
{
  "hpp_total_batch": 75000,
  "hpp_per_unit": 6250,
  "breakdown": {
    "bahan_baku": 8000,
    "tenaga_kerja": 25000,
    "overhead": 5000
  },
  "rekomendasi_harga": {
    "margin_20": 7500,
    "margin_30": 8125,
    "margin_40": 8750
  }
}
```

**Endpoint AI Saran**

`POST /api/hpp/ai-advice`

```json
{
  "hpp_per_unit": 6250,
  "harga_jual": 8000,
  "kategori_produk": "Makanan - Kue & Snack",
  "lokasi": "Yogyakarta"
}
```

**Prompt AI untuk Saran HPP**

```
System: Kamu adalah konsultan bisnis UMKM Indonesia yang ahli dalam strategi penetapan harga.
Gunakan bahasa Indonesia yang ramah dan mudah dipahami.

User: HPP produk saya adalah Rp {hpp_per_unit}/unit.
Saya berencana menjualnya seharga Rp {harga_jual}/unit.
Kategori: {kategori_produk}. Lokasi usaha: {lokasi}.

Berikan:
1. Analisis apakah harga tersebut kompetitif (2-3 kalimat)
2. Risiko jika harga terlalu rendah atau terlalu tinggi
3. Saran harga psikologis yang lebih menarik (misal Rp 14.900 vs Rp 15.000)
4. Tips meningkatkan perceived value agar bisa jual lebih mahal
Format: poin-poin singkat, maksimal 150 kata total.
```

### 1.4 Error Handling

| Kondisi Error              | Handling                                      |
|----------------------------|-----------------------------------------------|
| Semua field kosong         | Disable tombol Hitung, tampil hint 'Isi minimal 1 bahan baku' |
| HPP = 0 (input salah)      | Tampil warning: 'HPP tidak boleh 0, periksa kembali input' |
| AI timeout > 10 detik      | Tampil hasil HPP tetap, AI advice section tampil 'Coba lagi' |
| Jumlah produksi = 0        | Validasi frontend, error: 'Jumlah produksi harus lebih dari 0' |

### 1.5 Acceptance Criteria

1. Kalkulasi HPP akurat secara matematis — verified dengan unit test
2. Slider margin real-time update harga jual tanpa loading
3. AI saran tampil dalam < 8 detik
4. Hasil bisa disimpan ke Content Library dengan nama produk
5. Bisa tambah/hapus item bahan baku secara dinamis

---

## FITUR 2 — OPTIMASI NAMA & PROFIL GOOGLE MAPS

### 🎯 Overview

AI membantu UMKM membuat nama bisnis Google Maps yang SEO-friendly, deskripsi bisnis yang optimal, memilih kategori yang tepat, dan memberikan panduan langkah-by-langkah verifikasi Google Bisnisku.

### 2.1 User Story

- Sebagai pelaku UMKM, saya ingin nama toko di Google Maps saya mudah ditemukan oleh calon pembeli
- Sebagai pelaku UMKM, saya ingin deskripsi bisnis yang menarik dan mengandung kata kunci yang tepat
- Sebagai pelaku UMKM, saya ingin tahu cara daftar dan verifikasi Google Bisnisku step by step

### 2.2 Spesifikasi Fungsional

**Input Form**

| Field                    | Tipe     | Keterangan                                      |
|--------------------------|----------|-------------------------------------------------|
| Nama Usaha Asli          | Text     | Nama yang sudah ada atau ingin dipakai          |
| Jenis Usaha              | Dropdown | F&B, Fashion, Jasa, Retail, Kecantikan, dll     |
| Lokasi (Kota/Kecamatan)  | Text     | Untuk lokalisasi rekomendasi                    |
| Produk/Jasa Utama        | Text (max 100 char) | Apa yang paling dicari dari usaha ini     |
| Keunikan Usaha           | Text (max 150 char) | Apa yang membedakan dari kompetitor       |

**Output AI**

- 3 opsi nama GMaps yang direkomendasikan + penjelasan mengapa setiap nama efektif
- Deskripsi bisnis 150-200 kata yang siap copy-paste ke Google Bisnisku
- 5 kata kunci utama yang harus ada di profil
- Rekomendasi kategori Google Maps utama + 2 kategori tambahan
- Checklist panduan setup Google Bisnisku (10 langkah dengan screenshot tips)
- Template Q&A — 5 pertanyaan umum + jawaban yang bisa diisi di GMaps

### 2.3 Backend & Prompt

**Endpoint:** `POST /api/gmaps/optimize`

**Request:**

```json
{
  "nama_usaha": "Kue Ibu Sari",
  "jenis_usaha": "F&B - Kue & Roti",
  "lokasi": "Sleman, Yogyakarta",
  "produk_utama": "Kue ulang tahun custom dan brownies",
  "keunikan": "Bahan premium, bisa custom desain, ready 1 hari"
}
```

**System Prompt:**

```
Kamu adalah ahli SEO lokal dan Google My Business untuk UMKM Indonesia.
```

**User Prompt:**

```
Bantu optimalkan profil Google Maps untuk usaha berikut:
- Nama: {nama_usaha}
- Jenis: {jenis_usaha}
- Lokasi: {lokasi}
- Produk utama: {produk_utama}
- Keunikan: {keunikan}

Berikan output dalam format JSON:
{
  "nama_rekomendasi": [
    {"nama": "...", "alasan": "..."},
    {"nama": "...", "alasan": "..."},
    {"nama": "...", "alasan": "..."}
  ],
  "deskripsi_bisnis": "...",
  "kata_kunci": ["...", "...", "...", "...", "..."],
  "kategori_utama": "...",
  "kategori_tambahan": ["...", "..."],
  "qa_template": [
    {"pertanyaan": "...", "jawaban": "..."}
  ]
}
```

### 2.4 Acceptance Criteria

6. AI menghasilkan minimum 3 opsi nama yang berbeda karakter
7. Deskripsi bisnis mengandung lokasi + kata kunci produk
8. Semua output bisa di-copy dengan 1 tap
9. Ada tombol 'Simpan ke Library' untuk semua output
10. Panduan setup GMaps tersedia dalam format checklist interaktif (bisa dicentang)

---

## FITUR 3 — BIO LINK GENERATOR

### 🎯 Overview

Generate halaman bio link (seperti Linktree) yang sudah jadi dan bisa langsung digunakan. User input semua link penting → sistem generate halaman HTML yang di-host di subdomain KreaSea → user dapat link unik untuk ditempel di bio Instagram/TikTok.

### 3.1 User Story

- Sebagai pelaku UMKM, saya ingin satu link yang berisi semua cara menghubungi dan membeli dari saya
- Sebagai pelaku UMKM, saya ingin bio link saya terlihat profesional dengan nama dan logo toko saya
- Sebagai pelaku UMKM, saya ingin tahu berapa orang yang klik link saya

### 3.2 Spesifikasi Fungsional

**Input**

| Field          | Keterangan                                      | Wajib?    |
|----------------|-------------------------------------------------|-----------|
| Nama Toko      | Tampil sebagai judul halaman bio link           | Ya        |
| Foto/Logo      | Upload gambar profil (dari HP atau URL)         | Opsional  |
| Tagline        | 1 kalimat deskripsi singkat                     | Opsional  |
| Link WhatsApp  | Nomor WA dengan pesan otomatis                  | Opsional  |
| Link Instagram | @username                                       | Opsional  |
| Link TikTok    | @username                                       | Opsional  |
| Link Tokopedia | URL toko                                        | Opsional  |
| Link Shopee    | URL toko                                        | Opsional  |
| Link Gojek/Grab| Link pesan antar                                | Opsional  |
| Link Website   | URL website                                     | Opsional  |
| Link Kustom    | Label + URL bebas (max 3 tambahan)              | Opsional  |
| Tema Warna     | 5 pilihan tema warna pre-built                  | Ya        |

**Output**

- URL unik: `kreasea.page/{username_toko}` atau `kreasea.link/{id}`
- Halaman HTML responsif yang mobile-optimized
- QR Code otomatis yang bisa didownload
- Dashboard klik sederhana: total klik hari ini, minggu ini, all-time

### 3.3 Backend System

**Firestore Collection: `bio_links`**

```json
{
  "id": "auto-generated",
  "user_id": "firebase_uid",
  "slug": "kue-ibu-sari",
  "nama_toko": "Kue Ibu Sari",
  "tagline": "Kue custom premium Jogja",
  "photo_url": "https://...",
  "theme": "dark_blue",
  "links": [
    {"platform": "whatsapp", "url": "https://wa.me/628...", "label": "Chat WA", "order": 1},
    {"platform": "instagram", "url": "https://instagram.com/...", "label": "Follow IG", "order": 2},
    {"platform": "tokopedia", "url": "https://tokopedia.com/...", "label": "Beli di Tokopedia", "order": 3}
  ],
  "click_count": 0,
  "is_active": true,
  "created_at": "Timestamp",
  "updated_at": "Timestamp"
}
```

**Endpoint**

- `POST /api/biolink/create` — buat bio link baru
- `GET /api/biolink/{slug}` — fetch data untuk render halaman
- `PUT /api/biolink/{id}/update` — update links
- `GET /api/biolink/{id}/stats` — statistik klik
- `POST /api/biolink/track-click` — record klik (dipanggil dari halaman bio link)
- `GET /p/{slug}` — serve halaman bio link HTML

### 3.4 Acceptance Criteria

11. Bio link tersedia dan bisa dibuka dalam < 5 detik setelah dibuat
12. Halaman bio link tampil optimal di mobile (terutama setelah klik dari Instagram bio)
13. QR code bisa didownload sebagai PNG
14. Click tracking akurat dengan delay maksimal 1 menit
15. User bisa edit/update link kapan saja tanpa URL berubah
16. Maksimal 1 bio link per akun di plan free, unlimited di plan berbayar

---

## FITUR 4 — TESTIMONI & REVIEW REQUEST GENERATOR

### 🎯 Overview

AI generate pesan WhatsApp/DM yang sopan dan efektif untuk meminta ulasan dari pembeli. Plus template respons untuk bintang 1-5, dan template follow-up order.

### 4.1 User Story

- Sebagai pelaku UMKM, saya ingin template pesan minta review yang tidak terkesan memaksa
- Sebagai pelaku UMKM, saya ingin tahu cara membalas review bintang 1 dengan profesional
- Sebagai pelaku UMKM, saya ingin template follow-up untuk cek kepuasan setelah pembelian

### 4.2 Spesifikasi Fungsional

**Menu Utama — 4 Sub-Fitur**

| Sub-Fitur            | Fungsi                                              |
|----------------------|-----------------------------------------------------|
| Request Review WA    | Generate pesan WA meminta ulasan setelah pembelian  |
| Respons Review       | Template membalas ulasan bintang 1 s/d 5 di marketplace/GMaps |
| Follow-up Order      | Pesan check-in kepuasan 1-3 hari setelah produk diterima |
| Thank You Message    | Pesan ucapan terima kasih personal setelah transaksi |

**Input per Sub-Fitur**

| Sub-Fitur            | Input yang Diperlukan                                      |
|----------------------|------------------------------------------------------------|
| Request Review WA    | Nama pembeli (opsional), nama produk, platform ulasan target (GMaps/Shopee/Tokped/IG) |
| Respons Review       | Rating bintang (1-5), isi ulasan pembeli (teks bebas), nama toko |
| Follow-up Order      | Nama pembeli, nama produk, estimasi tiba (misal: 2 hari lalu) |
| Thank You Message    | Nama pembeli (opsional), nama produk, channel pembelian    |

### 4.3 Prompt AI

**Request Review**

```
System: Kamu adalah asisten komunikasi UMKM Indonesia yang ramah.
Buat pesan WA meminta ulasan yang: sopan, tidak memaksa, singkat (max 3 paragraf),
dan terasa personal bukan copy-paste massal.

User: 
- Nama pembeli: {nama} (kosong = gunakan "Kak")
- Produk: {nama_produk}
- Platform ulasan: {platform}
- Tone brand: {tone_brand dari profil usaha}
```

**Respons Review Bintang 1**

```
System: Buat respons profesional untuk ulasan negatif yang: 
empati, tidak defensif, tawarkan solusi konkret, singkat (max 4 kalimat).
User: Ulasan pembeli: "{isi_ulasan}"
```

### 4.4 Acceptance Criteria

17. Generate 2 variasi pesan untuk setiap sub-fitur
18. Tombol copy langsung tersedia di setiap variasi
19. Tone menyesuaikan profil brand (formal/santai sesuai onboarding)
20. Respons bintang 1 selalu menyertakan elemen: empati + solusi + ajakan kontak langsung

---

## FITUR 5 — AI CONTENT CALENDAR (AUTO PLANNER)

### 🎯 Overview

AI generate jadwal konten lengkap untuk 7, 14, atau 30 hari ke depan. Setiap hari sudah ada: topik konten, angle/hook, platform, waktu posting optimal, dan draft caption. Semua langsung masuk ke Content Planner.

### 5.1 User Story

- Sebagai pelaku UMKM, saya ingin rencana konten 1 bulan yang sudah jadi tanpa harus mikir setiap hari
- Sebagai pelaku UMKM, saya ingin konten saya beragam — tidak hanya promosi, tapi juga edukasi dan hiburan
- Sebagai pelaku UMKM, saya ingin jadwal otomatis mempertimbangkan hari besar dan momen penting

### 5.2 Spesifikasi Fungsional

**Input**

| Field              | Tipe          | Keterangan                                      |
|--------------------|---------------|-------------------------------------------------|
| Durasi             | Pilihan       | 7 hari / 14 hari / 30 hari                      |
| Frekuensi posting  | Pilihan       | 1x/hari / 2x/hari / 3x/hari / Hari kerja saja   |
| Platform           | Multi-select  | Instagram, TikTok, Facebook, WhatsApp, semua    |
| Fokus Konten       | Multi-select  | Promosi produk, Edukasi, Behind the scenes, Testimoni, Hari besar |
| Produk Highlight   | Text (opsional)| Produk yang ingin difokuskan bulan ini         |

**Output per Hari**

- Tanggal & hari
- Topik konten (contoh: 'Cara memilih kue untuk hampers')
- Tipe konten: Post Feed / Story / Reels / Carousel
- Hook/angle pembuka yang menarik perhatian
- Draft caption siap pakai (bisa diklik untuk buka di Caption Generator untuk dikustomisasi)
- Waktu posting optimal berdasarkan platform
- Hashtag rekomendasi
- Catatan hari besar jika ada (misal: Hari Ibu, Harbolnas)

### 5.3 Backend & Prompt

**Endpoint:** `POST /api/content-calendar/generate`

```json
{
  "durasi_hari": 30,
  "frekuensi": "1x_hari",
  "platform": ["instagram", "tiktok"],
  "fokus": ["promosi", "edukasi", "testimoni"],
  "produk_highlight": "Brownies Lumer Premium",
  "tanggal_mulai": "2026-04-01"
}
```

**System Prompt:**

```
Kamu adalah social media strategist untuk UMKM Indonesia.
Generate rencana konten {durasi_hari} hari untuk usaha {jenis_usaha} bernama {nama_brand}.

Rules:
- Mix konten: 40% promosi, 30% edukasi, 20% engagement, 10% behind the scenes
- Perhatikan hari besar Indonesia dalam periode {tanggal_mulai} - {tanggal_selesai}
- Waktu posting optimal: Instagram 07.00/12.00/19.00, TikTok 19.00/21.00
- Caption max 150 kata, casual tapi informatif
```

**Output format JSON array:**

```json
[{
  "tanggal": "2026-04-01",
  "hari": "Rabu",
  "hari_besar": null,
  "tipe_konten": "Reels",
  "topik": "...",
  "hook": "...",
  "caption_draft": "...",
  "hashtag": ["...", "..."],
  "waktu_posting": "19:00",
  "platform": "Instagram"
}]
```

### 5.4 Integrasi dengan Content Planner

- Setelah calendar di-generate, tampil preview seluruh jadwal dalam tampilan list
- Tombol **'Simpan ke Planner'** — semua item masuk ke Content Planner dengan status 'Draft'
- User bisa edit setiap item sebelum menyimpan
- Item yang sudah ada di Planner tidak di-overwrite jika generate ulang

### 5.5 Acceptance Criteria

21. Generate 30 hari selesai dalam < 30 detik
22. Tidak ada duplikasi topik dalam 1 minggu yang sama
23. Hari besar terdeteksi otomatis (sistem memiliki database hari besar Indonesia)
24. Semua jadwal tersimpan ke Planner dalam 1 klik
25. Bisa generate ulang sebagian (misal hanya minggu ke-3)

---

## FITUR 6 — BALASAN DM & KOMENTAR AI

### 🎯 Overview

User paste/ketik isi DM atau komentar yang masuk → AI suggest 2-3 balasan yang profesional sesuai brand tone. Mendukung berbagai skenario: pertanyaan harga, komplain, permintaan custom, tawaran endorse palsu.

### 6.1 User Story

- Sebagai pelaku UMKM, saya ingin template balasan cepat untuk pertanyaan yang sering ditanya
- Sebagai pelaku UMKM, saya ingin tahu cara merespons komplain dengan profesional
- Sebagai pelaku UMKM, saya ingin filter balasan endorse/spam dengan cerdas

### 6.2 Spesifikasi Fungsional

**Alur Penggunaan**

26. User pilih platform: Instagram DM / Komentar / WhatsApp / TikTok Komentar
27. User ketik atau paste isi pesan yang diterima
28. AI deteksi jenis pesan (pertanyaan harga, komplain, order, spam, endorse, dll)
29. AI generate 2-3 variasi balasan sesuai jenis pesan dan tone brand
30. User pilih variasi yang disukai → copy ke clipboard

**Kategori Pesan yang Didukung**

| Kategori            | Contoh Pesan                  | Pendekatan AI                                      |
|---------------------|-------------------------------|----------------------------------------------------|
| Pertanyaan Harga    | 'Kak harga berapa ya?'        | Ramah + CTA ke WA/DM untuk detail                  |
| Pertanyaan Ketersediaan | 'Masih ada stok?'          | Konfirmasi + opsi pre-order jika habis             |
| Komplain Produk     | 'Pesanan saya rusak kak'      | Empati + minta foto + tawarkan solusi              |
| Request Custom      | 'Bisa custom warna?'          | Klarifikasi + estimasi waktu + harga               |
| Pujian/Testimoni    | 'Enak banget kakk!!'          | Ucapan terima kasih + ajak tag/review              |
| Spam Endorse        | 'Halo min mau kerjasama...'   | Respons standar atau abaikan guide                 |
| Tawaran COD         | 'Bisa COD ga?'                | Sesuai kebijakan usaha yang diatur di profil       |

### 6.3 Prompt AI

```
System: Kamu adalah asisten komunikasi untuk toko {nama_toko}, 
sebuah usaha {jenis_usaha} dengan tone brand {tone_brand}.
Buat balasan yang: singkat (max 3 kalimat), sesuai tone, tidak copy-paste terasa,
dan selalu ada call-to-action yang relevan.

User: Platform: {platform}
Pesan masuk: "{isi_pesan}"
Konteks: {konteks_tambahan}

Deteksi kategori pesan, lalu buat 2 variasi balasan.
Output JSON: {
  "kategori": "...",
  "balasan": ["...", "..."],
  "tips": "satu tips singkat untuk situasi ini"
}
```

### 6.4 Acceptance Criteria

31. Deteksi kategori pesan akurat minimal 85% untuk 5 kategori utama
32. Balasan tidak mengandung informasi palsu tentang produk
33. Tone konsisten dengan pengaturan brand di profil usaha
34. Ada opsi 'Simpan sebagai template' untuk balasan yang sering dipakai

---

## FITUR 7 — LOGO MAKER AI

### 🎯 Overview

User input nama brand + deskripsi usaha + preferensi gaya → Stability AI generate 4 variasi logo → user pilih dan download PNG dengan background transparan.

### 7.1 User Story

- Sebagai pelaku UMKM yang baru mulai, saya ingin logo yang terlihat profesional tanpa bayar desainer
- Sebagai pelaku UMKM, saya ingin logo yang mencerminkan identitas usaha saya

### 7.2 Spesifikasi Fungsional

**Input Form**

| Field            | Tipe          | Keterangan                                      |
|------------------|---------------|-------------------------------------------------|
| Nama Brand       | Text          | Teks yang akan muncul di logo (wajib)           |
| Jenis Usaha      | Dropdown      | Untuk konteks visual yang relevan               |
| Gaya Logo        | Single-select | Minimalis Modern / Vintage Klasik / Playful Colorful / Bold & Tegas / Elegant Mewah |
| Warna Utama      | Color picker  | Pilih 1-2 warna utama brand                     |
| Elemen Visual    | Multi-select (opsional) | Icon makanan / Daun/Alam / Bintang / Abstrak / Tidak perlu icon |
| Background       | Toggle        | Transparan / Putih / Warna brand                |

**Prompt Engineering untuk Stability AI**

```text
"{gaya_style} logo design for a business called '{nama_brand}', 
{jenis_usaha} industry, {warna_utama} color scheme, 
featuring {elemen_visual}, clean professional design, 
vector style, white background, high quality, 
suitable for small business Indonesia"
```

**Negative prompt:**

```
"blurry, low quality, watermark, text errors, 
distorted letters, complex background, photorealistic"
```

**Backend Flow**

35. Terima request → bangun prompt dari input user
36. Kirim ke Stability AI dengan parameter: `width=512`, `height=512`, `samples=4`, `steps=30`
37. Simpan 4 hasil gambar ke Firebase Storage
38. Return URL 4 gambar ke Flutter
39. User pilih 1 → opsi download PNG 512x512 atau 1024x1024

### 7.3 Limitations & Komunikasi ke User

> ⚠️ **Batasan Logo AI yang Harus Dikomunikasikan ke User**  
> Logo AI mungkin tidak sempurna dalam merender teks — kadang ada huruf yang salah atau aneh. Ini adalah keterbatasan teknologi generasi gambar saat ini. Saran: pilih logo yang paling baik, lalu bisa diedit lebih lanjut di Canva jika perlu. Tampilkan disclaimer ini di UI sebelum user generate.

### 7.4 Acceptance Criteria

40. Generate 4 variasi dalam < 20 detik
41. Disclaimer keterbatasan AI tampil jelas sebelum generate
42. Download PNG tersedia dalam 2 ukuran: 512x512 dan 1024x1024
43. Hasil tersimpan di history untuk diakses kembali
44. Logo Maker menggunakan kuota image generation yang sama dengan AI Image lainnya

---

## FITUR 8 — NAMA PRODUK & TAGLINE AI

### 🎯 Overview

AI generate nama produk yang catchy, mudah diingat, dan relevan + tagline yang memorable untuk brand atau produk baru UMKM.

### 8.1 Spesifikasi Fungsional

**Input**

| Field             | Keterangan                                      |
|-------------------|-------------------------------------------------|
| Deskripsi Produk  | Apa produknya, bahan utama, keunggulan (max 200 karakter) |
| Target Audiens    | Siapa pembelinya: ibu rumah tangga / anak muda / profesional / dll |
| Tone/Karakter Nama| Elegan & Premium / Lucu & Playful / Simple & Modern / Lokal & Hangat |
| Bahasa            | Indonesia / Inggris / Mix (Bahasa Indonesia dengan sedikit Inggris) |
| Hindari Kata      | Kata atau konsep yang tidak ingin ada di nama (opsional) |

**Output**

- 10 opsi nama produk dengan penjelasan singkat arti/alasan setiap nama
- 3 opsi tagline brand yang pendek dan memorable (max 7 kata)
- Skor 'Kemudahan Diingat' dan 'Keunikan' untuk setiap nama (skala 1-5)
- Warning jika nama mirip dengan brand terkenal yang sudah ada

**Prompt AI**

```
System: Kamu adalah brand naming specialist untuk produk UMKM Indonesia.
User: 
- Produk: {deskripsi_produk}
- Target: {target_audiens}  
- Tone: {tone}
- Bahasa: {bahasa}
- Hindari: {kata_dihindari}

Buat 10 nama produk unik dengan format JSON:
[{
  "nama": "...",
  "alasan": "...",
  "skor_ingat": 4,
  "skor_unik": 5
}]
Dan 3 tagline: ["...", "...", "..."]
```

### 8.2 Acceptance Criteria

45. Generate minimum 10 nama yang berbeda karakter
46. Tidak ada nama yang sama persis dengan brand FMCG terkenal di Indonesia
47. Skor ditampilkan dalam format visual (bintang atau bar)
48. Semua nama bisa disimpan ke favorit
49. Ada tombol 'Gunakan nama ini' yang auto-isi ke profil usaha

---

## FITUR 9 — WA BLAST TEMPLATE GENERATOR

### 🎯 Overview

Generate pesan broadcast WhatsApp untuk promosi, info stok baru, flash sale, dan pengumuman lainnya. Pesan dirancang terasa personal dan tidak seperti spam massal.

### 9.1 Spesifikasi Fungsional

**Tipe Pesan yang Didukung**

| Tipe                    | Use Case                                              |
|-------------------------|-------------------------------------------------------|
| Promo Flash Sale        | Diskon X% untuk produk tertentu, berlaku Y jam        |
| Produk Baru             | Announcement peluncuran produk/menu baru              |
| Info Stok               | Stok hampir habis / restock tersedia                  |
| Pengingat Order         | Reminder untuk pelanggan yang belum checkout          |
| Ucapan Hari Besar       | Lebaran, Tahun Baru, Hari Ibu, dll                    |
| Follow-up Pelanggan Lama| Re-engage pelanggan yang sudah lama tidak beli        |
| Invitation Event        | Undangan ke bazaar, open house, atau promo offline    |

**Input**

- Tipe pesan (dropdown dari tabel di atas)
- Detail promo: nama produk, harga, diskon, batas waktu
- CTA yang diinginkan: klik link / hubungi WA / kunjungi toko
- Tone: Formal / Santai / Sedikit Humor

**Output**

- 2 versi pesan: versi panjang (200-250 kata) dan versi pendek (max 100 kata)
- Versi dengan emoji dan tanpa emoji
- Placeholder yang jelas untuk personalisasi nama pelanggan: `[Nama Kak]`

**Prompt AI**

```
System: Buat pesan broadcast WhatsApp untuk UMKM yang terasa personal, 
tidak spam, dan memiliki CTA yang jelas. 
Gunakan bahasa Indonesia yang {tone}, max {max_kata} kata.
Sertakan emoji yang relevan tapi tidak berlebihan.

User: Tipe: {tipe_pesan}
Detail: {detail_promo}
CTA: {cta}
Nama toko: {nama_brand}
```

### 9.2 Acceptance Criteria

50. Generate 2 variasi panjang berbeda
51. Placeholder `[Nama Kak]` selalu ada untuk personalisasi
52. Copy button langsung tersedia
53. Preview tampilan pesan di mock WA chat bubble

---

## FITUR 10 — ANALISIS FOTO PRODUK AI

### 🎯 Overview

User upload foto produk → Gemini Vision menganalisis kualitas foto (pencahayaan, komposisi, background, styling) → memberikan skor per aspek + saran perbaikan yang spesifik dan actionable.

### 10.1 User Story

- Sebagai pelaku UMKM, saya ingin tahu kenapa foto produk saya kurang menarik
- Sebagai pelaku UMKM, saya ingin saran perbaikan foto yang bisa saya lakukan sendiri tanpa alat mahal

### 10.2 Spesifikasi Fungsional

**Input**

- Upload foto produk (JPG/PNG, max 5MB)
- Kategori produk (untuk konteks analisis yang relevan)
- Platform target: Instagram Feed / TikTok / Shopee/Tokped Thumbnail

**Output — Scorecard Foto**

| Aspek Penilaian | Kriteria                                      | Skor |
|-----------------|-----------------------------------------------|------|
| Pencahayaan     | Merata, tidak over/under exposed, warna natural | 1-10 |
| Komposisi       | Rule of thirds, framing, negative space       | 1-10 |
| Background      | Bersih, tidak distraksi, sesuai produk        | 1-10 |
| Ketajaman       | Fokus tajam pada produk utama                 | 1-10 |
| Styling         | Properti pendukung, warna, estetika keseluruhan | 1-10 |
| Platform-fit    | Sesuai rasio dan estetika platform target     | 1-10 |

**Backend — Gemini Vision API**

**Endpoint:** `POST /api/photo-analysis`

- Multipart form data: `image` (file), `kategori` (string), `platform` (string)

**Backend flow:**

1. Resize gambar ke max 1024x1024
2. Convert ke base64
3. Kirim ke Gemini Vision (`gemini-pro-vision`)
4. Parse response JSON
5. Return scorecard + saran

**Prompt ke Gemini Vision**

```
System: Kamu adalah fotografer produk profesional dengan keahlian 
e-commerce dan social media marketing Indonesia.

User: Analisis kualitas foto produk {kategori} berikut untuk platform {platform}.
Berikan penilaian dalam format JSON:
{
  "skor_keseluruhan": 7,
  "aspek": {
    "pencahayaan": {"skor": 8, "komentar": "...", "saran": "..."},
    "komposisi": {"skor": 6, "komentar": "...", "saran": "..."},
    "background": {"skor": 7, "komentar": "...", "saran": "..."},
    "ketajaman": {"skor": 9, "komentar": "...", "saran": "..."},
    "styling": {"skor": 5, "komentar": "...", "saran": "..."},
    "platform_fit": {"skor": 7, "komentar": "...", "saran": "..."}
  },
  "saran_utama": ["...", "...", "..."],
  "pujian": "...",
  "estimasi_peningkatan": "Dengan perbaikan di atas, foto ini bisa meningkat dari 7/10 ke 8.5/10"
}
```

### 10.3 Acceptance Criteria

54. Analisis selesai dalam < 15 detik
55. Skor ditampilkan dengan visual progress bar berwarna (merah/kuning/hijau)
56. Saran bersifat actionable — bukan hanya teori tapi langkah konkret
57. Bisa upload max 3 foto sekaligus untuk perbandingan
58. Hasil bisa disimpan sebagai laporan di Content Library

---

## FITUR 11 — WEBSITE KILAT (LANDING PAGE AI)

> 🚀 **Fitur Premium — Kompleksitas Tinggi**  
> Fitur ini direkomendasikan sebagai **PREMIUM FEATURE** (Pro Plan ke atas). Tidak cocok untuk free tier karena membutuhkan hosting, domain, dan infrastruktur yang signifikan. Pertimbangkan untuk dikerjakan setelah fitur 1-10 stabil.

### 11.1 Overview

AI generate landing page HTML satu halaman untuk toko UMKM. User mengisi informasi usaha → AI buat kode HTML/CSS responsif yang siap di-deploy → user dapat link unik → bisa digunakan sebagai website sederhana tanpa coding.

### 11.2 Scope Minimum

- Landing page 1 halaman (bukan multi-page website)
- Konten: Hero section, tentang usaha, produk unggulan (max 6), kontak/CTA
- Mobile-first responsive design
- Hosted di `kreasea.site/{slug}`
- Custom domain tidak termasuk (fitur enterprise)

### 11.3 Backend Requirements

| Komponen   | Kebutuhan                                      |
|------------|------------------------------------------------|
| Hosting    | Dedicated hosting atau CDN (Cloudflare Pages / Vercel) |
| Storage    | HTML files di Firebase Storage atau object storage |
| Domain     | Subdomain wildcard: `*.kreasea.site`           |
| SSL        | Otomatis via Cloudflare atau Let's Encrypt     |
| Build time | Max 30 detik dari input ke live                |
| Bandwidth  | Unlimited (tergantung provider)                |

### 11.4 Rekomendasi Implementasi

> 💡 **Saran Developer**  
> Gunakan pendekatan **template-based** (bukan AI-generated HTML penuh) untuk menghindari broken HTML. Buat 5 template HTML yang sudah bagus, lalu AI hanya mengisi konten (teks, warna, gambar) ke dalam template. Ini jauh lebih reliable dan cepat dari generate HTML dari nol.

---

## RINGKASAN — PRIORITAS DEVELOPMENT

### Urutan Pengerjaan yang Disarankan

| Prioritas     | Fitur                              | Alasan                                      | Est. Dev   | Plan    |
|---------------|------------------------------------|---------------------------------------------|------------|---------|
| P1 — Minggu 1 | Expand Menu System                 | Foundation semua fitur baru                 | 2-3 hari   | Free    |
| P1 — Minggu 1-2 | Fitur 4: Testimoni Generator     | Pure text AI, paling sederhana, impact tinggi | 2-3 hari | Free    |
| P1 — Minggu 2 | Fitur 8: Nama Produk & Tagline     | Pure text AI, sederhana                     | 2-3 hari   | Free    |
| P1 — Minggu 2-3 | Fitur 2: Optimasi GMaps          | Pure text, sangat dibutuhkan                | 3-4 hari   | Free    |
| P1 — Minggu 3 | Fitur 9: WA Blast Template         | Pure text, langsung bisa dipakai            | 2-3 hari   | Free    |
| P2 — Minggu 3-4 | Fitur 6: Balasan DM AI           | Text AI + kategori deteksi                  | 3-4 hari   | Free    |
| P2 — Minggu 4-5 | Fitur 1: Kalkulator HPP          | Logic kalkulasi + AI advice                 | 4-5 hari   | Free    |
| P2 — Minggu 5-6 | Fitur 5: AI Content Calendar     | Prompt kompleks + integrasi Planner         | 4-5 hari   | Free/Pro|
| P3 — Minggu 6-7 | Fitur 3: Bio Link Generator      | Backend hosting + tracking                  | 7-10 hari  | Pro     |
| P3 — Minggu 7-8 | Fitur 7: Logo Maker AI           | Stability AI + prompt engineering           | 4-5 hari   | Pro     |
| P3 — Minggu 8-9 | Fitur 10: Analisis Foto          | Gemini Vision + UI scorecard                | 4-5 hari   | Pro     |
| P4 — Post-launch | Fitur 11: Website Kilat         | Infrastruktur besar, riset dulu             | 2-4 minggu | Premium |

---

## 📝 Catatan untuk Developer (Muhaimin)

Semua fitur P1 menggunakan Gemini API text generation yang sudah ada di backend. Tidak perlu infrastruktur baru — cukup tambah endpoint baru dan Flutter screen baru. Mulai dari **Expand Menu System** dulu sebagai fondasi, lalu kerjakan fitur P1 secara berurutan. Fitur P2-P3 bisa dikerjakan paralel setelah core KreaSea (Caption + Image + Planner) sudah stabil.

---

**KreaSea PRD — Fitur Tambahan v1.0**  
**Jundy Alka** | **Maret 2026**