import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/sale_model.dart';
import '../../data/models/sales_return_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/hive_service.dart';

class SalesReturnDialog extends StatefulWidget {
  const SalesReturnDialog({super.key});

  @override
  State<SalesReturnDialog> createState() => _SalesReturnDialogState();
}

class _SalesReturnDialogState extends State<SalesReturnDialog> {
  List<SaleModel> _recentSales = [];
  SaleModel? _selectedSale;
  final Map<String, int> _returnQuantities = {}; // productId -> quantity
  final Map<String, TextEditingController> _quantityControllers = {};
  final _reasonController = TextEditingController();
  String _selectedRefundMethod = 'cash';
  bool _isProcessing = false;
  bool _isLoadingSales = false;
  String? _errorMessage;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    // Don't call _loadRecentSales here - use didChangeDependencies instead
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load data only once after widget is fully built
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      // Use addPostFrameCallback to ensure context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRecentSales();
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Load sales from server (ONLINE ONLY)
  Future<void> _loadRecentSales() async {
    setState(() {
      _isLoadingSales = true;
      _errorMessage = null;
    });

    try {
      // Get auth data
      final authBox = HiveService.instance.getBox('auth');
      final token = authBox.get(
        'auth_token',
      ); // Changed from 'token' to 'auth_token'
      final branch = authBox.get('branch');
      final branchId = branch?['id'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      print('🔑 Using token: ${token.toString().substring(0, 20)}...');
      print('🏢 Branch ID: $branchId');

      // Get server URL from settings
      final settingsBox = HiveService.instance.getBox('settings');
      var serverUrl = settingsBox.get(
        'serverUrl',
        defaultValue: 'http://localhost:3000',
      );

      // Try port 3001 if 3000 is not set
      if (serverUrl == 'http://localhost:3000' || serverUrl.isEmpty) {
        serverUrl = 'http://localhost:3001';
      }

      print('🌐 Server URL: $serverUrl');

      // Fetch from API
      final url = Uri.parse(
        '$serverUrl/api/v2/sales-returns/recent-sales?days=30&branchId=$branchId',
      );

      print('📡 Fetching from: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Koneksi timeout. Pastikan server dapat diakses.',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('📦 Response data: $data');
        print('✅ Success: ${data['success']}');
        print('📊 Data type: ${data['data'].runtimeType}');

        if (data['success'] == true) {
          final salesData = data['data'] as List;
          print('📋 Found ${salesData.length} sales');

          final sales = <SaleModel>[];
          for (var i = 0; i < salesData.length; i++) {
            try {
              final saleJson = salesData[i];
              print('🔄 Processing sale $i: ${saleJson['invoiceNumber']}');

              // Ensure all fields are properly typed
              final sale = SaleModel.fromJson(
                saleJson is Map<String, dynamic>
                    ? saleJson
                    : Map<String, dynamic>.from(saleJson as Map),
              );

              sales.add(sale);
            } catch (e) {
              print('❌ Error parsing sale $i: $e');
              print('   Data: ${salesData[i]}');
            }
          }

          setState(() {
            _recentSales = sales;
            _isLoadingSales = false;
          });

          print('✅ Successfully loaded ${sales.length} sales');
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat data');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Silakan login kembali.');
      } else {
        final errorBody = response.body;
        print('❌ Error response: $errorBody');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('📍 Stack trace: $stackTrace');

      setState(() {
        _errorMessage = e.toString();
        _isLoadingSales = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _selectSale(SaleModel sale) {
    setState(() {
      _selectedSale = sale;
      _returnQuantities.clear();

      // Initialize controllers and default quantities
      for (var item in sale.items) {
        _quantityControllers[item.product.id] = TextEditingController(
          text: item.quantity.toString(),
        );
        _returnQuantities[item.product.id] = item.quantity;
      }
    });
  }

  void _updateReturnQuantity(String productId, int maxQty, String value) {
    final qty = int.tryParse(value) ?? 0;
    setState(() {
      if (qty > 0 && qty <= maxQty) {
        _returnQuantities[productId] = qty;
      } else if (qty > maxQty) {
        _returnQuantities[productId] = maxQty;
        _quantityControllers[productId]?.text = maxQty.toString();
      } else {
        _returnQuantities[productId] = 0;
      }
    });
  }

  double _calculateTotalRefund() {
    if (_selectedSale == null) return 0;

    double total = 0;
    for (var item in _selectedSale!.items) {
      final returnQty = _returnQuantities[item.product.id] ?? 0;
      if (returnQty > 0) {
        total += item.product.price * returnQty;
      }
    }
    return total;
  }

  Future<void> _processReturn() async {
    if (_selectedSale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih penjualan yang akan di-return'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate at least one item selected
    final hasReturnItems = _returnQuantities.values.any((qty) => qty > 0);
    if (!hasReturnItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 item untuk di-return'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan alasan return'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get auth data
      final authBox = HiveService.instance.getBox('auth');
      final token = authBox.get(
        'auth_token',
      ); // Changed from 'token' to 'auth_token'
      final user = authBox.get('user');
      final branch = authBox.get('branch');

      final cashierId = user?['id']?.toString() ?? '';
      final cashierName = user?['username']?.toString() ?? '';
      final branchId = branch?['id'] ?? 0;

      if (token == null || token.toString().isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      print(
        '🔄 Processing return with token: ${token.toString().substring(0, 20)}...',
      );
      print('👤 Cashier: $cashierName (ID: $cashierId)');
      print('🏢 Branch ID: $branchId');

      // Prepare return items for API
      final returnItemsJson = <Map<String, dynamic>>[];
      for (var item in _selectedSale!.items) {
        final returnQty = _returnQuantities[item.product.id] ?? 0;
        if (returnQty > 0) {
          returnItemsJson.add({
            'productId': int.tryParse(item.product.id) ?? 0,
            'productName': item.product.name,
            'quantity': returnQty,
            'unitPrice': item.product.price,
            'subtotal': item.product.price * returnQty,
            'reason': _reasonController.text.trim(),
          });
        }
      }

      // Prepare request body
      final requestBody = {
        'returnNumber': SalesReturnModel.generateReturnNumber(),
        'originalSaleId': int.tryParse(_selectedSale!.id) ?? 0,
        'originalInvoiceNumber': _selectedSale!.invoiceNumber,
        'branchId':
            branchId is int ? branchId : int.tryParse(branchId.toString()) ?? 0,
        'returnReason': _reasonController.text.trim(),
        'totalRefund': _calculateTotalRefund(),
        'refundMethod': _selectedRefundMethod,
        'customerId':
            _selectedSale!.customerId != null
                ? int.tryParse(_selectedSale!.customerId!)
                : null,
        'customerName': _selectedSale!.customerName,
        'cashierId': int.tryParse(cashierId) ?? 0,
        'cashierName': cashierName,
        'items': returnItemsJson,
        'notes': '',
      };

      // Get server URL
      final settingsBox = HiveService.instance.getBox('settings');
      var serverUrl = settingsBox.get(
        'serverUrl',
        defaultValue: 'http://localhost:3000',
      );

      // Try port 3001 if 3000 is not set
      if (serverUrl == 'http://localhost:3000' || serverUrl.isEmpty) {
        serverUrl = 'http://localhost:3001';
      }

      print('🌐 Posting to: $serverUrl/api/v2/sales-returns');
      print('📦 Request body: ${json.encode(requestBody)}');

      // POST to API
      final url = Uri.parse('$serverUrl/api/v2/sales-returns');
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Koneksi timeout. Pastikan server dapat diakses.',
              );
            },
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Return berhasil dibuat: ${requestBody['returnNumber']}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Gagal membuat return');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        throw Exception('Penjualan tidak ditemukan atau sudah dihapus.');
      } else if (response.statusCode == 403) {
        throw Exception('Penjualan tidak dapat di-return (beda cabang).');
      } else {
        final errorBody = response.body;
        print('❌ Error response (${response.statusCode}): $errorBody');
        try {
          final data = json.decode(errorBody);
          throw Exception(
            data['message'] ?? 'Server error: ${response.statusCode}',
          );
        } catch (parseError) {
          throw Exception('Server error: ${response.statusCode} - $errorBody');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Exception during return submission: $e');
      print('📍 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat menyimpan return: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.assignment_return,
                  size: 32,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Return Penjualan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: List of recent sales
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Penjualan (30 Hari Terakhir)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _buildSalesList()),
                      ],
                    ),
                  ),

                  const VerticalDivider(width: 32),

                  // Right: Return details
                  Expanded(
                    flex: 3,
                    child:
                        _selectedSale == null
                            ? const Center(
                              child: Text(
                                'Pilih penjualan untuk memulai return',
                              ),
                            )
                            : _buildReturnDetails(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList() {
    // Show loading
    if (_isLoadingSales) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data dari server...'),
          ],
        ),
      );
    }

    // Show error with retry
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRecentSales,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (_recentSales.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tidak ada penjualan dalam 30 hari terakhir'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _recentSales.length,
      itemBuilder: (context, index) {
        final sale = _recentSales[index];
        final isSelected = _selectedSale?.id == sale.id;
        // Note: Check if sale has been returned via API if needed

        return Card(
          color: isSelected ? Colors.blue[50] : null,
          child: ListTile(
            leading: const Icon(Icons.receipt, color: Colors.blue),
            title: Text(
              sale.invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(sale.transactionDate)),
                Text(
                  CurrencyFormatter.format(sale.total),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Note: Can add return status check via API if needed
              ],
            ),
            trailing:
                isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
            onTap: () => _selectSale(sale),
          ),
        );
      },
    );
  }

  Widget _buildReturnDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sale info
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSale!.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Tanggal: ${_formatDate(_selectedSale!.transactionDate)}'),
                Text('Kasir: ${_selectedSale!.cashierName}'),
                if (_selectedSale!.customerName != null)
                  Text('Customer: ${_selectedSale!.customerName}'),
                const SizedBox(height: 8),
                Text(
                  'Total: ${CurrencyFormatter.format(_selectedSale!.total)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Items to return
        Text(
          'Pilih Item yang Di-return',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            itemCount: _selectedSale!.items.length,
            itemBuilder: (context, index) {
              final item = _selectedSale!.items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.product.price),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Text('Qty: '),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller:
                                    _quantityControllers[item.product.id],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  hintText: item.quantity.toString(),
                                ),
                                onChanged:
                                    (value) => _updateReturnQuantity(
                                      item.product.id,
                                      item.quantity,
                                      value,
                                    ),
                              ),
                            ),
                            Text(' / ${item.quantity}'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          CurrencyFormatter.format(
                            item.product.price *
                                (_returnQuantities[item.product.id] ?? 0),
                          ),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Return reason
        TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Alasan Return *',
            border: OutlineInputBorder(),
            hintText: 'Contoh: Barang rusak, salah beli, dll',
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        // Refund method
        Row(
          children: [
            const Text('Metode Refund: '),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedRefundMethod,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                DropdownMenuItem(value: 'credit', child: Text('Kredit Toko')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRefundMethod = value ?? 'cash';
                });
              },
            ),
          ],
        ),

        const Divider(height: 32),

        // Total refund & action
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Refund', style: TextStyle(fontSize: 16)),
                  Text(
                    CurrencyFormatter.format(_calculateTotalRefund()),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processReturn,
              icon:
                  _isProcessing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check),
              label: Text(_isProcessing ? 'Memproses...' : 'Proses Return'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
