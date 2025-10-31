import 'package:flutter/material.dart';
import '../../data/models/cashier_settings_model.dart';
import '../../../../main.dart';

class CashierSettingsPage extends StatefulWidget {
  const CashierSettingsPage({super.key});

  @override
  State<CashierSettingsPage> createState() => _CashierSettingsPageState();
}

class _CashierSettingsPageState extends State<CashierSettingsPage> {
  late CashierSettingsModel _settings;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _deviceNameController;
  late TextEditingController _locationController;
  late TextEditingController _counterController;
  late TextEditingController _floorController;
  late TextEditingController _printerController;
  late TextEditingController _drawerController;

  bool _autoPrint = true;
  bool _allowOffline = true;
  String _theme = 'light';
  String _printFormat = 'receipt'; // 'receipt', 'invoice', 'delivery_note'

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _settings = cashierSettingsService.getSettings();

    _deviceNameController = TextEditingController(text: _settings.deviceName);
    _locationController = TextEditingController(
      text: _settings.cashierLocation ?? '',
    );
    _counterController = TextEditingController(
      text: _settings.counterNumber ?? '',
    );
    _floorController = TextEditingController(text: _settings.floorLevel ?? '');
    _printerController = TextEditingController(
      text: _settings.receiptPrinter ?? '',
    );
    _drawerController = TextEditingController(
      text: _settings.cashDrawerPort ?? '',
    );

    _autoPrint = _settings.autoPrintReceipt;
    _allowOffline = _settings.allowOfflineMode;
    _theme = _settings.themePreference;
    _printFormat = _settings.defaultPrintFormat;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _locationController.dispose();
    _counterController.dispose();
    _floorController.dispose();
    _printerController.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final updated = _settings.copyWith(
        deviceName: _deviceNameController.text,
        cashierLocation:
            _locationController.text.isEmpty ? null : _locationController.text,
        counterNumber:
            _counterController.text.isEmpty ? null : _counterController.text,
        floorLevel:
            _floorController.text.isEmpty ? null : _floorController.text,
        receiptPrinter:
            _printerController.text.isEmpty ? null : _printerController.text,
        cashDrawerPort:
            _drawerController.text.isEmpty ? null : _drawerController.text,
        autoPrintReceipt: _autoPrint,
        allowOfflineMode: _allowOffline,
        themePreference: _theme,
        defaultPrintFormat: _printFormat,
      );

      final success = await cashierSettingsService.saveSettings(updated);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pengaturan kasir berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _settings = updated;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal menyimpan pengaturan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset ke Default'),
            content: const Text(
              'Apakah Anda yakin ingin mereset semua pengaturan ke default?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('BATAL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('RESET', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await cashierSettingsService.resetToDefault();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pengaturan direset ke default'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _loadSettings();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefault,
            tooltip: 'Reset ke Default',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // DEVICE INFO SECTION
            _buildSectionHeader('Informasi Device'),
            _buildTextField(
              controller: _deviceNameController,
              label: 'Nama Device',
              hint: 'Contoh: Kasir-1, Kasir-2',
              icon: Icons.computer,
              validator: (v) => v!.isEmpty ? 'Nama device wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // LOCATION SECTION
            _buildSectionHeader('Lokasi Kasir'),
            _buildTextField(
              controller: _locationController,
              label: 'Lokasi Kasir',
              hint: 'Contoh: Lantai 1 - Depan',
              icon: Icons.location_on,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _counterController,
                    label: 'No. Counter',
                    hint: '1',
                    icon: Icons.confirmation_number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _floorController,
                    label: 'Lantai',
                    hint: 'Lantai 1',
                    icon: Icons.layers,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // HARDWARE SECTION
            _buildSectionHeader('Perangkat Keras'),
            _buildTextField(
              controller: _printerController,
              label: 'Printer Receipt',
              hint: 'Contoh: \\\\server\\printer1 atau COM1',
              icon: Icons.print,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _drawerController,
              label: 'Cash Drawer Port',
              hint: 'Contoh: COM1',
              icon: Icons.input,
            ),
            const SizedBox(height: 16),

            // OPERATIONAL SETTINGS
            _buildSectionHeader('Pengaturan Operasional'),
            SwitchListTile(
              title: const Text('Auto Print Receipt'),
              subtitle: const Text('Cetak struk otomatis setelah pembayaran'),
              value: _autoPrint,
              onChanged: (value) => setState(() => _autoPrint = value),
              secondary: const Icon(Icons.print_rounded),
            ),

            // Format Cetak Default (hanya muncul jika auto print enabled)
            if (_autoPrint)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Format Cetak Default',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _printFormat,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Format',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'receipt',
                          child: Row(
                            children: [
                              Icon(Icons.receipt, size: 18),
                              SizedBox(width: 8),
                              Text('Nota (Thermal 80mm)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'invoice',
                          child: Row(
                            children: [
                              Icon(Icons.description, size: 18),
                              SizedBox(width: 8),
                              Text('Invoice (A4)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'delivery_note',
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping, size: 18),
                              SizedBox(width: 8),
                              Text('Surat Jalan (A4)'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _printFormat = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Format ini akan digunakan untuk cetak otomatis setelah transaksi',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[900],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            SwitchListTile(
              title: const Text('Mode Offline'),
              subtitle: const Text('Izinkan operasi tanpa koneksi server'),
              value: _allowOffline,
              onChanged: (value) => setState(() => _allowOffline = value),
              secondary: const Icon(Icons.cloud_off),
            ),
            const SizedBox(height: 16),

            // THEME SECTION
            _buildSectionHeader('Tampilan'),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Tema Aplikasi'),
              trailing: DropdownButton<String>(
                value: _theme,
                items: const [
                  DropdownMenuItem(value: 'light', child: Text('Terang')),
                  DropdownMenuItem(value: 'dark', child: Text('Gelap')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _theme = value);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // INFO SECTION
            _buildInfoCard(),
            const SizedBox(height: 24),

            // SAVE BUTTON
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('SIMPAN PENGATURAN'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Informasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Pengaturan ini disimpan secara lokal di perangkat ini\n'
              '• Device info akan dikirim ke server saat transaksi\n'
              '• Lokasi kasir akan tercatat di setiap transaksi\n'
              '• Gunakan nama device yang unik untuk setiap kasir',
              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
            ),
          ],
        ),
      ),
    );
  }
}
