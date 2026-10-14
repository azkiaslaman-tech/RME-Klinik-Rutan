-- ==================================================================================
-- SKEMA DATABASE RME KLINIK PRATAMA RUTAN KELAS IIB TANJUNG REDEB (SUPABASE / POSTGRESQL)
-- Standard: Permenkes No. 24 Tahun 2022, SATUSEHAT FHIR Ready, Realtime Multi-Cluster
-- ==================================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABEL: PATIENTS (Data Induk Warga Binaan Pemasyarakatan & Pasien)
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    no_rm VARCHAR(50) UNIQUE NOT NULL,
    no_rm_lama VARCHAR(50),
    nik VARCHAR(20),
    full_name VARCHAR(150) NOT NULL,
    dob DATE,
    gender VARCHAR(20) DEFAULT 'Laki-laki',
    blood_type VARCHAR(5),
    block_room VARCHAR(100) DEFAULT 'Blok Hunian',
    religion VARCHAR(50),
    citizenship VARCHAR(50) DEFAULT 'WNI',
    marital_status VARCHAR(50),
    bpjs_number VARCHAR(50),
    faskes_origin VARCHAR(100),
    phone VARCHAR(30) DEFAULT '0000000000',
    address TEXT,
    allergies TEXT DEFAULT 'Tidak Ada',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patients_rm ON patients(no_rm);
CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(full_name);
CREATE INDEX IF NOT EXISTS idx_patients_nik ON patients(nik);

-- 3. TABEL: QUEUES / ENCOUNTERS (Sistem Antrean Realtime Multi-Kluster)
CREATE TABLE IF NOT EXISTS queues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    queue_no VARCHAR(20) NOT NULL,
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    patient_no_rm VARCHAR(50) NOT NULL,
    patient_name VARCHAR(150) NOT NULL,
    patient_age INTEGER DEFAULT 30,
    patient_gender VARCHAR(20) DEFAULT 'Laki-laki',
    block_room VARCHAR(100) DEFAULT 'Blok Hunian',
    current_cluster VARCHAR(20) DEFAULT 'k1', -- 'k1', 'k2', 'k3', 'k4', 'completed'
    triage VARCHAR(20) DEFAULT 'HIJAU',       -- 'HIJAU', 'KUNING', 'MERAH'
    is_cito BOOLEAN DEFAULT FALSE,
    status VARCHAR(30) DEFAULT 'waiting',     -- 'waiting', 'in_progress', 'completed', 'cancelled'
    complaint TEXT,
    rpd TEXT,
    handover_notes TEXT,
    allergies TEXT DEFAULT 'Tidak Ada',
    vitals JSONB DEFAULT '{"sys": 120, "dia": 80, "hr": 80, "rr": 20, "temp": 36.5, "spo2": 98, "tb": 170, "bb": 65, "bmi": 22.5, "gcs": 15}'::jsonb,
    poct_list JSONB DEFAULT '[]'::jsonb,
    soap JSONB DEFAULT '{"s": "", "o": "", "a": "", "p": ""}'::jsonb,
    icd10 JSONB DEFAULT '{"code": "", "name": "", "secCode": "", "secName": ""}'::jsonb,
    prescriptions JSONB DEFAULT '[]'::jsonb,
    dispense_status VARCHAR(30) DEFAULT 'pending', -- 'pending', 'review', 'confirm', 'process', 'ready', 'dispensed'
    encounter_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_queues_cluster ON queues(current_cluster);
CREATE INDEX IF NOT EXISTS idx_queues_status ON queues(status);
CREATE INDEX IF NOT EXISTS idx_queues_date ON queues(encounter_date);

-- 4. TABEL: MEDICAL_RECORDS (Rekam Medis Longitudinal Lengkap 49 Parameter - Cetak A4)
CREATE TABLE IF NOT EXISTS medical_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    record_no VARCHAR(60) UNIQUE NOT NULL,
    patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,
    no_rm VARCHAR(50) NOT NULL,
    nama_pasien VARCHAR(150) NOT NULL,
    nik VARCHAR(20),
    tanggal DATE DEFAULT CURRENT_DATE,
    jam TIME DEFAULT CURRENT_TIME,
    keluhan_utama TEXT,
    keluhan_tambahan TEXT,
    lama_sakit VARCHAR(50),
    merokok VARCHAR(20),
    alkohol VARCHAR(20),
    kurang_sayur_buah VARCHAR(20),
    edukasi TEXT,
    terapi_anjuran TEXT,
    terapi_non_obat TEXT,
    bmhp TEXT,
    rencana_tindakan TEXT,
    observasi TEXT,
    biopsikososial TEXT,
    keterangan TEXT,
    alergi_obat TEXT,
    alergi_makanan TEXT,
    alergi_udara TEXT,
    alergi_umum TEXT,
    kesadaran VARCHAR(50) DEFAULT 'Compos Mentis',
    sistole INTEGER,
    diastole INTEGER,
    tinggi_badan NUMERIC(5,2),
    berat_badan NUMERIC(5,2),
    lingkar_perut NUMERIC(5,2),
    detak_nadi INTEGER,
    nafas INTEGER,
    spo2 INTEGER,
    suhu NUMERIC(4,1),
    aktifitas_fisik VARCHAR(50),
    detak_jantung VARCHAR(50),
    triage VARCHAR(20),
    skala_nyeri INTEGER DEFAULT 0,
    lab_pemeriksaan TEXT,
    diagnosa TEXT,
    diagnosa_kode VARCHAR(20),
    diagnosa_sekunder TEXT,
    diagnosa_sekunder_kode VARCHAR(20),
    tindakan TEXT,
    resep_obat TEXT,
    poli_ruangan VARCHAR(100) DEFAULT 'Poli Umum Rutan',
    kamar VARCHAR(50),
    rujuk_internal VARCHAR(100),
    rujuk_eksternal VARCHAR(150),
    ttd_dokter VARCHAR(100) DEFAULT 'dr. MATIUS M. POPANG',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mr_norm ON medical_records(no_rm);
