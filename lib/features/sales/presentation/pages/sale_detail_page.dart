import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/sale.dart';
import '../bloc/sale_bloc.dart';
import '../bloc/sale_state.dart';

class SaleDetailPage extends StatelessWidget {
  const SaleDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printReceipt(context),
            tooltip: 'Cetak Struk',
          ),
        ],
      ),
      body: BlocBuilder<SaleBloc, SaleState>(
        builder: (context, state) {
          if (state is SaleLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SaleError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(state.message),
                ],
              ),
            );
          }

          if (state is SaleDetailLoaded) {
            return _buildContent(context, state.sale);
          }

          return const Center(child: Text('Memuat detail transaksi...'));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Sale sale) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderSection(sale),
          _buildItemsSection(sale),
          _buildSummarySection(sale),
          _buildPaymentSection(sale),
          if (sale.notes != null) _buildNotesSection(sale),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(Sale sale) {
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

    Color statusColor;
    String statusText;
    switch (sale.status) {
      case 'COMPLETED':
        statusColor = Colors.green;
        statusText = 'Selesai';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = 'Dibatalkan';
        break;
      case 'REFUNDED':
        statusColor = Colors.orange;
        statusText = 'Refund';
        break;
      default:
        statusColor = Colors.grey;
        statusText = sale.status;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            sale.saleNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateFormat.format(sale.saleDate),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(Sale sale) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Item Transaksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...sale.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currencyFormat.format(item.price)} x ${item.quantity}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormat.format(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(Sale sale) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: AppColors.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryRow(
                'Subtotal',
                currencyFormat.format(sale.subtotal),
              ),
              if (sale.tax > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow('Pajak', currencyFormat.format(sale.tax)),
              ],
              if (sale.discount > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Diskon',
                  '- ${currencyFormat.format(sale.discount)}',
                  color: Colors.red,
                ),
              ],
              const Divider(height: 24),
              _buildSummaryRow(
                'TOTAL',
                currencyFormat.format(sale.total),
                isTotal: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSection(Sale sale) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    String paymentMethodText;
    switch (sale.paymentMethod) {
      case 'CASH':
        paymentMethodText = 'Tunai';
        break;
      case 'CARD':
        paymentMethodText = 'Kartu Debit/Kredit';
        break;
      case 'QRIS':
        paymentMethodText = 'QRIS';
        break;
      case 'E_WALLET':
        paymentMethodText = 'E-Wallet';
        break;
      default:
        paymentMethodText = sale.paymentMethod;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payment, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Informasi Pembayaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow('Metode Pembayaran', paymentMethodText),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Jumlah Bayar',
                currencyFormat.format(sale.paymentAmount),
              ),
              if (sale.changeAmount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kembalian:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currencyFormat.format(sale.changeAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildInfoRow('Kasir', sale.cashierName),
              if (sale.customerId != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow('ID Pelanggan', sale.customerId!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection(Sale sale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.note_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Catatan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(sale.notes!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color:
                color ??
                (isTotal ? AppColors.textPrimary : AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: FontWeight.bold,
            color:
                color ?? (isTotal ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    final state = context.read<SaleBloc>().state;
    if (state is! SaleDetailLoaded) return;

    final sale = state.sale;

    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'SUPERPOS',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Jl. Contoh No. 123, Jakarta'),
                    pw.Text('Telp: 021-12345678'),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Transaction Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No. Transaksi:'),
                  pw.Text(
                    sale.saleNumber,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal:'),
                  pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Kasir:'), pw.Text(sale.cashierName)],
              ),
              if (sale.customerId != null) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ID Pelanggan:'),
                    pw.Text(sale.customerId!),
                  ],
                ),
              ],

              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Items
              ...sale.items.map((item) {
                return pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [pw.Expanded(child: pw.Text(item.productName))],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '  ${currencyFormat.format(item.price)} x ${item.quantity}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          currencyFormat.format(item.subtotal),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                  ],
                );
              }),

              pw.Divider(),
              pw.SizedBox(height: 8),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text(currencyFormat.format(sale.subtotal)),
                ],
              ),
              if (sale.tax > 0) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Pajak:'),
                    pw.Text(currencyFormat.format(sale.tax)),
                  ],
                ),
              ],
              if (sale.discount > 0) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diskon:'),
                    pw.Text('- ${currencyFormat.format(sale.discount)}'),
                  ],
                ),
              ],

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 8),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    currencyFormat.format(sale.total),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Payment
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pembayaran:'),
                  pw.Text(currencyFormat.format(sale.paymentAmount)),
                ],
              ),
              if (sale.changeAmount > 0) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Kembalian:'),
                    pw.Text(currencyFormat.format(sale.changeAmount)),
                  ],
                ),
              ],

              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Terima Kasih'),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Barang yang sudah dibeli tidak dapat ditukar/dikembalikan',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
