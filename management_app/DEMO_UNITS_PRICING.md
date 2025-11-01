# Quick Demo: Units & Pricing Management

## 🎬 Demo Scenario

### Product: "Aqua Mineral Water 600ml"

---

## Step 1: Create Product - Basic Info

```
┌─────────────────────────────────────────────┐
│  Tambah Produk                              │
│  [Informasi] [Units] [Pricing]              │
├─────────────────────────────────────────────┤
│                                             │
│  Barcode: █████████████████                │
│  Nama: Aqua Mineral Water 600ml            │
│  Kategori: Minuman                          │
│  Deskripsi: Air mineral kemasan             │
│                                             │
│  Harga Beli: Rp 3,000                       │
│  Harga Jual: Rp 5,000                       │
│  Margin: 66.7%                              │
│                                             │
│  Stock: 100 PCS                             │
│  Min Stock: 20                              │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Step 2: Setup Units

Click tab **[Units]**

### 2.1: Default Base Unit (Auto-created)
```
┌─────────────────────────────────────────────┐
│  🔲 Unit Konversi      [Tambah Unit]        │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐│
│  │ [UNIT DASAR]               #1     🗑️   ││
│  ├─────────────────────────────────────────┤│
│  │ Nama Unit: PCS                          ││
│  │ Nilai Konversi: 1 (auto)                ││
│  │ Barcode: _____                          ││
│  │ ✅ Dapat Dijual  ✅ Dapat Dibeli       ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

### 2.2: Add PAK Unit
Click **[Tambah Unit]**
```
┌─────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────┐│
│  │ Set sebagai dasar          #2     🗑️   ││
│  ├─────────────────────────────────────────┤│
│  │ Nama Unit: PAK                          ││
│  │ Nilai Konversi: 6                       ││
│  │   💡 1 PAK = 6 unit dasar               ││
│  │ Barcode: PAK-AQUA-600                   ││
│  │ ✅ Dapat Dijual  ✅ Dapat Dibeli       ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

### 2.3: Add DUS Unit
Click **[Tambah Unit]**
```
┌─────────────────────────────────────────────┐
│  ┌─────────────────────────────────────────┐│
│  │ Set sebagai dasar          #3     🗑️   ││
│  ├─────────────────────────────────────────┤│
│  │ Nama Unit: DUS                          ││
│  │ Nilai Konversi: 48                      ││
│  │   💡 1 DUS = 48 unit dasar              ││
│  │ Barcode: DUS-AQUA-600                   ││
│  │ ❌ Dapat Dijual  ✅ Dapat Dibeli       ││
│  │   (DUS hanya untuk pembelian)           ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

**Result:** 3 Units configured ✅

---

## Step 3: Setup Pricing

Click tab **[Pricing]**

### 3.1: Bulk Add Prices
Click **[Tambah Bulk]**

Dialog appears:
```
┌─────────────────────────────────────────────┐
│  Tambah Harga Bulk                          │
├─────────────────────────────────────────────┤
│  Pilih Cabang:                              │
│  ✅ Cabang Pusat                            │
│  ✅ Cabang Tangerang                        │
│  ❌ Cabang Bekasi                           │
│                                             │
│  ─────────────────────────────────────      │
│                                             │
│  Pilih Unit:                                │
│  ✅ PCS                                     │
│  ✅ PAK                                     │
│  ❌ DUS                                     │
│                                             │
│          [Batal]  [Tambahkan]               │
└─────────────────────────────────────────────┘
```

Result: **4 price entries** created
- Pusat × PCS
- Pusat × PAK
- Tangerang × PCS
- Tangerang × PAK

### 3.2: Fill Prices

#### Price Entry 1: Pusat - PCS
```
┌─────────────────────────────────────────────┐
│  🏪 Cabang Pusat   [PCS]             🗑️    │
├─────────────────────────────────────────────┤
│  Harga Beli: Rp 3000   Harga Jual: Rp 5000  │
│  Grosir: Rp 4500       Member: Rp 4700      │
│                                             │
│  ┌─────────────┐                            │
│  │ Margin      │  ✅ Aktif                  │
│  │ 66.7%       │                            │
│  └─────────────┘                            │
└─────────────────────────────────────────────┘
```

#### Price Entry 2: Pusat - PAK
```
┌─────────────────────────────────────────────┐
│  🏪 Cabang Pusat   [PAK]             🗑️    │
├─────────────────────────────────────────────┤
│  Harga Beli: Rp 17000  Harga Jual: Rp 28000 │
│  Grosir: Rp 26000      Member: Rp 27000     │
│                                             │
│  ┌─────────────┐                            │
│  │ Margin      │  ✅ Aktif                  │
│  │ 64.7%       │                            │
│  └─────────────┘                            │
└─────────────────────────────────────────────┘
```

