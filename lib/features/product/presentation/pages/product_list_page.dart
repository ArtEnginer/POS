import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart' as event;
import '../bloc/product_state.dart';
import 'product_detail_page.dart';
import 'product_form_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  late final ProductBloc _productBloc;
  String _searchQuery = '';
  bool _showLowStock = false;

  @override
  void initState() {
    super.initState();
    _productBloc = sl<ProductBloc>()..add(const event.LoadProducts());
  }

  @override
  void dispose() {
    _productBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _productBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Produk'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          actions: [
            IconButton(
              icon: Icon(
                _showLowStock ? Icons.inventory : Icons.inventory_2_outlined,
                color: _showLowStock ? AppColors.warning : AppColors.textWhite,
              ),
              onPressed: () {
                setState(() {
                  _showLowStock = !_showLowStock;
                });
                if (_showLowStock) {
                  _productBloc.add(const event.LoadLowStockProducts());
                } else {
                  _productBloc.add(const event.LoadProducts());
                }
              },
              tooltip: _showLowStock ? 'Tampilkan Semua' : 'Stok Rendah',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _productBloc.add(const event.LoadProducts());
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _productBloc.add(const event.LoadProducts());
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  if (value.isEmpty) {
                    _productBloc.add(const event.LoadProducts());
                  } else {
                    _productBloc.add(event.SearchProducts(value));
                  }
                },
              ),
            ),
            // Product List
            Expanded(
              child: BlocConsumer<ProductBloc, ProductState>(
                listener: (context, state) {
                  if (state is ProductError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (state is ProductOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    // Reload products after operation
                    _productBloc.add(const event.LoadProducts());
                  }
                },
                builder: (context, state) {
                  if (state is ProductLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ProductLoaded) {
                    if (state.products.isEmpty) {
                      return _buildEmptyState();
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        _productBloc.add(const event.LoadProducts());
                      },
                      child: _buildProductTable(state.products),
                    );
                  } else if (state is ProductError) {
                    return _buildErrorState(state.message);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToForm(context, null),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Produk'),
        ),
      ),
    );
  }

  Widget _buildProductTable(List<Product> products) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.primary.withOpacity(0.1),
            ),
            columns: const [
              DataColumn(
                label: Text(
                  'PLU',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Barcode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Nama Produk',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Kategori',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Harga Beli',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Harga Jual',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Stok',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Satuan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Aksi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows:
                products.map((product) {
                  final isLowStock = product.stock <= product.minStock;
                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (isLowStock) {
                        return AppColors.error.withOpacity(0.1);
                      }
                      return null;
                    }),
                    cells: [
                      DataCell(
                        Text(product.plu, style: AppTextStyles.bodyMedium),
                        onTap: () => _navigateToDetail(context, product),
                      ),
                      DataCell(
                        Text(product.barcode, style: AppTextStyles.bodyMedium),
                        onTap: () => _navigateToDetail(context, product),
                      ),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            product.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onTap: () => _navigateToDetail(context, product),
                      ),
                      DataCell(
                        Text(
                          product.categoryName ?? '-',
                          style: AppTextStyles.bodyMedium,
                        ),
                        onTap: () => _navigateToDetail(context, product),
                      ),
                      DataCell(
                        Text(
                          'Rp ${product.purchasePrice.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        onTap: () => _navigateToDetail(context, product),
                      ),
                      DataCell(
                        Text(
                          'Rp ${product.sellingPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => _navigateToDetail(context, product),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isLowStock
                                    ? AppColors.error.withOpacity(0.2)
                                    : AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.stock}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color:
                                  isLowStock
                                      ? AppColors.error
                                      : AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => _navigateToDetail(context, product),
                      ),
                      DataCell(
                        Text(product.unit, style: AppTextStyles.bodyMedium),
                        onTap: () => _navigateToDetail(context, product),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color:
                                  product.isActive
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              product.isActive ? 'Aktif' : 'Nonaktif',
                              style: AppTextStyles.bodySmall.copyWith(
                                color:
                                    product.isActive
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToDetail(context, product),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 20),
                              color: AppColors.info,
                              onPressed:
                                  () => _navigateToDetail(context, product),
                              tooltip: 'Detail',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: AppColors.warning,
                              onPressed:
                                  () => _navigateToForm(context, product),
                              tooltip: 'Edit',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: AppColors.error,
                              onPressed:
                                  () => _showDeleteDialog(context, product),
                              tooltip: 'Hapus',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showLowStock ? Icons.inventory_2 : Icons.shopping_basket_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _showLowStock
                ? 'Tidak ada produk dengan stok rendah'
                : 'Belum ada produk',
            style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _showLowStock
                ? 'Semua produk memiliki stok yang cukup'
                : 'Tambahkan produk pertama Anda',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (!_showLowStock) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToForm(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
          ElevatedButton.icon(
            onPressed: () {
              _productBloc.add(const event.LoadProducts());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(productId: product.id),
      ),
    );
  }

  void _navigateToForm(BuildContext context, Product? product) async {
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
