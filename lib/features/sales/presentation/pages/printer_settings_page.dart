import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
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
  bool _isLoadingPrinters = false;
  List<Printer> _availablePrinters = [];
  List<String> _printerNames = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPrinters();
  }

  Future<void> _loadSettings() async {
    final autoPrint = await PrintSettings.getAutoPrint();
    final defaultPrinter = await PrintSettings.getDefaultPrinter();
    final printCopies = await PrintSettings.getPrintCopies();

    if (mounted) {
      setState(() {
        _autoPrint = autoPrint;
        _defaultPrinter = defaultPrinter;
        _printCopies = printCopies;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _isLoadingPrinters = true;
    });

    try {
      // Get list of available printers from system
      final printers = await Printing.listPrinters();

      if (mounted) {
        setState(() {
          _availablePrinters = printers;
          // Hapus duplikasi dengan toSet().toList()
          _printerNames = printers.map((p) => p.name).toSet().toList();

          // Validasi: Jika default printer tidak ada di list, set ke null
          if (_defaultPrinter != null &&
              !_printerNames.contains(_defaultPrinter)) {
            _defaultPrinter = null;
          }

          _isLoadingPrinters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPrinters = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat daftar printer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                          Row(
                            children: [
                              Expanded(
                                child:
                                    _isLoadingPrinters
                                        ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                        : DropdownButtonFormField<String>(
                                          value:
                                              _printerNames.contains(
                                                    _defaultPrinter,
                                                  )
                                                  ? _defaultPrinter
                                                  : null,
                                          decoration: InputDecoration(
                                            labelText: 'Pilih Printer',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            prefixIcon: const Icon(Icons.print),
                                          ),
                                          items: [
                                            const DropdownMenuItem<String>(
                                              value: null,
                                              child: Text(
                                                '-- Pilih Printer --',
                                              ),
                                            ),
                                            ..._printerNames.map(
                                              (printerName) =>
                                                  DropdownMenuItem<String>(
                                                    value: printerName,
                                                    child: Text(printerName),
                                                  ),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _defaultPrinter = value;
                                            });
                                          },
                                        ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadPrinters,
                                tooltip: 'Refresh Daftar Printer',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_printerNames.isEmpty && !_isLoadingPrinters)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_outlined,
                                    color: Colors.orange[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tidak ada printer ditemukan. Pastikan printer sudah terinstall.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ditemukan ${_printerNames.length} printer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                        Text(
                                          'Termasuk printer local dan network',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue[600],
                                          ),
                                        ),
                                      ],
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

                  // Printer List Details
                  if (_availablePrinters.isNotEmpty)
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
                                  Icons.list_alt,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Detail Printer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _availablePrinters.length,
                              separatorBuilder:
                                  (context, index) => const Divider(height: 16),
                              itemBuilder: (context, index) {
                                final printer = _availablePrinters[index];
                                final isSelected =
                                    printer.name == _defaultPrinter;
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColors.primary.withOpacity(0.1)
                                            : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            printer.isAvailable
                                                ? Icons.check_circle
                                                : Icons.error_outline,
                                            color:
                                                printer.isAvailable
                                                    ? Colors.green
                                                    : Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              printer.name,
                                              style: TextStyle(
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Default',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Status: ${printer.isAvailable ? "Tersedia" : "Tidak Tersedia"}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (printer.location != null &&
                                          printer.location!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Lokasi: ${printer.location}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (printer.model != null &&
                                          printer.model!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Model: ${printer.model}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
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