CREATE INDEX IF NOT EXISTS idx_mr_tanggal ON medical_records(tanggal);

-- 5. TABEL: MEDICINES (Master Formularium Obat Rutan)
CREATE TABLE IF NOT EXISTS medicines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    form VARCHAR(50),           -- Tablet, Sirup, Injeksi, Salep, dll
    unit VARCHAR(50),           -- Tablet, Strip, Botol, Ampul, Tube
    category VARCHAR(100),       -- Antihipertensi, Analgesik, Antibiotik, dll
    stock INTEGER DEFAULT 0,
    min_stock INTEGER DEFAULT 10,
    batch_no VARCHAR(50),
    expired_date DATE,
    location VARCHAR(50) DEFAULT 'Depo Farmasi',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_meds_code ON medicines(code);
CREATE INDEX IF NOT EXISTS idx_meds_name ON medicines(name);

-- 6. TABEL: STOCK_CARDS (Kartu Stok & Mutasi FIFO/FEFO Farmasi)
CREATE TABLE IF NOT EXISTS stock_cards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medicine_id UUID REFERENCES medicines(id) ON DELETE CASCADE,
    medicine_name VARCHAR(150) NOT NULL,
    date DATE DEFAULT CURRENT_DATE,
    type VARCHAR(20) NOT NULL, -- 'MASUK', 'KELUAR', 'PENYESUAIAN'
    document_ref VARCHAR(100), -- No Resep / No BAST / Stok Opname
    qty_in INTEGER DEFAULT 0,
    qty_out INTEGER DEFAULT 0,
    balance INTEGER NOT NULL,
    batch_no VARCHAR(50),
    notes TEXT,
    officer VARCHAR(100) DEFAULT 'Petugas Farmasi',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_med_id ON stock_cards(medicine_id);
CREATE INDEX IF NOT EXISTS idx_stock_date ON stock_cards(date);

-- 7. ENABLE SUPABASE REALTIME REPLICATION (Untuk Sinkronisasi Antrean Live Antar Ruangan)
ALTER PUBLICATION supabase_realtime ADD TABLE queues;

-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- Catatan: Untuk kemudahan tahap awal pengembangan, kita buka akses publik / anon.
-- Pada tahap produksi, dapat diperketat dengan Supabase Auth JWT.
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE queues ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE medicines ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read-write on patients" ON patients FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write on queues" ON queues FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write on medical_records" ON medical_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write on medicines" ON medicines FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public read-write on stock_cards" ON stock_cards FOR ALL USING (true) WITH CHECK (true);

-- 9. DATA SEED AWAL (Contoh Pasien & Obat Standar Klinik Rutan)
INSERT INTO patients (no_rm, nik, full_name, dob, gender, block_room, bpjs_number, allergies, address)
VALUES 
('RM-2026-000125', '6403011203840001', 'MAKMUR BIN MANAN (ALM)', '1984-03-12', 'Laki-laki', 'TP Umum LT 1/A4 PESANTREN', '0001234567890', 'Tidak Ada', 'Kamar A4 Rutan Tanjung Redeb'),
('01561604', '6403015501920002', 'LINDA HERIANY BINTI JAMAL', '1992-01-22', 'Perempuan', 'Blok Wanita W-01', '0009876543210', 'Tidak Ada', 'Jln. Pulau Sambit RT. 04 RW. 05 Kel. Tanjung Redeb')
ON CONFLICT (no_rm) DO NOTHING;

INSERT INTO medicines (code, name, form, unit, category, stock, min_stock, batch_no, expired_date)
VALUES 
('OBT-001', 'Amlodipine 10 mg', 'Tablet', 'Tablet', 'Antihipertensi', 250, 30, 'BCH-AML-2026', '2027-12-31'),
('OBT-002', 'Amlodipine 5 mg', 'Tablet', 'Tablet', 'Antihipertensi', 300, 30, 'BCH-AML5-2026', '2027-12-31'),
('OBT-003', 'Paracetamol 500 mg', 'Tablet', 'Tablet', 'Analgesik & Antipiretik', 500, 50, 'BCH-PCT-2026', '2028-06-30'),
('OBT-004', 'Metformin 500 mg', 'Tablet', 'Tablet', 'Antidiabetes Oral', 200, 20, 'BCH-MET-2026', '2027-10-31'),
('OBT-005', 'Antasida DOEN', 'Tablet Kunyah', 'Tablet', 'Antasida / Lambung', 400, 40, 'BCH-ATD-2026', '2027-08-31'),
('OBT-006', 'Omeprazole 20 mg', 'Kapsul', 'Kapsul', 'PPI Lambung', 180, 20, 'BCH-OMP-2026', '2027-05-31'),
('OBT-007', 'Cetirizine 10 mg', 'Tablet', 'Tablet', 'Antihistamin / Alergi', 220, 20, 'BCH-CTZ-2026', '2027-11-30'),
('OBT-008', 'Cefadroxil 500 mg', 'Kapsul', 'Kapsul', 'Antibiotik Sefalosporin', 150, 20, 'BCH-CFD-2026', '2027-04-30'),
('OBT-009', 'Vitamin B Kompleks', 'Tablet', 'Tablet', 'Vitamin & Suplemen', 600, 50, 'BCH-VBK-2026', '2028-01-31'),
('OBT-010', 'Permetrin Krim 5%', 'Krim', 'Tube', 'Antiskabies Kulit', 45, 10, 'BCH-SCB-2026', '2027-03-31')
ON CONFLICT (code) DO NOTHING;
