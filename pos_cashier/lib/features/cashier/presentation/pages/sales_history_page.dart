import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/sale_model.dart';
import '../../data/models/sale_return_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/hive_service.dart';
import '../widgets/sales_return_dialog_v2.dart';
import '../widgets/print_options_dialog.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  List<SaleModel> _sales = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalRecords = 0;

  final _searchController = TextEditingController();
  String? _selectedDateRange;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales({bool resetPage = false}) async {
    if (resetPage) _currentPage = 1;

    setState(() => _isLoading = true);

    try {
      final authBox = HiveService.instance.getBox('auth');
      final token = authBox.get('auth_token');
      final branch = authBox.get('branch');
      final branchId = branch?['id'];

      final settingsBox = HiveService.instance.getBox('settings');
      final serverUrl = settingsBox.get(
        'serverUrl',
        defaultValue: 'http://localhost:3001',
      );

      final queryParams = {
        'page': _currentPage.toString(),
        'limit': _pageSize.toString(),
        'branchId': branchId.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
        if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
      };

      final uri = Uri.parse(
        '$serverUrl/api/v2/sales',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 API Response: ${data.keys}');
        print('📊 Total from API: ${data['total']}');
        print('📊 Data length: ${(data['data'] as List).length}');

        if (data['success'] == true) {
          final salesData = data['data'] as List;

          // Parse total safely (could be int, String, or null)
          if (data['total'] is int) {
            _totalRecords = data['total'];
          } else if (data['total'] is String) {
            _totalRecords = int.tryParse(data['total']) ?? salesData.length;
          } else {
            _totalRecords = salesData.length;
          }

          print('📊 Parsed _totalRecords: $_totalRecords');

          final sales =
              salesData
                  .map(
                    (json) => SaleModel.fromJson(
                      json is Map<String, dynamic>
                          ? json
                          : Map<String, dynamic>.from(json as Map),
                    ),
                  )
                  .toList();

          setState(() {
            _sales = sales;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showReturnDialog(SaleModel sale) async {
    final result = await showDialog(
      context: context,
      builder: (context) => SalesReturnDialogV2(preSelectedSale: sale),
    );

    if (result == true) {
      _loadSales();
    }
  }

  Future<void> _confirmDeleteReturn(
    SaleModel sale,
    SaleReturnModel returnData,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Retur?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menghapus retur ini?'),
            const SizedBox(height: 12),
            Text(
              'No. Retur: ${returnData.returnNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Refund: ${CurrencyFormatter.format(returnData.refundAmount)}',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stok akan dikembalikan seperti sebelum retur',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteReturn(returnData.id);
    }
  }

  Future<void> _deleteReturn(String returnId) async {
    try {
      final authBox = HiveService.instance.getBox('auth');
      final token = authBox.get('auth_token');
      final settingsBox = HiveService.instance.getBox('settings');
      final serverUrl = settingsBox.get(
        'serverUrl',
        defaultValue: 'http://localhost:3001',
      );

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final response = await http.delete(
        Uri.parse('$serverUrl/api/v2/sales-returns/$returnId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      // Close loading
      if (mounted) Navigator.pop(context);

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retur berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Reload data
        _loadSales();
      } else {
        throw Exception(data['message'] ?? 'Gagal menghapus retur');
      }
    } catch (e) {
      print('❌ Error deleting return: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPrintOptions(SaleModel sale) async {
    showDialog(
      context: context,
      builder: (context) => PrintOptionsDialog(sale: sale),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedDateRange =
            '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
      });
      _loadSales(resetPage: true);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSales(resetPage: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari invoice, customer...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      _loadSales(resetPage: true);
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (value) {
                          setState(() => _searchQuery = value);
                          _loadSales(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date Filter
                    ElevatedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDateRange ?? 'Tanggal',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                            _selectedDateRange = null;
                          });
                          _loadSales(resetPage: true);
                        },
                        tooltip: 'Clear filter',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Sales List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _sales.isEmpty
                    ? const Center(child: Text('Tidak ada data'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sales.length,
                      itemBuilder: (context, index) {
                        final sale = _sales[index];
                        return _buildSaleCard(sale);
                      },
                    ),
          ),

          // Pagination
          if (_totalRecords > _pageSize) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSaleCard(SaleModel sale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: const Icon(Icons.receipt_long, color: Colors.blue),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sale.invoiceNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    CurrencyFormatter.format(sale.total),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (sale.hasReturns) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      'Net: ${CurrencyFormatter.format(sale.netTotal)}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(sale.transactionDate),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (sale.hasReturns)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Text(
                      '🔄 ${sale.returns.length} Retur',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (sale.customerName != null)
              Text(
                '👤 ${sale.customerName}',
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              '💼 ${sale.cashierName}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items List
                const Text(
                  'Detail Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...sale.items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama produk & qty
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Harga satuan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Harga Satuan:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.product.price),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),

                        // Subtotal (qty x harga)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.subtotal),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Diskon (jika ada)
                        if (item.discount > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Diskon (${item.discount.toStringAsFixed(1)}%):',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                '- ${CurrencyFormatter.format(item.discountAmount)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // PPN/Pajak (jika ada)
                        if (item.taxPercent > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PPN (${item.taxPercent.toStringAsFixed(1)}%):',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                '+ ${CurrencyFormatter.format(item.taxAmount)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const Divider(height: 12),

                        // Total item
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Item:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.total),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),

                // Returns section (if any)
                if (sale.hasReturns) ...[
                  const Text(
                    'Retur Penjualan:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sale.returns.map(
                    (returnData) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.assignment_return,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  returnData.returnNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                _formatDateTime(returnData.returnDate),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              InkWell(
                                onTap: () => _confirmDeleteReturn(
                                  sale,
                                  returnData,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Alasan: ${returnData.reason}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Items:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...returnData.items.map(
                            (retItem) => Padding(
                              padding: const EdgeInsets.only(left: 12, top: 4),
                              child: Row(
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Expanded(
                                    child: Text(
                                      retItem.productName,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '${retItem.quantity}x',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.format(retItem.total),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Refund:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                '- ${CurrencyFormatter.format(returnData.refundAmount)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                ],

                // Totals
                _buildTotalRow('Subtotal', sale.subtotal),
                if (sale.discount > 0) _buildTotalRow('Diskon', -sale.discount),
                if (sale.tax > 0) _buildTotalRow('Pajak', sale.tax),
                const Divider(),
                _buildTotalRow('TOTAL', sale.total, bold: true),
                if (sale.hasReturns) ...[
                  _buildTotalRow(
                    'Total Retur',
                    -sale.returns.fold<double>(
                      0.0,
                      (sum, ret) => sum + ret.refundAmount,
                    ),
                    color: Colors.red,
                  ),
                  const Divider(),
                  _buildTotalRow(
                    'NET TOTAL',
                    sale.netTotal,
                    bold: true,
                    color: Colors.orange,
                  ),
                ],
                _buildTotalRow('Bayar', sale.paid),
                if (sale.change > 0) _buildTotalRow('Kembali', sale.change),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // Print Nota (Thermal 80mm)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPrintOptions(sale),
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text(
                          'Print',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Return Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showReturnDialog(sale),
                        icon: const Icon(Icons.assignment_return, size: 18),
                        label: const Text(
                          'Return',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
              color: color,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_totalRecords / _pageSize).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: $_totalRecords transaksi'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    _currentPage > 1
                        ? () {
                          setState(() => _currentPage--);
                          _loadSales();
                        }
                        : null,
              ),
              Text('$_currentPage / $totalPages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    _currentPage < totalPages
                        ? () {
                          setState(() => _currentPage++);
                          _loadSales();
                        }
                        : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
