# 📂 Panduan Hierarki Kategori Produk

## 🎯 Fitur Kategori dengan Sub-Kategori

Sistem POS sekarang mendukung hierarki kategori multi-level, dimana setiap kategori bisa memiliki **parent category** (kategori induk) untuk membuat struktur yang lebih terorganisir.

---

## 🌳 Struktur Hierarki

### Contoh Struktur Kategori:

```
📁 Elektronik (Kategori Utama)
   ↳ 📱 Smartphone (Sub-kategori)
   ↳ 💻 Laptop (Sub-kategori)
   ↳ 🎧 Audio (Sub-kategori)

📁 Makanan & Minuman (Kategori Utama)
   ↳ 🍔 Makanan (Sub-kategori)
   ↳ 🥤 Minuman (Sub-kategori)
   ↳ 🍰 Dessert (Sub-kategori)

📁 Fashion (Kategori Utama)
   ↳ 👕 Pakaian Pria (Sub-kategori)
   ↳ 👗 Pakaian Wanita (Sub-kategori)
   ↳ 👟 Sepatu (Sub-kategori)
```

---

## 🛠️ Cara Menggunakan

### 1. **Membuat Kategori Utama**

Di halaman **Kelola Kategori**:
- Isi **Nama Kategori** (contoh: "Elektronik")
- Isi **Deskripsi** (opsional)
- Pada **Kategori Induk**, pilih **"-- Kategori Utama --"**
- Klik **Tambah Kategori**

✅ Kategori utama akan muncul dengan ikon **folder** (📁)

### 2. **Membuat Sub-Kategori**

Di halaman **Kelola Kategori**:
- Isi **Nama Kategori** (contoh: "Smartphone")
- Isi **Deskripsi** (opsional)
- Pada **Kategori Induk**, pilih kategori yang sudah ada (contoh: "Elektronik")
- Klik **Tambah Kategori**

✅ Sub-kategori akan muncul dengan indentasi dan ikon **↳**

---

## 📱 Tampilan UI

### **Halaman Kelola Kategori**

#### Form Tambah Kategori:
```
┌─────────────────────────────────────┐
│ 📝 Tambah Kategori Baru             │
├─────────────────────────────────────┤
│ Nama Kategori *                     │
│ [___________________________]       │
│                                     │
│ Deskripsi (opsional)                │
│ [___________________________]       │
│                                     │
│ Kategori Induk (opsional)          │
│ [-- Kategori Utama -- ▼]           │
│   ↳ Elektronik                      │
│   ↳ Makanan & Minuman              │
│                                     │
│ [ ➕ Tambah Kategori ]              │
└─────────────────────────────────────┘
```

#### Daftar Kategori (Tree View):
```
┌─────────────────────────────────────┐
│ Daftar Kategori            6 kategori│
├─────────────────────────────────────┤
│ ▼ 📁 Elektronik        [3 sub] 🗑️  │
│    ↳ 📱 Smartphone            🗑️   │
│    ↳ 💻 Laptop                🗑️   │
│    ↳ 🎧 Audio                 🗑️   │
│                                     │
│ ▶ 📁 Makanan & Minuman [2 sub] 🗑️  │
│                                     │
│ 📁 Furniture                    🗑️  │
└─────────────────────────────────────┘
```

**Fitur Tampilan:**
- **▶/▼** = Expand/Collapse untuk melihat sub-kategori
- **[X sub]** = Badge menunjukkan jumlah sub-kategori
- **🗑️** = Tombol hapus kategori
- **Indentasi** = Visual hierarki kategori

---

## 🎯 Pemilihan Kategori di Form Produk

Saat membuat/edit produk, dropdown kategori akan menampilkan hierarki:

```
┌─────────────────────────────────────┐
│ Kategori                    [✏️]    │
│ [Pilih kategori ▼]                 │
│                                     │
│  Elektronik                         │
│     ↳ Smartphone ← dengan indentasi│
│     ↳ Laptop                        │
│     ↳ Audio                         │
│  Makanan & Minuman                  │
│     ↳ Makanan                       │
│     ↳ Minuman                       │
│  Furniture                          │
└─────────────────────────────────────┘
```

**Keterangan:**
- Kategori utama tampil **normal**
- Sub-kategori tampil dengan **indentasi** (↳)
- Tombol **✏️** untuk membuka halaman Kelola Kategori

---

## 🔒 Aturan & Validasi

### 1. **Tidak Bisa Hapus Kategori yang Memiliki Sub-Kategori**
❌ Jika kategori "Elektronik" memiliki 3 sub-kategori, tidak bisa dihapus
✅ Harus hapus semua sub-kategori dulu, baru bisa hapus kategori induk

### 2. **Tidak Bisa Hapus Kategori yang Digunakan Produk**
❌ Jika ada produk menggunakan kategori "Smartphone", kategori tidak bisa dihapus
💡 Error message: "Cannot delete category. It is used by X product(s)"

