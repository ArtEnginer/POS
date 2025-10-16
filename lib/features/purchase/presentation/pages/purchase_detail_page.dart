import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../bloc/purchase_bloc.dart';
import '../bloc/purchase_event.dart';
import '../bloc/purchase_state.dart';
import '../../domain/entities/purchase.dart';

class PurchaseDetailPage extends StatelessWidget {
  final String purchaseId;

  const PurchaseDetailPage({super.key, required this.purchaseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PurchaseBloc>()..add(LoadPurchaseById(purchaseId)),
      child: const _PurchaseDetailView(),
    );
  }
}

class _PurchaseDetailView extends StatelessWidget {
  const _PurchaseDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembelian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implement print functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print feature - Coming Soon')),
              );
            },
            tooltip: 'Cetak',
          ),
        ],
      ),
      body: BlocBuilder<PurchaseBloc, PurchaseState>(
        builder: (context, state) {
          if (state is PurchaseLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PurchaseDetailLoaded) {
            return _buildDetailContent(context, state.purchase);
          } else if (state is PurchaseError) {
            return _buildErrorState(context, state.message);
          }
          return const Center(child: Text('Memuat data...'));
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, Purchase purchase) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(purchase),
          const SizedBox(height: 16),
          _buildInfoCards(context, purchase),
          const SizedBox(height: 16),
          _buildItemsSection(purchase),
          const SizedBox(height: 16),
          _buildSummarySection(purchase),
          const SizedBox(height: 16),
          if (purchase.notes != null) _buildNotesSection(purchase),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildHeader(Purchase purchase) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nomor Pembelian',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    purchase.purchaseNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _buildStatusChip(purchase.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                DateFormat(
                  'EEEE, dd MMMM yyyy',
                  'id_ID',
                ).format(purchase.purchaseDate),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'RECEIVED':
        color = Colors.green;
        label = 'Received';
        break;
      case 'APPROVED':
        color = Colors.blue;
        label = 'Approved';
        break;
      case 'PENDING':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'DRAFT':
        color = Colors.grey;
        label = 'Draft';
        break;
      case 'CANCELLED':
        color = Colors.red;
        label = 'Batal';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context, Purchase purchase) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              icon: Icons.business,
              title: 'Supplier',
              value: purchase.supplierName ?? '-',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: Icons.payment,
              title: 'Pembayaran',
              value: _getPaymentMethodLabel(purchase.paymentMethod),
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'CASH':
        return '💵 Tunai';
      case 'TRANSFER':
        return '🏦 Transfer';
      case 'CREDIT':
        return '📝 Kredit';
      case 'CARD':
        return '💳 Kartu';
      case 'QRIS':
        return '📱 QRIS';
      default:
        return method;
    }
  }

  Widget _buildItemsSection(Purchase purchase) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    'Daftar Barang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text('${purchase.items.length} Item'),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: purchase.items.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = purchase.items[index];
                  return _buildItemRow(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(PurchaseItem item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.inventory_2, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${item.quantity} pcs',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('×', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Text(
                    currencyFormat.format(item.price),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(item.subtotal),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummarySection(Purchase purchase) {
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
                currencyFormat.format(purchase.subtotal),
              ),
              if (purchase.tax > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow('Pajak', currencyFormat.format(purchase.tax)),
              ],
              if (purchase.discount > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Diskon',
                  '- ${currencyFormat.format(purchase.discount)}',
                  color: Colors.red,
                ),
              ],
              const Divider(height: 24),
              _buildSummaryRow(
                'TOTAL',
                currencyFormat.format(purchase.total),
                isTotal: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      purchase.paidAmount >= purchase.total
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dibayar',
                      style: TextStyle(
                        color:
                            purchase.paidAmount >= purchase.total
                                ? Colors.green
                                : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currencyFormat.format(purchase.paidAmount),
                      style: TextStyle(
                        color:
                            purchase.paidAmount >= purchase.total
                                ? Colors.green
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (purchase.paidAmount < purchase.total) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sisa',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        currencyFormat.format(
                          purchase.total - purchase.paidAmount,
                        ),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color:
                color ?? (isTotal ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(Purchase purchase) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              Text(
                purchase.notes!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}
