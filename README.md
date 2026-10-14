# RME Klinik Pratama Rutan Kelas IIB Tanjung Redeb (Supabase + Vercel Edition)

Aplikasi Rekam Medis Elektronik (RME) modern berbasis web untuk Klinik Rutan Kelas IIB Tanjung Redeb, terintegrasi dengan **Supabase PostgreSQL** (Realtime Multi-Cluster) dan di-hosting melalui **Vercel** / **GitHub Pages**.

> **Catatan Keamanan & Isolasi:**
> Folder ini berdiri sendiri (`standalone`) di `/home/herman/RME-Klinik-Rutan-Supabase/`. Proyek Google Apps Script di `/home/herman/RME Klinik Rutan/` tetap utuh 100% dan tidak tersentuh.

---

## 🚀 Panduan Setup Singkat (3 Langkah Mudah)

### Langkah 1: Buat Database di Supabase
1. Buka [supabase.com](https://supabase.com) dan login (bisa langsung pakai akun GitHub).
2. Klik tombol **"New Project"**, beri nama project (contoh: `rme-klinik-rutan`), buat database password, lalu pilih Region: **Singapore (ap-southeast-1)** agar akses paling cepat dari Berau/Kalimantan Timur.
3. Setelah database siap (~1 menit), buka menu **SQL Editor** (ikon terminal `>_` di sidebar kiri Supabase).
4. Klik **"New Query"**, buka file `supabase_schema.sql` di folder ini, salin seluruh isinya (Ctrl+A $\rightarrow$ Ctrl+C), tempelkan ke SQL Editor, lalu klik tombol **"Run"**.
   * Skrip ini otomatis membuat tabel `patients`, `queues`, `medical_records`, `medicines`, `stock_cards`, mengaktifkan **Supabase Realtime Sync**, dan mengisi data dasar.

### Langkah 2: Ambil API Keys Supabase
1. Di Supabase dashboard, masuk ke menu **Settings** (ikon gerigi di sidebar bawah) $\rightarrow$ **Data API**.
2. Salin 2 parameter penting:
   * **Project URL** (contoh: `https://abcdefghijkl.supabase.co`)
   * **anon / public key** (kunci panjang berawalan `eyJ...`)
3. **Cara Menghubungkan (Sangat Mudah):**
   * Buka aplikasi `index.html` di browser Anda (atau setelah deploy ke Vercel).
   * Klik tombol **"Setup Supabase"** di header atas (di samping badge SATUSEHAT).
   * Tempelkan **Project URL** dan **Anon Key**, lalu klik **"Simpan & Hubungkan"**.
   * *(Opsional)* Jika database masih baru dan kosong, Anda juga bisa klik tombol **"Muat Data Awal (Seed)"** di dalam modal tersebut untuk memasukkan pasien Linda Heriany, Budi Santoso, dan formularium obat dasar secara instan!

### Langkah 3: Upload ke GitHub & Deploy ke Vercel

#### A. Upload ke GitHub
1. Buka [github.com](https://github.com) $\rightarrow$ buat repository baru (misal: `rme-klinik-rutan`).
2. Anda dapat mengunggah file-file berikut langsung via web GitHub (klik *"uploading an existing file"*):
   * `index.html`
   * `logo_klinik.png`
   * `vercel.json`
   * `README.md`
   * `supabase_schema.sql`

#### B. Deploy ke Vercel (Otomatis & Gratis)
1. Buka [vercel.com](https://vercel.com) $\rightarrow$ login dengan akun GitHub Anda.
2. Klik **"Add New..."** $\rightarrow$ **"Project"**.
3. Pilih repository `rme-klinik-rutan` yang baru saja Anda buat di GitHub.
4. Klik tombol **"Deploy"**.
5. Dalam waktu ~20 detik, Vercel akan memberikan link domain live aktif (contoh: `https://rme-klinik-rutan.vercel.app`) dengan HTTPS SSL aktif otomatis!

---

## 📂 Struktur Berkas
* `index.html`: Antarmuka lengkap 5 Kluster RME (Pendaftaran, Triase TTV, Poli DPJP & CDSS, Depo Farmasi & Stok, Pelaporan Cetak A4) + Universal Supabase RPC Bridge.
* `supabase_schema.sql`: Skema PostgreSQL terstandar Permenkes No. 24/2022 + SATUSEHAT FHIR Ready + Realtime Channels.
* `logo_klinik.png`: Logo resmi Klinik Pratama Rutan Kelas IIB Tanjung Redeb.
* `vercel.json`: Konfigurasi perutean statis dan security headers standar perbankan/medis.
* `README.md`: Dokumentasi dan panduan setup langkah demi langkah.
