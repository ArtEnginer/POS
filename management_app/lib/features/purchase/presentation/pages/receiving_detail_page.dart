import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../injection_container.dart';
import '../../../receiving/presentation/bloc/receiving_bloc.dart';
import '../../../receiving/presentation/bloc/receiving_event.dart';
import '../../../receiving/presentation/bloc/receiving_state.dart';
import '../bloc/purchase_return_bloc.dart';
import '../../../receiving/domain/entities/receiving.dart';
import 'purchase_return_form_page.dart';

class ReceivingDetailPage extends StatefulWidget {
  final String receivingId;

  const ReceivingDetailPage({Key? key, required this.receivingId})
    : super(key: key);

  @override
  State<ReceivingDetailPage> createState() => _ReceivingDetailPageState();
}

class _ReceivingDetailPageState extends State<ReceivingDetailPage> {
  @override
  void initState() {
    super.initState();
    // Load receiving - check if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<ReceivingBloc>().state;
      if (currentState is! ReceivingDetailLoaded) {
        _loadReceiving();
      }
    });
  }

  void _loadReceiving() {
    context.read<ReceivingBloc>().add(LoadReceivingById(widget.receivingId));
  }

  double _calculateItemDiscount(ReceivingItem item) {
    if (item.discountType == 'PERCENTAGE') {
      return item.subtotal * (item.discount / 100);
    }
    return item.discount;
  }

  double _calculateItemTax(ReceivingItem item) {
    final afterDiscount = item.subtotal - _calculateItemDiscount(item);
    if (item.taxType == 'PERCENTAGE') {
      return afterDiscount * (item.tax / 100);
    }
    return item.tax;
  }

  void _navigateToReturnForm(BuildContext context, Receiving receiving) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MultiBlocProvider(
              providers: [
                BlocProvider<ReceivingBloc>(
                  create: (context) => sl<ReceivingBloc>(),
                ),
                BlocProvider<PurchaseReturnBloc>(
                  create: (context) => sl<PurchaseReturnBloc>(),
                ),
              ],
              child: PurchaseReturnFormPage(receivingId: receiving.id),
            ),
      ),
    );
  }

  Future<void> _printReceiving(Receiving receiving) async {
    final pdf = await _generatePdf(receiving);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<pw.Document> _generatePdf(Receiving receiving) async {
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
                    'BUKTI PENERIMAAN BARANG',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    receiving.receivingNumber,
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Nomor PO', receiving.purchaseNumber),
                      _buildInfoRow(
                        'Supplier',
                        receiving.supplierName ?? 'N/A',
                      ),
                      _buildInfoRow('Status', receiving.status),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Tanggal Penerimaan',
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(receiving.receivingDate),
                      ),
                      _buildInfoRow(
                        'Diterima Oleh',
                        receiving.receivedBy ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

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
                    _buildTableCell('Produk', isHeader: true),
                    _buildTableCell('Qty PO', isHeader: true),
                    _buildTableCell('Qty Terima', isHeader: true),
                    _buildTableCell('Harga', isHeader: true),
                    _buildTableCell('Diskon', isHeader: true),
                    _buildTableCell('PPN', isHeader: true),
                    _buildTableCell('Total', isHeader: true),
                  ],
                ),
                // Items
                ...receiving.items.asMap().entries.map((entry) {
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
                      _buildTableCell((index + 1).toString()),
                      _buildTableCell(item.productName),
                      _buildTableCell(
                        item.poQuantity.toString(),
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        item.receivedQuantity.toString(),
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(item.receivedPrice),
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
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 250,
                child: pw.Column(
                  children: [
                    _buildSummaryRow('Subtotal', receiving.subtotal),
                    if (receiving.itemDiscount > 0)
                      _buildSummaryRow('Diskon Item', -receiving.itemDiscount),
                    if (receiving.totalDiscount > 0)
                      _buildSummaryRow(
                        'Diskon Total',
                        -receiving.totalDiscount,
                      ),
                    if (receiving.itemTax > 0)
                      _buildSummaryRow('Pajak Item', receiving.itemTax),
                    if (receiving.totalTax > 0)
                      _buildSummaryRow('Pajak Total', receiving.totalTax),
                    pw.Divider(thickness: 2),
                    _buildSummaryRow('TOTAL', receiving.total, isBold: true),
                  ],
                ),
              ),
            ),

            if (receiving.notes != null && receiving.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text(
                'Catatan:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(receiving.notes!),
            ],

            pw.SizedBox(height: 48),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSignatureBox('Diterima Oleh'),
                _buildSignatureBox('Disetujui Oleh'),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': '),
          pw.Expanded(child: pw.Text(value)),
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
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
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
          pw.Text(label),
          pw.SizedBox(height: 60),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
            ),
            width: 150,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'DRAFT':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penerimaan Barang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceiving,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<ReceivingBloc, ReceivingState>(
        builder: (context, state) {
          if (state is ReceivingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReceivingDetailLoaded) {
            final receiving = state.receiving;

            // Debug: Print items count
            debugPrint(
              'Receiving Detail - Items count: ${receiving.items.length}',
            );
            for (var item in receiving.items) {
              debugPrint(
                '  - ${item.productName}: Qty ${item.receivedQuantity}',
              );
            }

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
                                        'Nomor Receiving',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        receiving.receivingNumber,
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
                                      receiving.status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStatusColor(receiving.status),
                                    ),
                                  ),
                                  child: Text(
                                    receiving.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(receiving.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoItem(
                              'Nomor PO',
                              receiving.purchaseNumber,
                            ),
                            _buildInfoItem(
                              'Supplier',
                              receiving.supplierName ?? 'N/A',
                            ),
                            _buildInfoItem(
                              'Tanggal Penerimaan',
                              DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(receiving.receivingDate),
                            ),
                            _buildInfoItem(
                              'Diterima Oleh',
                              receiving.receivedBy ?? 'N/A',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detail Penerimaan Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Detail Pengiriman',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            _buildInfoItem(
                              'Nomor Faktur',
                              receiving.invoiceNumber ?? '-',
                              icon: Icons.numbers,
                            ),
                            _buildInfoItem(
                              'No. Surat Jalan',
                              receiving.deliveryOrderNumber ?? '-',
                              icon: Icons.local_shipping,
                            ),
                            _buildInfoItem(
                              'Nomor Kendaraan',
                              receiving.vehicleNumber ?? '-',
                              icon: Icons.directions_car,
                            ),
                            _buildInfoItem(
                              'Nama Sopir',
                              receiving.driverName ?? '-',
                              icon: Icons.person,
                            ),
                            if (receiving.notes != null &&
                                receiving.notes!.isNotEmpty) ...[
                              const Divider(height: 20),
                              _buildInfoItem(
                                'Catatan',
                                receiving.notes!,
                                icon: Icons.note,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items Section
                    const Text(
                      'Item yang Diterima',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...receiving.items.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Qty PO',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        item.poQuantity.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Qty Terima',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        item.receivedQuantity.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Harga',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'id_ID',
                                          symbol: 'Rp ',
                                          decimalDigits: 0,
                                        ).format(item.receivedPrice),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                              if (item.notes != null &&
                                  item.notes!.isNotEmpty) ...[
                                const Divider(height: 24),
                                Text(
                                  'Catatan: ${item.notes}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 16),

                    // Summary Card
                    Card(
                      elevation: 2,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildSummaryItem('Subtotal', receiving.subtotal),
                            if (receiving.itemDiscount > 0)
                              _buildSummaryItem(
                                'Diskon Item',
                                -receiving.itemDiscount,
                                color: Colors.red,
                              ),
                            if (receiving.totalDiscount > 0)
                              _buildSummaryItem(
                                'Diskon Total',
                                -receiving.totalDiscount,
                                color: Colors.red,
                              ),
                            if (receiving.itemTax > 0)
                              _buildSummaryItem(
                                'Pajak Item',
                                receiving.itemTax,
                              ),
                            if (receiving.totalTax > 0)
                              _buildSummaryItem(
                                'Pajak Total',
                                receiving.totalTax,
                              ),
                            const Divider(height: 24),
                            _buildSummaryItem(
                              'TOTAL',
                              receiving.total,
                              isBold: true,
                              fontSize: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Print Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _printReceiving(receiving),
                        icon: const Icon(Icons.print),
                        label: const Text('Print Bukti Penerimaan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    // Return Button - Only show if status is COMPLETED
                    if (receiving.status == 'COMPLETED') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              () => _navigateToReturnForm(context, receiving),
                          icon: const Icon(Icons.assignment_return),
                          label: const Text('Buat Return Pembelian'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          if (state is ReceivingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReceiving,
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

  Widget _buildInfoItem(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: icon != null ? 120 : 140,
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

  Widget _buildSummaryItem(
    String label,
    double value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(value),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
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
