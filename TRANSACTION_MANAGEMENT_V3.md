# SISTEM MANAJEMEN TRANSAKSI & CETAK NOTA

**Tanggal**: 30 Oktober 2025  
**Versi**: 3.0

## 🎯 FITUR BARU

### 1. **Halaman Riwayat Transaksi** 📋

- Daftar semua transaksi dengan pagination
- Search: Invoice, Customer, Kasir
- Filter tanggal (Date Range Picker)
- Expand/collapse untuk lihat detail
- Action buttons per transaksi

### 2. **Multiple Print Format** 🖨️

- **Nota Thermal 80mm** - Format struk kasir
- **Invoice A4** - Format invoice resmi untuk accounting
- **Surat Jalan A4** - Untuk pengiriman barang

### 3. **Direct Actions** ⚡

- Print langsung dari list transaksi
- Return langsung dari list transaksi
- Pre-selected sale untuk return cepat

### 4. **Print Features**

- **Nota Thermal**: Struk kasir kompak 80mm
- **Invoice A4**: Layout professional dengan header toko
- **Surat Jalan**: Include pengirim, penerima, sopir signature

---

## 📁 NEW FILES

### Frontend (Flutter)

#### 1. **sales_history_page.dart**

```
pos_cashier/lib/features/cashier/presentation/pages/sales_history_page.dart
```

**Features**:

- ✅ Pagination (20 per page)
- ✅ Search invoice/customer/cashier
- ✅ Date range filter
- ✅ Expandable card untuk detail
- ✅ Action buttons: Print & Return
- ✅ Total calculation display

**UI Elements**:

```dart
AppBar
├── Title: "Riwayat Transaksi"
└── Refresh button

Search & Filter Section
├── Search TextField (invoice/customer/kasir)
└── Date Range Picker button

Sales List (Expandable Cards)
└── Card
    ├── Invoice Number
    ├── Date & Time
    ├── Customer Name
    ├── Cashier Name
    ├── Total Amount
    └── Expand
        ├── Items detail
        ├── Subtotal, discount, tax
        └── Actions
            ├── Print Button → Print Options
            └── Return Button → Return Dialog

Pagination
├── Total records
└── Page navigation
```

#### 2. **print_options_dialog.dart**

```
pos_cashier/lib/features/cashier/presentation/widgets/print_options_dialog.dart
```

**Features**:

- ✅ 3 print formats:
  1. Nota Thermal 80mm
  2. Invoice A4
  3. Surat Jalan A4
- ✅ PDF generation untuk setiap format
- ✅ Print preview dengan `printing` package

**Print Format Details**:

##### **Nota Thermal 80mm**

```
================================
       NAMA TOKO
    Alamat Lengkap
    Telp: XXX
================================
No. Invoice  : INV-XXX
Tanggal      : DD/MM/YYYY HH:MM
Kasir        : Nama Kasir
Customer     : Nama Customer
================================
ITEMS:
Produk A
  2 x Rp 10,000      Rp 20,000

Produk B
  1 x Rp 15,000      Rp 15,000
--------------------------------
Subtotal            Rp 35,000
Diskon              Rp  5,000
Pajak               Rp  3,000
================================
TOTAL               Rp 33,000
================================
Bayar               Rp 50,000
Kembali             Rp 17,000

  Terima kasih atas kunjungan
================================
```

##### **Invoice A4**