#### Price Entry 3: Tangerang - PCS
```
┌─────────────────────────────────────────────┐
│  🏪 Cabang Tangerang   [PCS]         🗑️    │
├─────────────────────────────────────────────┤
│  Harga Beli: Rp 3200   Harga Jual: Rp 5500  │
│  Grosir: Rp 5000       Member: Rp 5200      │
│                                             │
│  ┌─────────────┐                            │
│  │ Margin      │  ✅ Aktif                  │
│  │ 71.9%       │                            │
│  └─────────────┘                            │
└─────────────────────────────────────────────┘
```

#### Price Entry 4: Tangerang - PAK
```
┌─────────────────────────────────────────────┐
│  🏪 Cabang Tangerang   [PAK]         🗑️    │
├─────────────────────────────────────────────┤
│  Harga Beli: Rp 18500  Harga Jual: Rp 31000 │
│  Grosir: Rp 29000      Member: Rp 30000     │
│                                             │
│  ┌─────────────┐                            │
│  │ Margin      │  ✅ Aktif                  │
│  │ 67.6%       │                            │
│  └─────────────┘                            │
└─────────────────────────────────────────────┘
```

**Result:** 4 Prices configured ✅

---

## Step 4: Save Product

Bottom bar shows:
```
┌─────────────────────────────────────────────┐
│  Units: 3                                   │
│  Prices: 4                                  │
│                                             │
│              [Batal]  [Simpan]              │
└─────────────────────────────────────────────┘
```

Click **[Simpan]**

Loading...
```
┌─────────────────────────────────────────────┐
│  ⏳ Menyimpan produk...                     │
│     • Saving basic info                     │
│     • Saving 3 units                        │
│     • Saving 4 prices                       │
└─────────────────────────────────────────────┘
```

Success!
```
┌─────────────────────────────────────────────┐
│  ✅ Produk berhasil disimpan!               │
└─────────────────────────────────────────────┘
```

---

## Step 5: View in Product List

Product List Page shows:
```
┌────────────────────────────────────────────┐
│  📦 Aqua Mineral Water 600ml  [3] 🏪      │
│  PCS • Rp 5,000                            │
│  Stock: 100 • Min: 20                      │
│  Kategori: Minuman                         │
└────────────────────────────────────────────┘

Badges:
[3]  = Product has 3 units
🏪   = Product has branch-specific pricing
```

---

## Step 6: View in Product Detail

Click product → Detail Page opens

### Units Section
```
┌─── 📦 Units ───────────────────────────────┐
│                                            │
│  Unit   Konversi   Jual   Beli   Barcode  │
│  ─────  ─────────  ─────  ─────  ────────  │
│  PCS    1          ✓      ✓      -         │
│  PAK    6          ✓      ✓      PAK-...   │
│  DUS    48         ✗      ✓      DUS-...   │
│                                            │
└────────────────────────────────────────────┘
```

### Pricing Section
```
┌─── 💰 Pricing per Branch ──────────────────┐
│                                            │
│  📍 Cabang Pusat                           │
│  • PCS:  Rp 3,000 → Rp 5,000 (66.7%)      │
│    Grosir: Rp 4,500 | Member: Rp 4,700    │
│                                            │
│  • PAK:  Rp 17,000 → Rp 28,000 (64.7%)    │
│    Grosir: Rp 26,000 | Member: Rp 27,000  │
│                                            │
│  📍 Cabang Tangerang                       │
│  • PCS:  Rp 3,200 → Rp 5,500 (71.9%)      │
│    Grosir: Rp 5,000 | Member: Rp 5,200    │
│                                            │
│  • PAK:  Rp 18,500 → Rp 31,000 (67.6%)    │
│    Grosir: Rp 29,000 | Member: Rp 30,000  │
│                                            │
└────────────────────────────────────────────┘
```

---

## 🎯 Key Takeaways

1. **Units Management**
   - ✅ Easy to add/edit/delete units
   - ✅ Set base unit with 1 click
   - ✅ Flexible conversion values
   - ✅ Control sell/purchase permissions

2. **Pricing Management**
   - ✅ Bulk add saves time (2 branches × 2 units = 4 prices instantly)
   - ✅ Auto-calculate margins
   - ✅ Support wholesale & member prices
   - ✅ Filter by branch or unit

3. **Data Integrity**
   - ✅ Must have 1 base unit
   - ✅ Base unit conversion = 1
   - ✅ Prices linked to specific branch + unit
   - ✅ All saved in one transaction

4. **User Experience**
   - ✅ Tab-based navigation (Info → Units → Pricing)
   - ✅ Visual indicators in list page
   - ✅ Detailed view in detail page
   - ✅ Persistent bottom bar shows summary

---

## 📱 Mobile/Tablet View

Same features work on smaller screens with responsive layout:
- Tabs scroll horizontally if needed
- Cards stack vertically
- Filter dropdowns adapt to screen width
- Bottom bar stays fixed

---

**Demo Complete!** 🎉

For more details, see:
- `UNITS_PRICING_MANAGEMENT_GUIDE.md` - Full user guide
- `UNITS_PRICING_INTEGRATION.md` - Developer integration guide
