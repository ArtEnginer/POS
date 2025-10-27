import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart' as event;
import '../bloc/product_state.dart';
import 'product_form_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductBloc _productBloc;

  @override
  void initState() {
    super.initState();
    _productBloc =
        sl<ProductBloc>()..add(event.LoadProductById(widget.productId));
  }

  @override
  void dispose() {
    _productBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _productBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Produk'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          actions: [
            BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductDetailLoaded) {
                  return IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _navigateToEdit(context, state.product),
                    tooltip: 'Edit',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is ProductOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context, true);
            }
          },
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductDetailLoaded) {
              return _buildProductDetail(context, state.product);
            } else if (state is ProductError) {
              return _buildErrorState(context, state.message);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildProductDetail(BuildContext context, Product product) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: double.infinity,
            height: 300,
            color: AppColors.background,
            child:
                product.imageUrl != null
                    ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    )
                    : _buildImagePlaceholder(),
          ),
          // Product Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(product.name, style: AppTextStyles.h3),
                    ),
                    _buildSyncBadge(product.syncStatus),
                  ],
                ),
                const SizedBox(height: 8),
                // PLU
                Row(
                  children: [
                    const Icon(
                      Icons.tag,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SKU: ${product.sku}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Barcode
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.barcode,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (product.categoryName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.categoryName!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                // Price Card
                _buildInfoCard(
                  title: 'Harga',
                  children: [
                    _buildInfoRow(
                      'Harga Beli',
                      currencyFormat.format(product.costPrice),
                      valueColor: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Harga Jual',
                      currencyFormat.format(product.sellingPrice),
                      valueColor: AppColors.primary,
                      valueStyle: AppTextStyles.priceMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Keuntungan',
                      currencyFormat.format(product.profit),
                      valueColor: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Margin',
                      '${product.profitMargin.toStringAsFixed(1)}%',
                      valueColor: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stock Card
                _buildInfoCard(
                  title: 'Stok',
                  children: [
                    _buildInfoRow(
                      'Stok Tersedia',
                      '${product.stock} ${product.unit}',
                      valueColor:
                          product.isLowStock
                              ? AppColors.error
                              : AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Stok Minimum',
                      '${product.minStock} ${product.unit}',
                      valueColor: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Satuan',
                      product.unit,
                      valueColor: AppColors.textSecondary,
                    ),
                    if (product.isLowStock) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Stok produk rendah! Segera lakukan restock.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Additional Info Card
                if (product.description != null &&
                    product.description!.isNotEmpty)
                  _buildInfoCard(
                    title: 'Deskripsi',
                    children: [
                      Text(
                        product.description!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                // Metadata Card
                _buildInfoCard(
                  title: 'Informasi Sistem',
                  children: [
                    _buildInfoRow(
                      'ID Produk',
                      product.id,
                      valueColor: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Status',
                      product.isActive ? 'Aktif' : 'Nonaktif',
                      valueColor:
                          product.isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Dibuat',
                      dateFormat.format(product.createdAt),
                      valueColor: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Diupdate',
                      dateFormat.format(product.updatedAt),
                      valueColor: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteDialog(context, product),
                        icon: const Icon(Icons.delete),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToEdit(context, product),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 100,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h6.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style:
              valueStyle ??
              AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildSyncBadge(String syncStatus) {
    Color color;
    IconData icon;
    String label;

    switch (syncStatus.toUpperCase()) {
      case 'SYNCED':
        color = AppColors.synced;
        icon = Icons.check_circle;
        label = 'Tersinkronisasi';
        break;
      case 'PENDING':
        color = AppColors.syncPending;
        icon = Icons.sync;
        label = 'Menunggu Sinkronisasi';
        break;
      case 'FAILED':
        color = AppColors.syncFailed;
        icon = Icons.error;
        label = 'Gagal Sinkronisasi';
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.help;
        label = 'Tidak Diketahui';
    }

    return Tooltip(message: label, child: Icon(icon, size: 24, color: color));
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: AppTextStyles.h6.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context, Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(product: product),
      ),
    );

    if (result == true && context.mounted) {
      _productBloc.add(const event.LoadProducts());
    }
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Hapus Produk'),
            content: Text(
              'Apakah Anda yakin ingin menghapus produk "${product.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _productBloc.add(event.DeleteProduct(product.id));
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }
}
