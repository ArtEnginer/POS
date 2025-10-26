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

  // Pagination
  int _currentPage = 0;
  int _rowsPerPage = 10;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

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

  void _sort<T>(
    Comparable<T> Function(Product p) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<Product> _getSortedProducts(List<Product> products) {
    final sorted = List<Product>.from(products);

    switch (_sortColumnIndex) {
      case 0: // sku
        sorted.sort(
          (a, b) =>
              _sortAscending ? a.sku.compareTo(b.sku) : b.sku.compareTo(a.sku),
        );
        break;
      case 1: // Barcode
        sorted.sort(
          (a, b) =>
              _sortAscending
                  ? a.barcode.compareTo(b.barcode)
                  : b.barcode.compareTo(a.barcode),
        );
        break;
      case 2: // Nama
        sorted.sort(
          (a, b) =>
              _sortAscending
                  ? a.name.compareTo(b.name)
                  : b.name.compareTo(a.name),
        );
        break;
      case 3: // Kategori
        sorted.sort((a, b) {
          final aCategory = a.categoryName ?? '';
          final bCategory = b.categoryName ?? '';
          return _sortAscending
              ? aCategory.compareTo(bCategory)
              : bCategory.compareTo(aCategory);
        });
        break;
      case 4: // Harga Beli
        sorted.sort(
          (a, b) =>
              _sortAscending
                  ? a.costPrice.compareTo(b.costPrice)
                  : b.costPrice.compareTo(a.costPrice),
        );
        break;
      case 5: // Harga Jual
        sorted.sort(
          (a, b) =>
              _sortAscending
                  ? a.sellingPrice.compareTo(b.sellingPrice)
                  : b.sellingPrice.compareTo(a.sellingPrice),
        );
        break;
      case 6: // Stok
        sorted.sort(
          (a, b) =>
              _sortAscending
                  ? a.stock.compareTo(b.stock)
                  : b.stock.compareTo(a.stock),
        );
        break;
    }

    return sorted;
  }

  List<Product> _getPaginatedProducts(List<Product> products) {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, products.length);

    if (startIndex >= products.length) {
      return [];
    }

    return products.sublist(startIndex, endIndex);
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
                  _currentPage = 0; // Reset to first page
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
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToForm(context, null),
              tooltip: 'Tambah Produk',
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
                    _currentPage = 0; // Reset to first page on search
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
      ),
    );
  }

  Widget _buildProductTable(List<Product> products) {
    final sortedProducts = _getSortedProducts(products);
    final paginatedProducts = _getPaginatedProducts(sortedProducts);
    final totalPages = (sortedProducts.length / _rowsPerPage).ceil();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Daftar Produk',
                  style: AppTextStyles.h6.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${sortedProducts.length} Produk',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: DataTable(
                  headingRowHeight: 56,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 60,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.primary.withOpacity(0.08),
                  ),
                  columns: [
                    DataColumn(
                      label: const Text(
                        'sku',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onSort: (columnIndex, ascending) {
                        _sort<String>((p) => p.sku, columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Barcode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onSort: (columnIndex, ascending) {
                        _sort<String>((p) => p.barcode, columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Nama Produk',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onSort: (columnIndex, ascending) {
                        _sort<String>((p) => p.name, columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Kategori',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onSort: (columnIndex, ascending) {
                        _sort<String>(
                          (p) => p.categoryName ?? '',
                          columnIndex,
                          ascending,
                        );
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Harga Beli',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      numeric: true,
                      onSort: (columnIndex, ascending) {
                        _sort<num>((p) => p.costPrice, columnIndex, ascending);
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Harga Jual',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      numeric: true,
                      onSort: (columnIndex, ascending) {
                        _sort<num>(
                          (p) => p.sellingPrice,
                          columnIndex,
                          ascending,
                        );
                      },
                    ),
                    DataColumn(
                      label: const Text(
                        'Stok',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      numeric: true,
                      onSort: (columnIndex, ascending) {
                        _sort<num>((p) => p.stock, columnIndex, ascending);
                      },
                    ),
                    const DataColumn(
                      label: Text(
                        'Satuan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const DataColumn(
                      label: Text(
                        'Aksi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  rows:
                      paginatedProducts.map((product) {
                        final isLowStock = product.stock <= product.minStock;
                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((
                            Set<WidgetState> states,
                          ) {
                            if (states.contains(WidgetState.hovered)) {
                              return AppColors.primary.withOpacity(0.05);
                            }
                            if (isLowStock) {
                              return AppColors.error.withOpacity(0.08);
                            }
                            return null;
                          }),
                          cells: [
                            DataCell(
                              Text(
                                product.sku,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => _navigateToDetail(context, product),
                            ),
                            DataCell(
                              Text(
                                product.barcode,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => _navigateToDetail(context, product),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 180,
                                  maxWidth: 250,
                                ),
                                child: Text(
                                  product.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              onTap: () => _navigateToDetail(context, product),
                            ),
                            DataCell(
                              Text(
                                product.categoryName ?? '-',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => _navigateToDetail(context, product),
                            ),
                            DataCell(
                              Text(
                                'Rp ${product.costPrice.toStringAsFixed(0)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => _navigateToDetail(context, product),
                            ),
                            DataCell(
                              Text(
                                'Rp ${product.sellingPrice.toStringAsFixed(0)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => _navigateToDetail(context, product),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isLowStock
                                          ? AppColors.error.withOpacity(0.15)
                                          : AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color:
                                        isLowStock
                                            ? AppColors.error.withOpacity(0.3)
                                            : AppColors.success.withOpacity(
                                              0.3,
                                            ),
                                  ),
                                ),
                                child: Text(
                                  '${product.stock}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color:
                                        isLowStock
                                            ? AppColors.error
                                            : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              onTap: () => _navigateToDetail(context, product),
                            ),
                            DataCell(
                              Text(
                                product.unit,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 13,
                                ),
                              ),
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
                                      fontSize: 12,
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
                                  Tooltip(
                                    message: 'Lihat Detail',
                                    child: InkWell(
                                      onTap:
                                          () => _navigateToDetail(
                                            context,
                                            product,
                                          ),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.info.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.visibility,
                                          size: 18,
                                          color: AppColors.info,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: 'Edit',
                                    child: InkWell(
                                      onTap:
                                          () =>
                                              _navigateToForm(context, product),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          size: 18,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: 'Hapus',
                                    child: InkWell(
                                      onTap:
                                          () => _showDeleteDialog(
                                            context,
                                            product,
                                          ),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
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
          ),
          // Pagination Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.1),
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Rows per page selector
                Text(
                  'Baris per halaman:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.2),
                    ),
                  ),
                  child: DropdownButton<int>(
                    value: _rowsPerPage,
                    underline: const SizedBox(),
                    items:
                        [5, 10, 25, 50, 100].map((value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              '$value',
                              style: AppTextStyles.bodySmall,
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _rowsPerPage = value!;
                        _currentPage = 0; // Reset to first page
                      });
                    },
                  ),
                ),
                const SizedBox(width: 24),
                // Page info
                Text(
                  '${_currentPage * _rowsPerPage + 1}-${((_currentPage + 1) * _rowsPerPage).clamp(0, sortedProducts.length)} dari ${sortedProducts.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Page navigation
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.first_page),
                      iconSize: 20,
                      onPressed:
                          _currentPage > 0
                              ? () {
                                setState(() {
                                  _currentPage = 0;
                                });
                              }
                              : null,
                      tooltip: 'Halaman pertama',
                      color: AppColors.primary,
                      disabledColor: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 20,
                      onPressed:
                          _currentPage > 0
                              ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                              : null,
                      tooltip: 'Halaman sebelumnya',
                      color: AppColors.primary,
                      disabledColor: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Hal ${_currentPage + 1} / $totalPages',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 20,
                      onPressed:
                          _currentPage < totalPages - 1
                              ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                              : null,
                      tooltip: 'Halaman berikutnya',
                      color: AppColors.primary,
                      disabledColor: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    IconButton(
                      icon: const Icon(Icons.last_page),
                      iconSize: 20,
                      onPressed:
                          _currentPage < totalPages - 1
                              ? () {
                                setState(() {
                                  _currentPage = totalPages - 1;
                                });
                              }
                              : null,
                      tooltip: 'Halaman terakhir',
                      color: AppColors.primary,
                      disabledColor: AppColors.textSecondary.withOpacity(0.3),
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
