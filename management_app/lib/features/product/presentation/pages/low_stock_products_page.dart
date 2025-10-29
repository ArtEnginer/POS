import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/product_usecases.dart';
import '../../../product/domain/entities/product.dart';
import 'product_detail_page.dart';
import 'product_form_page.dart';

class LowStockProductsPage extends StatefulWidget {
  const LowStockProductsPage({super.key});

  @override
  State<LowStockProductsPage> createState() => _LowStockProductsPageState();
}

class _LowStockProductsPageState extends State<LowStockProductsPage> {
  final GetLowStockProductsPaginated _getLowStockProducts = sl();

  // Pagination state
  int _currentPage = 1;
  int _rowsPerPage = 5;
  int _totalPages = 1;
  int _totalItems = 0;

  // Data state
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _getLowStockProducts(
      page: _currentPage,
      limit: _rowsPerPage,
      search: _searchQuery,
    );

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        }
      },
      (data) {
        if (mounted) {
          setState(() {
            _products = (data['products'] as List).cast<Product>();
            _currentPage = data['currentPage'] ?? 1;
            _totalPages = data['totalPages'] ?? 1;
            _totalItems = data['totalItems'] ?? 0;
            _isLoading = false;
          });
        }
      },
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
          _currentPage = 1; // Reset to first page on search
        });
        _loadProducts();
      }
    });
  }

  void _onRowsPerPageChanged(int? newValue) {
    if (newValue != null && newValue != _rowsPerPage) {
      setState(() {
        _rowsPerPage = newValue;
        _currentPage = 1; // Reset to first page
      });
      _loadProducts();
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      _loadProducts();
    }
  }

  void _navigateToDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(productId: product.id),
      ),
    );
  }

  void _navigateToEdit(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(product: product),
      ),
    ).then((_) => _loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Stok Minimum'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: Column(
        children: [
          // Header with Search
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari produk (nama, SKU, barcode)...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Total Items Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_totalItems Produk',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading / Error / Table
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadProducts,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                    : _products.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada produk dengan stok rendah',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _buildTable(),
          ),

          // Pagination Footer
          _buildPaginationFooter(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
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
              AppColors.warning.withOpacity(0.08),
            ),
            columns: [
              DataColumn(label: Text('SKU', style: AppTextStyles.titleSmall)),
              DataColumn(
                label: Text('Barcode', style: AppTextStyles.titleSmall),
              ),
              DataColumn(
                label: Text('Nama Produk', style: AppTextStyles.titleSmall),
              ),
              DataColumn(
                label: Text('Kategori', style: AppTextStyles.titleSmall),
              ),
              DataColumn(
                label: Text('Stok', style: AppTextStyles.titleSmall),
                numeric: true,
              ),
              DataColumn(
                label: Text('Min Stock', style: AppTextStyles.titleSmall),
                numeric: true,
              ),
              DataColumn(
                label: Text('Status', style: AppTextStyles.titleSmall),
              ),
              DataColumn(label: Text('Aksi', style: AppTextStyles.titleSmall)),
            ],
            rows:
                _products.map((product) {
                  final isLowStock = product.stock <= product.minStock;
                  final stockPercentage =
                      product.minStock > 0
                          ? (product.stock / product.minStock * 100).clamp(
                            0,
                            100,
                          )
                          : 0.0;

                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return AppColors.warning.withOpacity(0.05);
                      }
                      return AppColors.error.withOpacity(0.03);
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
                        Text(
                          product.categoryName ?? '-',
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
                              '${product.stock.toInt()}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                color: isLowStock ? AppColors.error : null,
                                fontWeight:
                                    isLowStock
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            if (isLowStock) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: AppColors.error,
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          '${product.minStock.toInt()}',
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
                                stockPercentage <= 50
                                    ? AppColors.error.withOpacity(0.1)
                                    : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stockPercentage <= 50 ? 'Kritis' : 'Rendah',
                            style: AppTextStyles.bodySmall.copyWith(
                              color:
                                  stockPercentage <= 50
                                      ? AppColors.error
                                      : AppColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.visibility,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              onPressed: () => _navigateToDetail(product),
                              tooltip: 'Detail',
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: AppColors.success,
                                size: 18,
                              ),
                              onPressed: () => _navigateToEdit(product),
                              tooltip: 'Edit',
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

  Widget _buildPaginationFooter() {
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
          DropdownButton<int>(
            value: _rowsPerPage,
            items:
                [5, 10, 15, 50, 100].map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
            onChanged: _onRowsPerPageChanged,
            underline: Container(),
          ),
          const Spacer(),
          // Page info
          Text(
            'Halaman $_currentPage dari $_totalPages ($_totalItems total)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          // Navigation buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                tooltip: 'Halaman Pertama',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed:
                    _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                tooltip: 'Halaman Sebelumnya',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    _currentPage < _totalPages
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                tooltip: 'Halaman Selanjutnya',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed:
                    _currentPage < _totalPages
                        ? () => _goToPage(_totalPages)
                        : null,
                tooltip: 'Halaman Terakhir',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
