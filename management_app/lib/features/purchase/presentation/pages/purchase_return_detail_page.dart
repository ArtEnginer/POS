import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../bloc/purchase_return_bloc.dart';
import '../bloc/purchase_return_event.dart' as events;
import '../bloc/purchase_return_state.dart';
import '../../domain/entities/purchase_return.dart';

class PurchaseReturnDetailPage extends StatefulWidget {
  final String returnId;

  const PurchaseReturnDetailPage({Key? key, required this.returnId})
    : super(key: key);

  @override
  State<PurchaseReturnDetailPage> createState() =>
      _PurchaseReturnDetailPageState();
}

class _PurchaseReturnDetailPageState extends State<PurchaseReturnDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<PurchaseReturnBloc>().state;
      if (currentState is! PurchaseReturnDetailLoaded) {
        _loadReturn();
      }
    });
  }

  void _loadReturn() {
    context.read<PurchaseReturnBloc>().add(
      events.LoadPurchaseReturnById(widget.returnId),
    );
  }

  double _calculateItemDiscount(PurchaseReturnItem item) {
    if (item.discountType == 'PERCENTAGE') {
      return item.subtotal * (item.discount / 100);
    }
    return item.discount;
  }

  double _calculateItemTax(PurchaseReturnItem item) {
    final afterDiscount = item.subtotal - _calculateItemDiscount(item);
    if (item.taxType == 'PERCENTAGE') {
      return afterDiscount * (item.tax / 100);
    }
    return item.tax;
  }

  Future<void> _printReturn(PurchaseReturn returnData) async {
    final pdf = await _generatePdf(returnData);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<pw.Document> _generatePdf(PurchaseReturn returnData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Text(
                    'BUKTI RETURN PEMBELIAN',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    returnData.returnNumber,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Return Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfInfoRow(
                      'Nomor Receiving',
                      returnData.receivingNumber,
                    ),
                    _buildPdfInfoRow('Nomor PO', returnData.purchaseNumber),
                    _buildPdfInfoRow(
                      'Supplier',
                      returnData.supplierName ?? 'N/A',
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfInfoRow(
                      'Tanggal Return',
                      DateFormat(
                        'dd MMMM yyyy',
                        'id_ID',
                      ).format(returnData.returnDate),
                    ),
                    _buildPdfInfoRow('Status', returnData.status),
                    if (returnData.processedBy != null &&
                        returnData.processedBy!.isNotEmpty)
                      _buildPdfInfoRow(
                        'Diproses Oleh',
                        returnData.processedBy!,
                      ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Reason Box
            if (returnData.reason != null && returnData.reason!.isNotEmpty)
              // Items Table Header
              pw.Text(
                'Detail Barang yang Di-return',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            pw.SizedBox(height: 8),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1),
                6: const pw.FlexColumnWidth(1),
                7: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('No', isHeader: true),
                    _buildTableCell('Nama Barang', isHeader: true),
                    _buildTableCell(
                      'Qty Diterima',
                      isHeader: true,
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      'Qty Return',
                      isHeader: true,
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      'Harga',
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _buildTableCell(
                      'Diskon',
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _buildTableCell(
                      'PPN',
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _buildTableCell(
                      'Total',
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                // Items
                ...returnData.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  // Calculate discount and tax
                  double discount = 0;
                  if (item.discount > 0) {
                    if (item.discountType == 'PERCENTAGE') {
                      discount = item.subtotal * (item.discount / 100);
                    } else {
                      discount = item.discount;
                    }
                  }

                  double tax = 0;
                  if (item.tax > 0) {
                    final afterDiscount = item.subtotal - discount;
                    if (item.taxType == 'PERCENTAGE') {
                      tax = afterDiscount * (item.tax / 100);
                    } else {
                      tax = item.tax;
                    }
                  }

                  return pw.TableRow(
                    children: [
                      _buildTableCell('${index + 1}'),
                      _buildTableCell(item.productName),
                      _buildTableCell(
                        '${item.receivedQuantity}',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        '${item.returnQuantity}',
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(item.price),
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        discount > 0
                            ? NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(discount)
                            : '-',
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        tax > 0
                            ? NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(tax)
                            : '-',
                        align: pw.TextAlign.right,
                      ),
                      _buildTableCell(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(item.total),
                        align: pw.TextAlign.right,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 16),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    children: [
                      _buildSummaryRow('Subtotal', returnData.subtotal),
                      if (returnData.itemDiscount > 0)
                        _buildSummaryRow(
                          'Diskon Item',
                          -returnData.itemDiscount,
                        ),
                      if (returnData.totalDiscount > 0)
                        _buildSummaryRow(
                          'Diskon Total',
                          -returnData.totalDiscount,
                        ),
                      if (returnData.itemTax > 0)
                        _buildSummaryRow('Pajak Item', returnData.itemTax),
                      if (returnData.totalTax > 0)
                        _buildSummaryRow('Pajak Total', returnData.totalTax),
                      pw.Divider(thickness: 2),
                      _buildSummaryRow(
                        'Total Return',
                        returnData.total,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Notes
            if (returnData.notes != null && returnData.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'Catatan:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(returnData.notes!),
            ],

            pw.SizedBox(height: 40),

            // Signature Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSignatureBox('Diterima Oleh'),
                _buildSignatureBox('Disetujui Oleh'),
                _buildSignatureBox('Supplier'),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Text(
              'Dicetak pada: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          ),
          pw.Text(': '),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildSummaryRow(
    String label,
    double value, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isBold ? 12 : 10,
            ),
          ),
          pw.Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(value),
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isBold ? 12 : 10,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureBox(String label) {
    return pw.Container(
      width: 150,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 60),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
            ),
            width: 150,
            child: pw.SizedBox(height: 1),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Return Pembelian'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReturn,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<PurchaseReturnBloc, PurchaseReturnState>(
        builder: (context, state) {
          if (state is PurchaseReturnLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PurchaseReturnDetailLoaded) {
            final returnData = state.purchaseReturn;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Nomor Return',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        returnData.returnNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      returnData.status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStatusColor(returnData.status),
                                    ),
                                  ),
                                  child: Text(
                                    returnData.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(returnData.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoItem(
                              'Nomor Receiving',
                              returnData.receivingNumber,
                            ),
                            _buildInfoItem(
                              'Nomor PO',
                              returnData.purchaseNumber,
                            ),
                            _buildInfoItem(
                              'Supplier',
                              returnData.supplierName ?? 'N/A',
                            ),
                            _buildInfoItem(
                              'Tanggal Return',
                              DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(returnData.returnDate),
                            ),
                            if (returnData.processedBy != null &&
                                returnData.processedBy!.isNotEmpty)
                              _buildInfoItem(
                                'Diproses Oleh',
                                returnData.processedBy!,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason Card
                    if (returnData.reason != null &&
                        returnData.reason!.isNotEmpty)
                      Card(
                        color: Colors.orange.shade50,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Alasan Return',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                returnData.reason!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Items Section
                    const Text(
                      'Barang yang Di-return',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...returnData.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    radius: 16,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Qty Diterima',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.receivedQuantity}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: Colors.orange.shade700,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Qty Return',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.returnQuantity}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Harga',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              NumberFormat.currency(
                                                locale: 'id_ID',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(item.price),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Item calculation detail
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildItemDetailRow(
                                      'Subtotal',
                                      item.subtotal,
                                    ),
                                    if (item.discount > 0) ...[
                                      const SizedBox(height: 4),
                                      _buildItemDetailRow(
                                        'Diskon ${item.discountType == "PERCENTAGE" ? "(${item.discount}%)" : ""}',
                                        -_calculateItemDiscount(item),
                                        color: Colors.red,
                                      ),
                                    ],
                                    if (item.tax > 0) ...[
                                      const SizedBox(height: 4),
                                      _buildItemDetailRow(
                                        'PPN ${item.taxType == "PERCENTAGE" ? "(${item.tax}%)" : ""}',
                                        _calculateItemTax(item),
                                        color: Colors.green,
                                      ),
                                    ],
                                    const Divider(height: 16),
                                    _buildItemDetailRow(
                                      'Total',
                                      item.total,
                                      isBold: true,
                                      color: Colors.orange.shade700,
                                    ),
                                  ],
                                ),
                              ),
                              if (item.reason != null &&
                                  item.reason!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Alasan: ${item.reason}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Summary Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 16),
                            _buildSummaryRowWidget(
                              'Subtotal',
                              returnData.subtotal,
                            ),
                            if (returnData.itemDiscount > 0)
                              _buildSummaryRowWidget(
                                'Diskon Item',
                                -returnData.itemDiscount,
                              ),
                            if (returnData.totalDiscount > 0)
                              _buildSummaryRowWidget(
                                'Diskon Total',
                                -returnData.totalDiscount,
                              ),
                            if (returnData.itemTax > 0)
                              _buildSummaryRowWidget(
                                'Pajak Item',
                                returnData.itemTax,
                              ),
                            if (returnData.totalTax > 0)
                              _buildSummaryRowWidget(
                                'Pajak Total',
                                returnData.totalTax,
                              ),
                            const Divider(height: 24),
                            _buildSummaryRowWidget(
                              'TOTAL RETURN',
                              returnData.total,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Notes Card
                    if (returnData.notes != null &&
                        returnData.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Catatan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(returnData.notes!),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Print Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _printReturn(returnData),
                        icon: const Icon(Icons.print),
                        label: const Text('Print Bukti Return'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is PurchaseReturnError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReturn,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Tidak ada data'));
        },
      ),
    );
  }

  Widget _buildSummaryRowWidget(
    String label,
    double value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(value),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.orange : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailRow(
    String label,
    double value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.grey.shade700,
          ),
        ),
        Text(
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(value.abs()),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
