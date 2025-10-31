import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/sale_return_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/hive_service.dart';

class SubmittedReturnsPage extends StatefulWidget {
  const SubmittedReturnsPage({super.key});

  @override
  State<SubmittedReturnsPage> createState() => _SubmittedReturnsPageState();
}

class _SubmittedReturnsPageState extends State<SubmittedReturnsPage> {
  List<Map<String, dynamic>> _returns = [];
  bool _isLoading = false;
  String? _selectedStatus;
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalRecords = 0;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': null, 'label': 'Semua Status', 'color': Colors.grey},
    {'value': 'pending', 'label': 'Pending', 'color': Colors.orange},
    {'value': 'processed', 'label': 'Diproses', 'color': Colors.blue},
    {'value': 'completed', 'label': 'Selesai', 'color': Colors.green},
    {'value': 'cancelled', 'label': 'Dibatalkan', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadReturns();
  }

  Future<void> _loadReturns({bool resetPage = false}) async {
    if (resetPage) _currentPage = 1;

    setState(() => _isLoading = true);

    try {
      final authBox = HiveService.instance.getBox('auth');
      final token = authBox.get('auth_token');
      final branch = authBox.get('branch');
      final branchId = branch?['id'];
      final cashier = authBox.get('user');
      final cashierId = cashier?['id'];

      final settingsBox = HiveService.instance.getBox('settings');
      final serverUrl = settingsBox.get(
        'serverUrl',
        defaultValue: 'http://localhost:3001',
      );

      if (token == null || branchId == null) {
        throw Exception('Missing authentication data');
      }

      final queryParams = {
        'branchId': branchId.toString(),
        'limit': _pageSize.toString(),
        'offset': ((_currentPage - 1) * _pageSize).toString(),
        if (_selectedStatus != null) 'status': _selectedStatus!,
      };

      final uri = Uri.parse(
        '$serverUrl/api/v2/sales-returns',
      ).replace(queryParameters: queryParams);

      print('📥 Fetching returns from: $uri');

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
        print('📊 Returns API Response: ${data.keys}');

        if (data['success'] == true) {
          final returnsData = data['data'] as List;
          final pagination = data['pagination'] as Map<String, dynamic>?;

          _totalRecords = pagination?['total'] ?? returnsData.length;

          setState(() {
            _returns =
                returnsData
                    .map((json) => Map<String, dynamic>.from(json as Map))
                    .toList();
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

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processed':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Retur yang Diajukan'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadReturns(resetPage: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text(
                  'Filter Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _statusOptions.map((option) {
                            final isSelected =
                                _selectedStatus == option['value'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(option['label'] as String),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus =
                                        selected
                                            ? option['value'] as String?
                                            : null;
                                  });
                                  _loadReturns(resetPage: true);
                                },
                                backgroundColor: Colors.white,
                                selectedColor: (option['color'] as Color)
                                    .withOpacity(0.2),
                                checkmarkColor: option['color'] as Color,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? option['color'] as Color
                                          : Colors.black87,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Returns List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _returns.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_return,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada retur',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _returns.length,
                      itemBuilder: (context, index) {
                        final returnData = _returns[index];
                        return _buildReturnCard(returnData);
                      },
                    ),
          ),

          // Pagination
          if (_totalRecords > _pageSize) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> returnData) {
    final status = returnData['status']?.toString() ?? 'pending';
    final statusColor = _getStatusColor(status);
    final items = returnData['items'] as List? ?? [];
    final totalRefund = _parseDouble(returnData['total_refund']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.assignment_return, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                returnData['return_number']?.toString() ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                _getStatusLabel(status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDateTime(returnData['return_date']?.toString()),
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Invoice: ${returnData['original_invoice_number'] ?? '-'}',
              style: const TextStyle(fontSize: 12),
            ),
            if (returnData['cashier_name'] != null)
              Text(
                '👤 ${returnData['cashier_name']}',
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
                // Return Information
                const Text(
                  'Informasi Retur:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Alasan', returnData['return_reason'] ?? '-'),
                _buildInfoRow(
                  'Metode Refund',
                  returnData['refund_method'] ?? 'cash',
                ),
                if (returnData['notes'] != null)
                  _buildInfoRow('Catatan', returnData['notes']),
                if (returnData['processed_by_name'] != null)
                  _buildInfoRow(
                    'Diproses oleh',
                    returnData['processed_by_name'],
                  ),

                const Divider(height: 24),

                // Items List
                const Text(
                  'Item yang Diretur:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['product_name']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (item['reason'] != null)
                                Text(
                                  'Alasan: ${item['reason']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_parseDouble(item['quantity']).toInt()}x',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                _parseDouble(item['subtotal']),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
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

                // Total Refund
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Refund:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(totalRefund),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
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
          Text('Total: $_totalRecords retur'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    _currentPage > 1
                        ? () {
                          setState(() => _currentPage--);
                          _loadReturns();
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
                          _loadReturns();
                        }
                        : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
