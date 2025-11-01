import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/product.dart';
import '../../data/models/product_model.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart' as event;
import '../bloc/product_state.dart';
import 'product_detail_page.dart';
import 'product_form_page.dart';
import 'low_stock_products_page.dart';

/// Optimized Product List Page with Server-Side Pagination
/// Designed for handling 50,000+ products efficiently
class ProductListPageOptimized extends StatefulWidget {
  const ProductListPageOptimized({super.key});

  @override
  State<ProductListPageOptimized> createState() =>
      _ProductListPageOptimizedState();
}

class _ProductListPageOptimizedState extends State<ProductListPageOptimized> {
  final TextEditingController _searchController = TextEditingController();
  late final ProductBloc _productBloc;

  // Server-side Pagination State
  int _currentPage = 1; // Server pages start from 1
  int _rowsPerPage = 5; // Default 5 items per page
  String? _searchQuery;
  String? _sortBy;
  bool _sortAscending = true;
  bool _showLowStock = false;

  @override
  void initState() {
    super.initState();
    _productBloc = sl<ProductBloc>();
    _loadProducts();
  }

  @override
  void dispose() {
    _productBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    if (_showLowStock) {
      _productBloc.add(const event.LoadLowStockProducts());
    } else {
      _productBloc.add(
        event.LoadProducts(
          page: _currentPage,
          limit: _rowsPerPage,
          search: _searchQuery,
          sortBy: _sortBy,
          ascending: _sortAscending,
        ),
      );
    }
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _loadProducts();
  }

  void _onRowsPerPageChanged(int newRowsPerPage) {
    setState(() {
      _rowsPerPage = newRowsPerPage;
      _currentPage = 1; // Reset to first page
    });
    _loadProducts();
  }