```
┌─────────────────────────────────────────────────┐
│ NAMA TOKO                        INVOICE        │
│ Alamat                      No: INV-XXX         │
│ Telp: XXX                   Tanggal: DD/MM/YYYY │
│ Email: XXX                                      │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ KEPADA:                                         │
│ Nama Customer                                   │
│ (Alamat jika ada)                               │
└─────────────────────────────────────────────────┘

┌────┬──────────────┬─────┬───────────┬──────────┐
│ No │ Nama Produk  │ Qty │   Harga   │  Total   │
├────┼──────────────┼─────┼───────────┼──────────┤
│  1 │ Produk A     │  2  │ 10,000    │ 20,000   │
│  2 │ Produk B     │  1  │ 15,000    │ 15,000   │
└────┴──────────────┴─────┴───────────┴──────────┘

                            Subtotal  : Rp 35,000
                            Diskon    : Rp  5,000
                            Pajak     : Rp  3,000
                            ──────────────────────
                            TOTAL     : Rp 33,000
                            ──────────────────────

Metode: Cash                    ___________________
Kasir: John Doe               Tanda Tangan & Stempel
```

##### **Surat Jalan A4**

```
             NAMA TOKO
          Alamat Lengkap
           Telp: XXX

        SURAT JALAN
    ═══════════════════════

No: SJ-INV-XXX         Ref Invoice: INV-XXX
Tanggal: DD/MM/YYYY

┌──────────────────────┬──────────────────────┐
│ PENGIRIM:            │ PENERIMA:            │
│ Nama Toko            │ Nama Customer        │
│ Alamat Toko          │ Alamat Customer      │
│ Telp: XXX            │ Telp: XXX            │
└──────────────────────┴──────────────────────┘

┌────┬──────────────┬─────┬────────┬──────────┐
│ No │ Nama Produk  │ Qty │ Satuan │ Ket      │
├────┼──────────────┼─────┼────────┼──────────┤
│  1 │ Produk A     │  2  │  PCS   │          │
│  2 │ Produk B     │  1  │  PCS   │          │
└────┴──────────────┴─────┴────────┴──────────┘


Pengirim        Penerima         Sopir

________        ________        ________
(...........)   (...........)   (...........)

Catatan: Barang yang sudah dikirim tidak dapat
dikembalikan kecuali ada kesalahan dari pihak kami.
```

---

## 📋 UPDATED FILES

### Frontend

#### **sales_return_dialog_v2.dart**

**Changes**:

- ✅ Added `preSelectedSale` parameter
- ✅ Auto-select sale if pre-selected
- ✅ Skip loading recent sales if sale provided

```dart
// OLD
const SalesReturnDialogV2({super.key});

// NEW
const SalesReturnDialogV2({
  super.key,
  this.preSelectedSale
});

// Usage from History Page
SalesReturnDialogV2(preSelectedSale: sale)
```

---

## 🔧 BACKEND

### Existing Endpoint

```
GET /api/v2/sales
```

**Query Parameters**:

```javascript
{
  page: 1,              // Page number
  limit: 20,            // Records per page
  search: '',           // Search query
  startDate: '',        // ISO date
  endDate: '',          // ISO date
  branchId: 1,          // Filter by branch
  status: 'completed'   // Filter by status
}
```

**Response**:

```json
{
  "success": true,
  "data": [...],
  "total": 150,
  "page": 1,
  "limit": 20
}
```

---

## 🎨 UI FLOW

### 1. **Opening Sales History**

```
Cashier Page
    └── Menu/Navigation
        └── "Riwayat Transaksi" button
            └── Opens SalesHistoryPage
```

### 2. **View & Search Transactions**

```
Sales History Page
    ├── Search bar (type & Enter)
    ├── Date filter (select range)
    └── Results
        └── Card (expandable)
            ├── Collapsed: Invoice, Date, Total
            └── Expanded: Full detail + actions
```

### 3. **Print Flow**

```
Sale Card → Print Button
    └── Print Options Dialog
        ├── Nota (80mm) → PDF Preview → Print
        ├── Invoice (A4) → PDF Preview → Print
        └── Surat Jalan (A4) → PDF Preview → Print
```

### 4. **Return Flow**

```
Sale Card → Return Button
    └── Return Dialog (Pre-selected)
        ├── Skip sale selection
        ├── Show items directly
        ├── Input quantities & reason
        └── Process return
            └── Print return receipt option
```

---

