import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/purchase.dart';
import '../bloc/purchase_bloc.dart';
import '../bloc/purchase_event.dart';
import '../bloc/purchase_state.dart';
import 'purchase_form_page.dart';
import 'purchase_detail_page.dart';

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
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        actions: [
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
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.read<PurchaseBloc>().add(const LoadPurchases());
                } else if (state is PurchaseError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
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
                  return _buildPurchaseTable(state.purchases);
                } else if (state is PurchaseError) {
                  return _buildErrorState(state.message);
                }
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_purchase_fab',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseFormPage()),
          );
          if (result == true && mounted) {
            context.read<PurchaseBloc>().add(const LoadPurchases());
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Pembelian Baru'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nomor pembelian atau supplier...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<PurchaseBloc>().add(const LoadPurchases());
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            context.read<PurchaseBloc>().add(const LoadPurchases());
          } else {
            context.read<PurchaseBloc>().add(SearchPurchases(value));
          }
        },
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

  Widget _buildPurchaseTable(List<Purchase> purchases) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            AppColors.primary.withOpacity(0.1),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'No. Pembelian',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Tanggal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Supplier',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Total Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Total Harga',
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
              purchases.map((purchase) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        purchase.purchaseNumber,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(Text(dateFormat.format(purchase.purchaseDate))),
                    DataCell(
                      Text(
                        purchase.supplierName ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          purchase.items.length.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        currencyFormat.format(purchase.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    DataCell(_buildStatusChip(purchase.status)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, size: 20),
                            onPressed: () => _viewDetail(purchase),
                            tooltip: 'Lihat Detail',
                          ),
                          if (purchase.status == 'DRAFT')
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _editPurchase(purchase),
                              tooltip: 'Edit',
                            ),
                          if (purchase.status == 'DRAFT')
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDelete(purchase),
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

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
}