  void _onSort(String sortBy, bool ascending) {
    setState(() {
      _sortBy = sortBy;
      _sortAscending = ascending;
      _currentPage = 1; // Reset to first page when sorting
    });
    _loadProducts();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
      _currentPage = 1; // Reset to first page when searching
    });
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == (query.isEmpty ? null : query)) {
        _loadProducts();
      }
    });
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
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LowStockProductsPage(),
                  ),
                );
              },
              tooltip: 'Stok Minimum',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadProducts(),
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToForm(context, null),
              tooltip: 'Tambah Produk',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'import') {
                  _handleImport();
                } else if (value == 'template') {
                  _handleDownloadTemplate();
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.upload_file, size: 20),
                          SizedBox(width: 12),
                          Text('Import Produk'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'template',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 12),
                          Text('Download Template'),
                        ],
                      ),
                    ),
                  ],
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
                  hintText: 'Cari produk (SKU, Barcode, Nama)...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
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
                    vertical: 14,
                  ),
                ),
                onChanged: _onSearch,
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
                    _loadProducts();
                  } else if (state is ProductImportSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    _showImportResultDialog(context, state.details);
                    _loadProducts();
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
                      onRefresh: () async => _loadProducts(),
                      child: _buildProductTable(state),
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

  Widget _buildProductTable(ProductLoaded state) {
    final products = state.products;
    final totalItems = state.totalItems;

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
                    '$totalItems Produk',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Table - Full Width with Horizontal Scroll
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowHeight: 56,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 60,
                    horizontalMargin: 16,
                    columnSpacing: 24,
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.primary.withOpacity(0.08),
                    ),
                    columns: [
                      DataColumn(
                        label: const Text(
                          'SKU',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onSort: (_, ascending) => _onSort('sku', ascending),
                      ),
                      DataColumn(
                        label: const Text(
                          'Barcode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onSort: (_, ascending) => _onSort('barcode', ascending),
                      ),
                      DataColumn(
                        label: const Text(
                          'Nama Produk',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onSort: (_, ascending) => _onSort('name', ascending),
                      ),
                      const DataColumn(
                        label: Text(
                          'Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
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
                        onSort:
                            (_, ascending) => _onSort('cost_price', ascending),
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
                        onSort:
                            (_, ascending) =>
                                _onSort('selling_price', ascending),
                      ),
                      const DataColumn(
                        label: Text(
                          'Stok',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        numeric: true,
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
                        products.map((product) {
                          final isLowStock = product.stock <= product.minStock;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((
                              states,
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
                              ),
                              DataCell(
                                Text(
                                  product.barcode,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  product.name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      product.categoryName ?? '-',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                    // Multi-unit indicator
                                    if (product.units != null &&
                                        product.units!.length > 1) ...[
                                      const SizedBox(width: 6),
                                      Tooltip(
                                        message:
                                            'Multi-Unit (${product.units!.length} units)',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.info,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.layers,
                                                size: 10,
                                                color: AppColors.textWhite,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${product.units!.length}',
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                      color:
                                                          AppColors.textWhite,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    // Branch-specific pricing indicator
                                    if (product.prices != null &&
                                        product.prices!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Tooltip(
                                        message: 'Harga Per Cabang',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.store,
                                            size: 10,
                                            color: AppColors.textWhite,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(product.costPrice),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(product.sellingPrice),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
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
                                            ? AppColors.error.withOpacity(0.1)
                                            : AppColors.success.withOpacity(
                                              0.1,
                                            ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${product.stock.toInt()}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color:
                                          isLowStock
                                              ? AppColors.error
                                              : AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: AppColors.info,
                                        size: 18,
                                      ),
                                      onPressed:
                                          () => _navigateToDetail(
                                            context,
                                            product,
                                          ),
                                      tooltip: 'Detail',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: AppColors.warning,
                                        size: 18,
                                      ),
                                      onPressed:
                                          () =>
                                              _navigateToForm(context, product),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: AppColors.error,
                                        size: 18,
                                      ),
                                      onPressed:
                                          () => _showDeleteDialog(
                                            context,
                                            product,
                                          ),
                                      tooltip: 'Hapus',
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
          ),
          // Pagination Footer
          _buildPaginationFooter(state),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(ProductLoaded state) {
    final totalPages = state.totalPages;
    final totalItems = state.totalItems;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
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
                  [5, 10, 15, 50, 100].map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value', style: AppTextStyles.bodySmall),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) _onRowsPerPageChanged(value);
              },
            ),
          ),
          const SizedBox(width: 24),
          // Page info
          Text(
            'Halaman $_currentPage dari $totalPages ($totalItems total)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          // Page navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page, size: 20),
                onPressed: _currentPage > 1 ? () => _onPageChanged(1) : null,
                tooltip: 'Halaman pertama',
                color: AppColors.primary,
                disabledColor: AppColors.textSecondary.withOpacity(0.3),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed:
                    _currentPage > 1
                        ? () => _onPageChanged(_currentPage - 1)
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
                  '$_currentPage',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed:
                    _currentPage < totalPages
                        ? () => _onPageChanged(_currentPage + 1)
                        : null,
                tooltip: 'Halaman berikutnya',
                color: AppColors.primary,
                disabledColor: AppColors.textSecondary.withOpacity(0.3),
              ),
              IconButton(
                icon: const Icon(Icons.last_page, size: 20),
                onPressed:
                    _currentPage < totalPages
                        ? () => _onPageChanged(totalPages)
                        : null,
                tooltip: 'Halaman terakhir',
                color: AppColors.primary,
                disabledColor: AppColors.textSecondary.withOpacity(0.3),
              ),
            ],
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
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada produk',
            style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan produk baru untuk memulai',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
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
            onPressed: () => _loadProducts(),
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
    Product? productToEdit = product;

    // If editing existing product, load complete data first
    if (product != null) {
      try {
        // Show loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const Center(child: CircularProgressIndicator()),
          );
        }

        // Load complete product data (with units and prices)
        final apiClient = sl<ApiClient>();
        final response = await apiClient.get(
          '/products/${product.id}/complete',
        );

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (response.statusCode == 200) {
          // Parse complete product data using ProductModel
          productToEdit = ProductModel.fromJson(response.data['data']);
        } else {
          // If failed to load, show error and return
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal memuat data produk lengkap'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } catch (e) {
        // Close loading dialog if still open
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Navigate to form with complete product data
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(product: productToEdit),
      ),
    );

    if (result == true && mounted) {
      _loadProducts();
    }
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Hapus Produk'),
            content: Text('Apakah Anda yakin ingin menghapus ${product.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _productBloc.add(event.DeleteProduct(product.id));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textWhite,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  void _handleImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );

    if (result != null && result.files.single.path != null) {
      _productBloc.add(event.ImportProducts(result.files.single.path!));
    }
  }

  void _handleDownloadTemplate() {
    _productBloc.add(const event.DownloadImportTemplate());
  }

  void _showImportResultDialog(
    BuildContext context,
    Map<String, dynamic> details,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hasil Import'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total: ${details['total']} baris'),
                Text(
                  'Berhasil: ${details['imported']} produk',
                  style: const TextStyle(color: AppColors.success),
                ),
                Text(
                  'Error: ${details['errors']} baris',
                  style: const TextStyle(color: AppColors.error),
                ),
                Text(
                  'Dilewati: ${details['skipped']} baris',
                  style: const TextStyle(color: AppColors.warning),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }
}