### 3. **Kategori Induk Bersifat Opsional**
✅ Bisa membuat kategori tanpa parent (kategori utama)
✅ Bisa membuat sub-kategori dengan memilih parent

---

## 🗄️ Database Schema

### Tabel `categories`:
```sql
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  parent_id INTEGER REFERENCES categories(id), -- Hierarki!
  icon VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP NULL -- Soft delete
);
```

**Field Penting:**
- `parent_id` = NULL untuk kategori utama
- `parent_id` = ID kategori lain untuk sub-kategori

---

## 🔌 API Endpoints

### Backend Support:

#### 1. GET `/api/v2/categories`
Response dengan parent info:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Elektronik",
      "description": "Kategori elektronik",
      "parentId": null,
      "isActive": true
    },
    {
      "id": 2,
      "name": "Smartphone",
      "description": "Produk smartphone",
      "parentId": 1,  // ← Sub-kategori dari Elektronik
      "isActive": true
    }
  ]
}
```

#### 2. POST `/api/v2/categories`
Request body:
```json
{
  "name": "Smartphone",
  "description": "Produk smartphone",
  "parent_id": 1,  // ← ID kategori Elektronik
  "is_active": true
}
```

---

## ✨ Keuntungan Hierarki Kategori

### 1. **Organisasi Lebih Baik**
- Produk terkelompok dengan rapi
- Mudah navigasi dan pencarian
- Struktur logis dan intuitif

### 2. **Fleksibilitas**
- Bisa tambah level baru kapan saja
- Mudah reorganisasi kategori
- Support kategori unlimited

### 3. **User Experience**
- Visual tree view yang jelas
- Expand/collapse untuk navigasi cepat
- Indentasi memudahkan pemahaman

### 4. **Reporting & Analytics**
- Laporan per kategori utama
- Detail per sub-kategori
- Agregasi data hierarkis

---

## 📊 Best Practices

### ✅ DO (Direkomendasikan):

1. **Gunakan Nama yang Jelas**
   - ✅ "Elektronik" > "Smartphone" > "Android"
   - ❌ "Kat1" > "Kat1.1" > "Kat1.1.1"

2. **Maksimal 2-3 Level**
   - ✅ Kategori > Sub-kategori
   - ⚠️ Kategori > Sub > Sub-sub (sudah cukup dalam)

3. **Konsisten dalam Penamaan**
   - ✅ "Pakaian Pria", "Pakaian Wanita", "Pakaian Anak"
   - ❌ "Pria", "Clothes for Women", "anak2"

### ❌ DON'T (Hindari):

1. **Terlalu Banyak Level**
   - ❌ Level > 3 susah di-maintain
   
2. **Kategori Terlalu Spesifik**
   - ❌ "Smartphone Samsung Galaxy S Series Warna Hitam"
   - ✅ "Smartphone" saja, detail di produk

3. **Duplikasi Nama**
   - ❌ Punya 2 kategori "Elektronik" berbeda
   - ✅ Nama unik untuk setiap kategori

---

## 🎨 Implementasi Frontend

### File yang Diupdate:

1. **`category_list_page.dart`**
   - Form dengan dropdown parent category
   - Tree view dengan expand/collapse
   - Badge jumlah sub-kategori
   - Validasi hapus kategori

2. **`product_form_page.dart`**
   - Dropdown hierarkis dengan indentasi
   - Parsing parent info dari API
   - Display name dengan visual ↳

---

## 🚀 Migration Guide

Jika sudah punya kategori existing tanpa parent:

1. **Semua kategori otomatis jadi kategori utama** (parent_id = null)
2. **Edit kategori** untuk set parent jika perlu
3. **Reorganisasi** sesuai kebutuhan bisnis

---

## 📞 Tips Penggunaan

### Untuk Toko Retail:
```
📁 Makanan
   ↳ Snack
   ↳ Mie Instan
   ↳ Bumbu Dapur
📁 Minuman
   ↳ Minuman Ringan
   ↳ Air Mineral
   ↳ Kopi & Teh
```

### Untuk Toko Elektronik:
```
📁 Komputer & Aksesoris
   ↳ Laptop
   ↳ Desktop PC
   ↳ Monitor
   ↳ Keyboard & Mouse
📁 Audio & Video
   ↳ Headphone
   ↳ Speaker
   ↳ Webcam
```

### Untuk Toko Fashion:
```
📁 Pakaian
   ↳ Kaos
   ↳ Kemeja
   ↳ Celana
📁 Aksesoris
   ↳ Tas
   ↳ Topi
   ↳ Ikat Pinggang
```

---

## 🎯 Summary

✅ **Kategori dengan hierarki parent-child**
✅ **Tree view dengan expand/collapse**
✅ **Indentasi visual di dropdown**
✅ **Validasi hapus kategori**
✅ **Support unlimited sub-kategori**
✅ **Backend & Frontend terintegrasi**

**Happy organizing! 🎉**
