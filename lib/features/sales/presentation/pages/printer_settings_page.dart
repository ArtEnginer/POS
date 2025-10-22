import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/print_settings.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  bool _autoPrint = false;
  String? _defaultPrinter;
  int _printCopies = 1;
  bool _isLoading = true;

  final List<String> _availablePrinters = [
    'Microsoft Print to PDF',
    'POS-80 Thermal Printer',
    'Epson TM-T82',
    'Star TSP143',
    // Tambahkan printer lainnya sesuai kebutuhan
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoPrint = await PrintSettings.getAutoPrint();
    final defaultPrinter = await PrintSettings.getDefaultPrinter();
    final printCopies = await PrintSettings.getPrintCopies();

    setState(() {
      _autoPrint = autoPrint;
      _defaultPrinter = defaultPrinter;
      _printCopies = printCopies;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await PrintSettings.setAutoPrint(_autoPrint);
    if (_defaultPrinter != null) {
      await PrintSettings.setDefaultPrinter(_defaultPrinter!);
    }
    await PrintSettings.setPrintCopies(_printCopies);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Auto Print Setting
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.print,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Cetak Otomatis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Cetak Struk Otomatis'),
                            subtitle: Text(
                              _autoPrint
                                  ? 'Struk akan dicetak otomatis setelah transaksi selesai'
                                  : 'Struk hanya dicetak jika diminta manual',
                            ),
                            value: _autoPrint,
                            onChanged: (value) {
                              setState(() {
                                _autoPrint = value;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Default Printer Selection
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.devices,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Printer Default',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _defaultPrinter,
                            decoration: InputDecoration(
                              labelText: 'Pilih Printer',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.print),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('-- Pilih Printer --'),
                              ),
                              ..._availablePrinters.map(
                                (printer) => DropdownMenuItem<String>(
                                  value: printer,
                                  child: Text(printer),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _defaultPrinter = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pastikan printer sudah terinstall dan terhubung dengan komputer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Print Copies
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.content_copy,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Jumlah Salinan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text(
                                'Jumlah Cetak:',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        if (_printCopies > 1) {
                                          setState(() {
                                            _printCopies--;
                                          });
                                        }
                                      },
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Text(
                                        _printCopies.toString(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        if (_printCopies < 5) {
                                          setState(() {
                                            _printCopies++;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Max: 5 salinan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Test Print Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _testPrint,
                      icon: const Icon(Icons.print),
                      label: const Text('Test Cetak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Pengaturan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  void _testPrint() {
    if (_defaultPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih printer terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implementasi test print
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test print ke $_defaultPrinter'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