## 📊 COMPARISON: OLD vs NEW

| Feature               | Before           | After                            |
| --------------------- | ---------------- | -------------------------------- |
| **View Transactions** | ❌ None          | ✅ Full history page             |
| **Search**            | ❌ None          | ✅ Search invoice/customer/kasir |
| **Date Filter**       | ❌ None          | ✅ Date range picker             |
| **Print Nota**        | ❌ None          | ✅ 3 formats (Nota/Invoice/SJ)   |
| **Return**            | ⚠️ Manual search | ✅ Direct from list              |
| **Pagination**        | ❌ None          | ✅ 20 per page                   |
| **Expandable Detail** | ❌ None          | ✅ Collapsible cards             |

---

## 🚀 CARA PAKAI

### 1. **Install Dependencies**

```bash
cd pos_cashier
flutter pub get
```

### 2. **Add Navigation**

Update `cashier_page.dart` atau main drawer:

```dart
// Add to navigation menu
ListTile(
  leading: Icon(Icons.history),
  title: Text('Riwayat Transaksi'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesHistoryPage(),
      ),
    );
  },
),
```

### 3. **Test Features**

#### **View History**

1. Buka "Riwayat Transaksi"
2. List transaksi muncul (20 per page)
3. Klik card untuk expand detail

#### **Search**

1. Ketik "INV-001" di search
2. Tekan Enter
3. Hasil filtered muncul

#### **Date Filter**

1. Klik button "Tanggal"
2. Pilih range (misal: 1 Oct - 30 Oct)
3. Results filtered by date

#### **Print Nota**

1. Expand sale card
2. Klik "Print"
3. Pilih "Nota (Thermal 80mm)"
4. Preview muncul
5. Klik Print

#### **Print Invoice**

1. Expand sale card
2. Klik "Print"
3. Pilih "Invoice (A4)"
4. Professional invoice muncul
5. Print or Save PDF

#### **Print Surat Jalan**

1. Expand sale card
2. Klik "Print"
3. Pilih "Surat Jalan (A4)"
4. Delivery note muncul
5. Print for delivery

#### **Process Return**

1. Expand sale card
2. Klik "Return"
3. Return dialog langsung show items
4. Input quantity & reason
5. Process return
6. Option print return receipt

---

## 🎯 KEY IMPROVEMENTS

### **Better UX**

- ✅ One-stop untuk manage transaksi
- ✅ No need manual search untuk return
- ✅ Multiple print formats untuk berbagai kebutuhan
- ✅ Professional invoice untuk customer

### **Business Benefits**

- ✅ Nota thermal untuk internal/kasir
- ✅ Invoice A4 untuk accounting/customer
- ✅ Surat jalan untuk delivery/logistik
- ✅ Audit trail dengan history lengkap
- ✅ Easy return process

### **Technical**

- ✅ Efficient pagination (tidak load semua data)
- ✅ Reusable print components
- ✅ Clean architecture
- ✅ PDF generation dengan `pdf` & `printing` packages

---

## 📝 TODO / FUTURE ENHANCEMENTS

- [ ] Bulk print (multiple invoices)
- [ ] Email/WhatsApp invoice
- [ ] Custom nota template
- [ ] QR code di invoice
- [ ] Return history per sale
- [ ] Export to Excel
- [ ] Print queue management
- [ ] Template customization UI

---

## 🐛 TROUBLESHOOTING

### "Page not found"

```dart
// Make sure to import:
import '../pages/sales_history_page.dart';
```

### "Print preview error"

```bash
# Ensure packages installed:
flutter pub get

# Check pubspec.yaml includes:
pdf: ^3.11.1
printing: ^5.13.4
```

### "No data showing"

```
1. Check backend running (port 3001)
2. Check auth token valid
3. Check branch_id filter
4. Check console for API errors
```

---

**Created by**: AI Assistant  
**Last Updated**: 30 Oktober 2025  
**Version**: 3.0.0
