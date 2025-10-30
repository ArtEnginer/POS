import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/sale_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/database/hive_service.dart';

class PrintOptionsDialog extends StatelessWidget {
  final SaleModel sale;

  const PrintOptionsDialog({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Format Cetak'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.receipt, color: Colors.blue),
            title: const Text('Nota (Thermal 80mm)'),
            subtitle: const Text('Format struk kasir'),
            onTap: () {
              Navigator.pop(context);
              _printReceipt(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.green),
            title: const Text('Invoice (A4)'),
            subtitle: const Text('Format invoice resmi'),
            onTap: () {
              Navigator.pop(context);
              _printInvoice(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_shipping, color: Colors.orange),
            title: const Text('Surat Jalan (A4)'),
            subtitle: const Text('Untuk pengiriman barang'),
            onTap: () {
              Navigator.pop(context);
              _printDeliveryNote(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      final pdf = await _generateReceipt();
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      final pdf = await _generateInvoice();
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printDeliveryNote(BuildContext context) async {
    try {
      final pdf = await _generateDeliveryNote();
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================
  // THERMAL RECEIPT 80mm
  // ============================================
  Future<pw.Document> _generateReceipt() async {
    final pdf = pw.Document();
    final authBox = HiveService.instance.getBox('auth');
    final branch = authBox.get('branch');

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
                    pw.Text(
                      'Telp: ${branch?['phone'] ?? '-'}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),

              // Transaction Info
              _buildInfoRow('No. Invoice', sale.invoiceNumber),
              _buildInfoRow('Tanggal', _formatDateTime(sale.transactionDate)),
              _buildInfoRow('Kasir', sale.cashierName),
              if (sale.customerName != null)
                _buildInfoRow('Customer', sale.customerName!),
              pw.Divider(),

              // Items
              pw.Text(
                'ITEMS:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),

              ...sale.items.map((item) {
                // Find returns for this specific item
                final itemReturns =
                    sale.returns
                        .expand((ret) => ret.items)
                        .where(
                          (retItem) => retItem.productId == item.product.id,
                        )
                        .toList();

                final totalReturnQty = itemReturns.fold<double>(
                  0.0,
                  (sum, retItem) => sum + retItem.quantity,
                );

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Item name
                    pw.Text(
                      item.product.name,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    // Item quantity x price = total
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${item.quantity} x ${_formatCurrency(item.product.price)}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          _formatCurrency(item.product.price * item.quantity),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Show returns for this item
                    if (itemReturns.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      ...itemReturns.map(
                        (retItem) => pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '  Retur: -${retItem.quantity} x ${_formatCurrency(retItem.unitPrice)}',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.red,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                            pw.Text(
                              '-${_formatCurrency(retItem.subtotal)}',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.red,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      // Net for this item
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '  Net: ${item.quantity - totalReturnQty}',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            _formatCurrency(
                              (item.product.price * item.quantity) -
                                  itemReturns.fold<double>(
                                    0.0,
                                    (sum, r) => sum + r.subtotal,
                                  ),
                            ),
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    pw.SizedBox(height: 3),
                  ],
                );
              }),

              pw.Divider(),

              // Totals
              _buildTotalRow('Subtotal', sale.subtotal),
              if (sale.discount > 0) _buildTotalRow('Diskon', -sale.discount),
              if (sale.tax > 0) _buildTotalRow('Pajak', sale.tax),
              pw.Divider(thickness: 2),
              _buildTotalRow('TOTAL', sale.total, bold: true, fontSize: 12),

              // Returns (if any)
              if (sale.hasReturns) ...[
                pw.SizedBox(height: 5),
                _buildTotalRow(
                  'Retur',
                  -sale.returns.fold<double>(
                    0.0,
                    (sum, ret) => sum + ret.refundAmount,
                  ),
                ),
                pw.Divider(),
                _buildTotalRow(
                  'NET TOTAL',
                  sale.netTotal,
                  bold: true,
                  fontSize: 12,
                ),
              ],

              pw.Divider(),
              _buildTotalRow('Bayar', sale.paid),
              if (sale.change > 0) _buildTotalRow('Kembali', sale.change),

              pw.SizedBox(height: 15),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Terima kasih atas kunjungan Anda',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      _formatDateTime(DateTime.now()),
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

  // ============================================
  // INVOICE A4
  // ============================================
  Future<pw.Document> _generateInvoice() async {
    final pdf = pw.Document();
    final authBox = HiveService.instance.getBox('auth');
    final branch = authBox.get('branch');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        branch?['name'] ?? 'POS System',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(branch?['address'] ?? ''),
                      pw.Text('Telp: ${branch?['phone'] ?? '-'}'),
                      pw.Text('Email: ${branch?['email'] ?? '-'}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('No: ${sale.invoiceNumber}'),
                      pw.Text('Tanggal: ${_formatDate(sale.transactionDate)}'),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Bill To
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'KEPADA:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(sale.customerName ?? 'Walk-in Customer'),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell('No', bold: true),
                      _buildTableCell('Nama Produk', bold: true),
                      _buildTableCell(
                        'Qty',
                        bold: true,
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        'Harga',
                        bold: true,
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        'Total',
                        bold: true,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                  // Items with returns
                  ...sale.items.asMap().entries.expand((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    // Find returns for this item
                    final itemReturns =
                        sale.returns
                            .expand((ret) => ret.items)
                            .where(
                              (retItem) => retItem.productId == item.product.id,
                            )
                            .toList();

                    final totalReturnQty = itemReturns.fold<double>(
                      0.0,
                      (sum, retItem) => sum + retItem.quantity,
                    );
                    final totalReturnAmount = itemReturns.fold<double>(
                      0.0,
                      (sum, retItem) => sum + retItem.subtotal,
                    );

                    final rows = <pw.TableRow>[];

                    // Main item row
                    rows.add(
                      pw.TableRow(
                        children: [
                          _buildTableCell((idx + 1).toString()),
                          _buildTableCell(item.product.name),
                          _buildTableCell(
                            item.quantity.toString(),
                            align: pw.TextAlign.center,
                          ),
                          _buildTableCell(
                            _formatCurrency(item.product.price),
                            align: pw.TextAlign.right,
                          ),
                          _buildTableCell(
                            _formatCurrency(item.product.price * item.quantity),
                            align: pw.TextAlign.right,
                          ),
                        ],
                      ),
                    );

                    // Return rows for this item
                    if (itemReturns.isNotEmpty) {
                      for (var retItem in itemReturns) {
                        rows.add(
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.red50,
                            ),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(''),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  '  ↪ Retur',
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.red,
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  '-${retItem.quantity}',
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.red,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  _formatCurrency(retItem.unitPrice),
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.red,
                                  ),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  '-${_formatCurrency(retItem.subtotal)}',
                                  style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.red,
                                  ),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Net row
                      rows.add(
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(''),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                '  Net',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                '${item.quantity - totalReturnQty}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(''),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                _formatCurrency(
                                  (item.product.price * item.quantity) -
                                      totalReturnAmount,
                                ),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return rows;
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      children: [
                        _buildInvoiceTotalRow('Subtotal', sale.subtotal),
                        if (sale.discount > 0)
                          _buildInvoiceTotalRow('Diskon', -sale.discount),
                        if (sale.tax > 0)
                          _buildInvoiceTotalRow('Pajak', sale.tax),
                        pw.Divider(thickness: 2),
                        _buildInvoiceTotalRow(
                          'TOTAL',
                          sale.total,
                          bold: true,
                          fontSize: 16,
                        ),

                        // Returns (if any)
                        if (sale.hasReturns) ...[
                          pw.SizedBox(height: 5),
                          _buildInvoiceTotalRow(
                            'Retur',
                            -sale.returns.fold<double>(
                              0.0,
                              (sum, ret) => sum + ret.refundAmount,
                            ),
                          ),
                          pw.Divider(),
                          _buildInvoiceTotalRow(
                            'NET TOTAL',
                            sale.netTotal,
                            bold: true,
                            fontSize: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Metode Pembayaran: ${sale.paymentMethod}'),
                      pw.Text('Kasir: ${sale.cashierName}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(color: PdfColors.black),
                          ),
                        ),
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Center(
                          child: pw.Text('Tanda Tangan & Stempel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ============================================
  // DELIVERY NOTE A4
  // ============================================
  Future<pw.Document> _generateDeliveryNote() async {
    final pdf = pw.Document();
    final authBox = HiveService.instance.getBox('auth');
    final branch = authBox.get('branch');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
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
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(branch?['address'] ?? ''),
                    pw.Text('Telp: ${branch?['phone'] ?? '-'}'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Center(
                child: pw.Text(
                  'SURAT JALAN',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              // Document Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('No. Surat Jalan: ${sale.invoiceNumber}'),
                      pw.Text('Tanggal: ${_formatDate(sale.transactionDate)}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [pw.Text('Ref. Invoice: ${sale.invoiceNumber}')],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Sender & Receiver
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PENGIRIM:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(branch?['name'] ?? ''),
                          pw.Text(branch?['address'] ?? ''),
                          pw.Text('Telp: ${branch?['phone'] ?? ''}'),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PENERIMA:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(sale.customerName ?? 'Walk-in Customer'),
                          pw.SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell('No', bold: true),
                      _buildTableCell('Nama Produk', bold: true),
                      _buildTableCell(
                        'Qty',
                        bold: true,
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell('Satuan', bold: true),
                      _buildTableCell('Keterangan', bold: true),
                    ],
                  ),
                  // Items
                  ...sale.items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell((idx + 1).toString()),
                        _buildTableCell(item.product.name),
                        _buildTableCell(
                          item.quantity.toString(),
                          align: pw.TextAlign.center,
                        ),
                        _buildTableCell('PCS'),
                        _buildTableCell(''),
                      ],
                    );
                  }),
                ],
              ),

              pw.Spacer(),

              // Signatures
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureBox('Pengirim'),
                  _buildSignatureBox('Penerima'),
                  _buildSignatureBox('Sopir'),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Text(
                'Catatan: Barang yang sudah dikirim tidak dapat dikembalikan kecuali ada kesalahan dari pihak kami.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Helper methods
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

  pw.Widget _buildInvoiceTotalRow(
    String label,
    double amount, {
    bool bold = false,
    double fontSize = 12,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
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

  pw.Widget _buildTableCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildSignatureBox(String title) {
    return pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 50),
        pw.Container(
          width: 120,
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide()),
          ),
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Center(
            child: pw.Text(
              '( ........................... )',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
