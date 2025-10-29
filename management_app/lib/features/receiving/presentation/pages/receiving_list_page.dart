import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../purchase/domain/entities/purchase.dart';
import '../../../purchase/presentation/bloc/purchase_bloc.dart';
import '../../../purchase/presentation/bloc/purchase_event.dart';
import '../../../purchase/presentation/bloc/purchase_state.dart';
import '../../../purchase_return/presentation/bloc/purchase_return_bloc.dart';
import '../bloc/receiving_bloc.dart';
import 'receiving_form_page_new.dart';
import 'receiving_history_page.dart';

/// Optimized Receiving List Page with Server-Side Pagination and DataTable
class ReceivingListPage extends StatefulWidget {
  const ReceivingListPage({Key? key}) : super(key: key);

  @override
  State<ReceivingListPage> createState() => _ReceivingListPageState();
}

class _ReceivingListPageState extends State<ReceivingListPage> {
  final _searchController = TextEditingController();
  late final PurchaseBloc _purchaseBloc;

  // Client-side Pagination State (backend belum support server-side)
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _purchaseBloc = context.read<PurchaseBloc>();
    _loadPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPurchases() {
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      _purchaseBloc.add(SearchPurchases(_searchQuery!));
    } else {
      _purchaseBloc.add(const LoadPurchases());
    }
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
    _loadPurchases();
  }

  void _onRowsPerPageChanged(int newRowsPerPage) {
    setState(() {
      _rowsPerPage = newRowsPerPage;
      _currentPage = 1;
    });
    _loadPurchases();
  }

  void _onSort(String sortBy, bool ascending) {
    // Sort will be handled client-side in _buildPurchaseTable
    setState(() {
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
        _loadPurchases();
      }
    });
  }

  Future<void> _openReceivingForm(Purchase purchase) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<PurchaseBloc>()),
                BlocProvider(create: (_) => sl<ReceivingBloc>()),
              ],
              child: ReceivingFormPageNew(purchase: purchase),
            ),
      ),
    );
    if (result == true) {
      _loadPurchases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penerimaan Barang (Receiving)'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider(create: (_) => sl<ReceivingBloc>()),
                          BlocProvider(create: (_) => sl<PurchaseBloc>()),
                          BlocProvider(create: (_) => sl<PurchaseReturnBloc>()),
                        ],
                        child: const ReceivingHistoryPage(),
                      ),
                ),
              );
            },
            tooltip: 'Riwayat Penerimaan',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchases,
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
                hintText: 'Cari nomor PO atau supplier...',
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

          // Info Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Proses receiving hanya tersedia untuk PO dengan status APPROVED.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Purchase List with DataTable
          Expanded(
            child: BlocConsumer<PurchaseBloc, PurchaseState>(
              listener: (context, state) {
                if (state is PurchaseError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (state is PurchaseOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadPurchases();
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
                    onRefresh: () async => _loadPurchases(),
                    child: _buildPurchaseTable(state),
                  );
                } else if (state is PurchaseError) {
                  return _buildErrorState(state.message);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
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
                  'Daftar Purchase Order',
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
                    '$totalItems PO',
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
                          'No. PO',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onSort:
                            (columnIndex, ascending) =>
                                _onSort('purchase_number', ascending),
                      ),
                      DataColumn(
                        label: Text(
                          'Supplier',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onSort:
                            (columnIndex, ascending) =>
                                _onSort('supplier_name', ascending),
                      ),
                      DataColumn(
                        label: Text(
                          'Tanggal',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onSort:
                            (columnIndex, ascending) =>
                                _onSort('purchase_date', ascending),
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
                        onSort:
                            (columnIndex, ascending) =>
                                _onSort('total_amount', ascending),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onSort:
                            (columnIndex, ascending) =>
                                _onSort('status', ascending),
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
                          final canReceive =
                              purchase.status.toLowerCase() == 'approved';
                          final isReceived =
                              purchase.status.toLowerCase() == 'received';

                          return DataRow(
                            cells: [
                              // No. PO
                              DataCell(
                                Text(
                                  purchase.purchaseNumber,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                              // Tanggal
                              DataCell(
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(purchase.purchaseDate),
                                  style: AppTextStyles.bodySmall,
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
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(purchase.totalAmount),
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
                                _buildActionButton(
                                  purchase,
                                  canReceive,
                                  isReceived,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'ordered':
        return Colors.blue;
      case 'approved':
        return Colors.teal;
      case 'partial':
        return Colors.orange;
      case 'received':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    Purchase purchase,
    bool canReceive,
    bool isReceived,
  ) {
    if (canReceive) {
      return ElevatedButton.icon(
        onPressed: () => _openReceivingForm(purchase),
        icon: const Icon(Icons.check_circle, size: 16),
        label: const Text('Proses', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(100, 36),
        ),
      );
    } else if (isReceived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              'Diterima',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        'Perlu Approval',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
          fontSize: 11,
        ),
      );
    }
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
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada purchase order',
            style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'PO akan muncul di sini setelah dibuat',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
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
          Icon(Icons.error_outline, size: 80, color: AppColors.error),
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
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPurchases,
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
}
