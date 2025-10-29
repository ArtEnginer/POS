import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/purchase.dart';
import '../bloc/purchase_bloc.dart';
import '../bloc/purchase_event.dart';
import '../bloc/purchase_state.dart';
import 'purchase_form_page.dart';
import 'purchase_detail_page.dart';

/// Optimized Purchase List Page with DataTable and Pagination
class PurchaseListPage extends StatelessWidget {
  const PurchaseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PurchaseBloc>()..add(const LoadPurchases()),
      child: const _PurchaseListView(),
    );
  }
}

class _PurchaseListView extends StatefulWidget {
  const _PurchaseListView();

  @override
  State<_PurchaseListView> createState() => _PurchaseListViewState();
}

class _PurchaseListViewState extends State<_PurchaseListView> {
  final TextEditingController _searchController = TextEditingController();

  // Client-side Pagination State
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String? _searchQuery;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
  }

  void _onRowsPerPageChanged(int newRowsPerPage) {
    setState(() {
      _rowsPerPage = newRowsPerPage;
      _currentPage = 1;
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
      _currentPage = 1;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == (query.isEmpty ? null : query)) {
        if (query.isEmpty) {
          context.read<PurchaseBloc>().add(const LoadPurchases());
        } else {
          context.read<PurchaseBloc>().add(SearchPurchases(query));
        }
      }
    });
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      if (mounted) {
        context.read<PurchaseBloc>().add(
          LoadPurchasesByDateRange(picked.start, picked.end),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _searchController.clear();
    });
    context.read<PurchaseBloc>().add(const LoadPurchases());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pembelian'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          // Tombol Tambah Pembelian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const PurchaseFormPage()),
                );
                if (result == true && mounted) {
                  context.read<PurchaseBloc>().add(const LoadPurchases());
                }
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Pembelian Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
            tooltip: 'Filter Tanggal',
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Hapus Filter',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () => context.read<PurchaseBloc>().add(const LoadPurchases()),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_dateRange != null) _buildDateRangeChip(),
          Expanded(
            child: BlocConsumer<PurchaseBloc, PurchaseState>(
              listener: (context, state) {
                if (state is PurchaseOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.read<PurchaseBloc>().add(const LoadPurchases());
                } else if (state is PurchaseError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is PurchaseLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PurchaseLoaded) {
                  if (state.purchases.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh:
                        () async => context.read<PurchaseBloc>().add(
                          const LoadPurchases(),
                        ),
                    child: _buildPurchaseTable(state),
                  );
                } else if (state is PurchaseError) {
                  return _buildErrorState(state.message);
                }
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nomor pembelian atau supplier...',
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
    );
  }

  Widget _buildDateRangeChip() {
    final formatter = DateFormat('dd MMM yyyy', 'id_ID');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Chip(
        label: Text(
          'Periode: ${formatter.format(_dateRange!.start)} - ${formatter.format(_dateRange!.end)}',
        ),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: _clearFilters,
      ),
    );
  }

  Widget _buildPurchaseTable(PurchaseLoaded state) {
    final allPurchases = state.purchases;

    // Client-side pagination
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, allPurchases.length);
    final purchases = allPurchases.sublist(
      startIndex.clamp(0, allPurchases.length),
      endIndex,
    );

    final totalItems = allPurchases.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy', 'id_ID');

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
                  'Daftar Pembelian',
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
                    '$totalItems Pembelian',
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowHeight: 56,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 72,
                    horizontalMargin: 16,
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.primary.withOpacity(0.08),
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'No. Pembelian',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Tanggal',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Supplier',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Jumlah Item',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Total',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Aksi',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    rows:
                        purchases.map((purchase) {
                          return DataRow(
                            cells: [
                              // No. Pembelian
                              DataCell(
                                Text(
                                  purchase.purchaseNumber,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () => _viewDetail(purchase),
                              ),
                              // Tanggal
                              DataCell(
                                Text(
                                  dateFormat.format(purchase.purchaseDate),
                                  style: AppTextStyles.bodySmall,
                                ),
                              ),
                              // Supplier
                              DataCell(
                                Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 200,
                                  ),
                                  child: Text(
                                    purchase.supplierName ?? '-',
                                    style: AppTextStyles.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ),
                              // Jumlah Item
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${purchase.items.length}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // Total
                              DataCell(
                                Text(
                                  currencyFormat.format(purchase.totalAmount),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              // Status
                              DataCell(_buildStatusBadge(purchase.status)),
                              // Aksi
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 18,
                                      ),
                                      onPressed: () => _viewDetail(purchase),
                                      tooltip: 'Lihat Detail',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_canEditPurchase(purchase.status))
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        onPressed:
                                            () => _editPurchase(purchase),
                                        tooltip: 'Edit',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    const SizedBox(width: 8),
                                    if (_canDeletePurchase(purchase.status))
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: AppColors.error,
                                        ),
                                        onPressed:
                                            () => _confirmDelete(purchase),
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
            ),
          ),
          // Pagination Controls
          _buildPaginationControls(totalPages, totalItems),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    String label;

    switch (status.toUpperCase()) {
      case 'RECEIVED':
        statusColor = Colors.green;
        label = 'Received';
        break;
      case 'APPROVED':
        statusColor = Colors.blue;
        label = 'Approved';
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        label = 'Pending';
        break;
      case 'DRAFT':
        statusColor = Colors.grey;
        label = 'Draft';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        label = 'Batal';
        break;
      default:
        statusColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages, int totalItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Rows per page selector
          Text('Baris per halaman:', style: AppTextStyles.bodySmall),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _rowsPerPage,
            underline: const SizedBox(),
            items:
                [5, 10, 25, 50, 100].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                _onRowsPerPageChanged(newValue);
              }
            },
          ),
          const SizedBox(width: 24),
          // Page info
          Text(
            'Halaman $_currentPage dari $totalPages ($totalItems total)',
            style: AppTextStyles.bodySmall,
          ),
          const Spacer(),
          // Navigation buttons
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 1 ? () => _onPageChanged(1) : null,
            tooltip: 'Halaman Pertama',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 1
                    ? () => _onPageChanged(_currentPage - 1)
                    : null,
            tooltip: 'Halaman Sebelumnya',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed:
                _currentPage < totalPages
                    ? () => _onPageChanged(_currentPage + 1)
                    : null,
            tooltip: 'Halaman Berikutnya',
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed:
                _currentPage < totalPages
                    ? () => _onPageChanged(totalPages)
                    : null,
            tooltip: 'Halaman Terakhir',
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
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada data pembelian',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambah pembelian baru',
            style: TextStyle(color: Colors.grey[500]),
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
          const Icon(Icons.error_outline, size: 100, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<PurchaseBloc>().add(const LoadPurchases());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _viewDetail(Purchase purchase) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseDetailPage(purchaseId: purchase.id),
      ),
    );
  }

  void _editPurchase(Purchase purchase) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PurchaseFormPage(purchase: purchase)),
    );
    if (result == true && mounted) {
      context.read<PurchaseBloc>().add(const LoadPurchases());
    }
  }

  void _confirmDelete(Purchase purchase) {
    final parentContext = context; // Capture context before dialog
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Apakah Anda yakin ingin menghapus pembelian ${purchase.purchaseNumber}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  parentContext.read<PurchaseBloc>().add(
                    DeletePurchase(purchase.id),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
  }

  /// Check if purchase can be edited
  /// Only purchases with status: draft, ordered, partial can be edited
  bool _canEditPurchase(String status) {
    final lowerStatus = status.toLowerCase();
    return ['draft', 'ordered', 'partial'].contains(lowerStatus);
  }

  /// Check if purchase can be deleted
  /// Only purchases with status: draft, ordered, partial can be deleted
  bool _canDeletePurchase(String status) {
    final lowerStatus = status.toLowerCase();
    return ['draft', 'ordered', 'partial'].contains(lowerStatus);
  }
}
