import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/sales_return_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/hive_service.dart';

class SalesReturnDialogV2 extends StatefulWidget {
  final SaleModel preSelectedSale; // Required, no longer optional

  const SalesReturnDialogV2({super.key, required this.preSelectedSale});

  @override
  State<SalesReturnDialogV2> createState() => _SalesReturnDialogV2State();
}

class _SalesReturnDialogV2State extends State<SalesReturnDialogV2> {
  SaleModel? _selectedSale;
  final Map<String, double> _returnQuantities = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  final _reasonController = TextEditingController();
  String _selectedRefundMethod = 'cash';
  bool _isProcessing = false;

  // Return result for printing
  Map<String, dynamic>? _createdReturn;

  @override
  void initState() {
    super.initState();
    // Auto-select the pre-selected sale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectSale(widget.preSelectedSale);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectSale(SaleModel sale) {
    setState(() {
      _selectedSale = sale;
      _returnQuantities.clear();
      _quantityControllers.clear();

      for (var item in sale.items) {
        _quantityControllers[item.product.id] = TextEditingController(
          text: item.quantity.toStringAsFixed(2),
        );
        _returnQuantities[item.product.id] = item.quantity.toDouble();
      }
    });
  }

  void _updateReturnQuantity(String productId, double maxQty, String value) {
    final qty = double.tryParse(value) ?? 0;
    setState(() {
      if (qty > 0 && qty <= maxQty) {
        _returnQuantities[productId] = qty;
      } else if (qty > maxQty) {
        _returnQuantities[productId] = maxQty;
        _quantityControllers[productId]?.text = maxQty.toStringAsFixed(2);
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
        // Calculate proportional refund including discount & tax
        // item.total already includes discount & tax per item
        final pricePerUnit = item.total / item.quantity;
        total += pricePerUnit * returnQty;
      }
    }
    return total;
  }

  Future<void> _processReturn() async {
    if (_selectedSale == null) {
      _showError('Pilih penjualan yang akan di-return');
      return;
    }

    final hasReturnItems = _returnQuantities.values.any((qty) => qty > 0);
    if (!hasReturnItems) {
      _showError('Pilih minimal 1 item untuk di-return');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showError('Masukkan alasan return');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final authBox = HiveService.instance.getBox('auth');
      final token = authBox.get('auth_token');
      final user = authBox.get('user');

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

      final requestBody = {
        'returnNumber': SalesReturnModel.generateReturnNumber(),
        'originalSaleId': int.tryParse(_selectedSale!.id) ?? 0,
        'originalInvoiceNumber': _selectedSale!.invoiceNumber,
        'branchId': _selectedSale!.branchId, // Use branch from selected sale
        'returnReason': _reasonController.text.trim(),
        'totalRefund': _calculateTotalRefund(),
        'refundMethod': _selectedRefundMethod,
        'customerId':
            _selectedSale!.customerId != null
                ? int.tryParse(_selectedSale!.customerId!)
                : null,
        'customerName': _selectedSale!.customerName,
        'cashierId': user?['id'] ?? 0,
        'cashierName': user?['username'] ?? '',
        'items': returnItemsJson,
        'notes': '',
      };

      final settingsBox = HiveService.instance.getBox('settings');
      final serverUrl = settingsBox.get(
        'serverUrl',
        defaultValue: 'http://localhost:3001',
      );

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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() => _createdReturn = data['data']);

          // Show print option dialog
          if (mounted) {
            final shouldPrint = await _showPrintDialog();
            if (shouldPrint == true) {
              await _printReturnReceipt();
            }

            if (mounted) {
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Return berhasil: ${requestBody['returnNumber']}',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } else {
          throw Exception(data['message'] ?? 'Gagal membuat return');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(
          data['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool?> _showPrintDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('✅ Return Berhasil'),
            content: const Text('Apakah Anda ingin mencetak nota return?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tidak'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.print),
                label: const Text('Cetak Nota'),
              ),
            ],
          ),
    );
  }

  Future<void> _printReturnReceipt() async {
    if (_createdReturn == null || _selectedSale == null) return;

    try {
      final pdf = await _generateReturnPDF();
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print('❌ Print error: $e');
      _showError('Gagal mencetak: $e');
    }
  }

  Future<pw.Document> _generateReturnPDF() async {
    final pdf = pw.Document();
    final authBox = HiveService.instance.getBox('auth');
    final branch = authBox.get('branch');

    // Calculate totals
    final returnItems = <Map<String, dynamic>>[];
    double subtotal = 0;

    for (var item in _selectedSale!.items) {
      final returnQty = _returnQuantities[item.product.id] ?? 0;
      if (returnQty > 0) {
        final itemTotal = item.product.price * returnQty;
        subtotal += itemTotal;
        returnItems.add({
          'name': item.product.name,
          'qty': returnQty,
          'price': item.product.price,
          'total': itemTotal,
        });
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      branch?['name'] ?? 'POS System',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      branch?['address'] ?? '',
                      style: const pw.TextStyle(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Telp: ${branch?['phone'] ?? '-'}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),

              // Return Info
              pw.Center(
                child: pw.Text(
                  'NOTA RETUR PENJUALAN',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              _buildInfoRow(
                'No. Retur',
                _createdReturn?['return_number'] ?? '-',
              ),
              _buildInfoRow('Tgl Retur', _formatDate(DateTime.now())),
              pw.Divider(),

              // Original Sale Info
              pw.Text(
                'TRANSAKSI ASAL:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              _buildInfoRow('No. Invoice', _selectedSale!.invoiceNumber),
              _buildInfoRow(
                'Tgl Transaksi',
                _formatDate(_selectedSale!.transactionDate),
              ),
              _buildInfoRow('Kasir', _selectedSale!.cashierName),
              if (_selectedSale!.customerName != null)
                _buildInfoRow('Customer', _selectedSale!.customerName!),
              pw.Divider(),

              // Return Items
              pw.Text(
                'BARANG DIRETUR:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),

              // Items table
              ...returnItems.map(
                (item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item['name'],
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${item['qty']} x ${_formatCurrency(item['price'])}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          _formatCurrency(item['total']),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                  ],
                ),
              ),

              pw.Divider(),

              // Totals
              _buildTotalRow('Subtotal', subtotal),
              _buildTotalRow('Discount', _selectedSale!.discount),
              _buildTotalRow('Tax', _selectedSale!.tax),
              pw.Divider(thickness: 2),
              _buildTotalRow(
                'TOTAL REFUND',
                _calculateTotalRefund(),
                bold: true,
                fontSize: 12,
              ),
              pw.Divider(),

              // Payment Info
              _buildInfoRow(
                'Metode Refund',
                _getRefundMethodName(_selectedRefundMethod),
              ),
              _buildInfoRow('Alasan', _reasonController.text.trim()),

              pw.SizedBox(height: 15),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Terima kasih',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      _formatDate(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTotalRow(
    String label,
    double amount, {
    bool bold = false,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            _formatCurrency(amount),
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRefundMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'credit':
        return 'Kredit Toko';
      default:
        return method;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Compact Header
            Row(
              children: [
                const Icon(Icons.assignment_return, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Return Penjualan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 16),

            // Content - Return Details Only (no sale selection needed)
            Expanded(child: _buildReturnDetails()),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sale Info (Compact)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedSale!.invoiceNumber,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDate(_selectedSale!.transactionDate)} • ${_selectedSale!.cashierName}',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(_selectedSale!.total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Items (Compact Table)
        const Text(
          'Item Return:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),

        Expanded(
          child: ListView.builder(
            itemCount: _selectedSale!.items.length,
            itemBuilder: (context, index) {
              final item = _selectedSale!.items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Price & details
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Harga: ${CurrencyFormatter.format(item.product.price)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (item.discount > 0)
                                Text(
                                  'Diskon: ${item.discount.toStringAsFixed(1)}% (-${CurrencyFormatter.format(item.discountAmount)})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                  ),
                                ),
                              if (item.taxPercent > 0)
                                Text(
                                  'PPN: ${item.taxPercent.toStringAsFixed(1)}% (+${CurrencyFormatter.format(item.taxAmount)})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Return quantity input
                        SizedBox(
                          width: 70,
                          height: 32,
                          child: TextField(
                            controller: _quantityControllers[item.product.id],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              border: const OutlineInputBorder(),
                              suffixText: '/${item.quantity}',
                              suffixStyle: const TextStyle(fontSize: 10),
                            ),
                            onChanged:
                                (value) => _updateReturnQuantity(
                                  item.product.id,
                                  item.quantity.toDouble(),
                                  value,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Return total
                        SizedBox(
                          width: 85,
                          child: Text(
                            CurrencyFormatter.format(
                              item.total /
                                  item.quantity *
                                  (_returnQuantities[item.product.id] ?? 0),
                            ),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Reason & Method (Compact)
        TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Alasan Return *',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.all(10),
          ),
          style: const TextStyle(fontSize: 12),
          maxLines: 2,
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Text('Refund: ', style: TextStyle(fontSize: 12)),
            DropdownButton<String>(
              value: _selectedRefundMethod,
              isDense: true,
              style: const TextStyle(fontSize: 12, color: Colors.black),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                DropdownMenuItem(value: 'credit', child: Text('Kredit')),
              ],
              onChanged: (value) {
                setState(() => _selectedRefundMethod = value ?? 'cash');
              },
            ),
          ],
        ),

        const Divider(height: 16),

        // Action (Compact)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Refund',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    CurrencyFormatter.format(_calculateTotalRefund()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Text(
                    '(Sudah termasuk diskon & PPN)',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processReturn,
              icon:
                  _isProcessing
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.check, size: 18),
              label: Text(
                _isProcessing ? 'Proses...' : 'Proses Return',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
