import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../bloc/purchase_return_bloc.dart';
import '../bloc/purchase_return_event.dart';
import '../bloc/purchase_return_state.dart';
import 'purchase_return_detail_page.dart';

class PurchaseReturnListPage extends StatefulWidget {
  const PurchaseReturnListPage({Key? key}) : super(key: key);

  @override
  State<PurchaseReturnListPage> createState() => _PurchaseReturnListPageState();
}

class _PurchaseReturnListPageState extends State<PurchaseReturnListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReturns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadReturns() {
    context.read<PurchaseReturnBloc>().add(const LoadPurchaseReturns());
  }

  void _searchReturns(String query) {
    if (query.isEmpty) {
      _loadReturns();
    } else {
      context.read<PurchaseReturnBloc>().add(SearchPurchaseReturnsEvent(query));
    }
  }

  Future<void> _showDeleteConfirmation(String id, String returnNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Apakah Anda yakin ingin menghapus return $returnNumber?\n\nPerhatian: Stock akan dikembalikan ke posisi sebelum return.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      context.read<PurchaseReturnBloc>().add(DeletePurchaseReturnEvent(id));
    }
  }

  Future<void> _navigateToDetail(String id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BlocProvider(
              create:
                  (_) =>
                      sl<PurchaseReturnBloc>()..add(LoadPurchaseReturnById(id)),
              child: PurchaseReturnDetailPage(returnId: id),
            ),
      ),
    );

    if (result == true) {
      _loadReturns();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Return Pembelian'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nomor return, supplier...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadReturns();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchReturns,
            ),
          ),

          // Return List
          Expanded(
            child: BlocConsumer<PurchaseReturnBloc, PurchaseReturnState>(
              listener: (context, state) {
                if (state is PurchaseReturnError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is PurchaseReturnOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadReturns();
                }
              },
              builder: (context, state) {
                if (state is PurchaseReturnLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PurchaseReturnLoaded) {
                  if (state.purchaseReturns.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_return,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada return pembelian',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.purchaseReturns.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final returnItem = state.purchaseReturns[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          returnItem.returnNumber,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Receiving: ${returnItem.receivingNumber}',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          returnItem.supplierName ?? 'N/A',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        returnItem.status,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getStatusColor(
                                          returnItem.status,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      returnItem.status.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(
                                          returnItem.status,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(returnItem.returnDate),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Icon(
                                    Icons.inventory,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${returnItem.items.length} item',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Reason
                              if (returnItem.reason != null &&
                                  returnItem.reason!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        size: 16,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Alasan: ${returnItem.reason}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(returnItem.total)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Detail & Print Button
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _navigateToDetail(returnItem.id),
                                    icon: const Icon(
                                      Icons.visibility,
                                      size: 18,
                                    ),
                                    label: const Text('Detail & Print'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete Button
                                  OutlinedButton.icon(
                                    onPressed:
                                        () => _showDeleteConfirmation(
                                          returnItem.id,
                                          returnItem.returnNumber,
                                        ),
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: const Text('Hapus'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: Text('Tidak ada data'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
