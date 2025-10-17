import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/receiving.dart';
import '../bloc/purchase_bloc.dart';
import '../bloc/purchase_event.dart';
import '../bloc/purchase_state.dart';
import '../bloc/receiving_bloc.dart';
import '../bloc/receiving_event.dart';
import '../bloc/receiving_state.dart';
import '../bloc/purchase_return_bloc.dart';
import 'receiving_detail_page.dart';
import 'receiving_form_page_new.dart';
import 'purchase_return_list_page.dart';

class ReceivingHistoryPage extends StatefulWidget {
  const ReceivingHistoryPage({Key? key}) : super(key: key);

  @override
  State<ReceivingHistoryPage> createState() => _ReceivingHistoryPageState();
}

class _ReceivingHistoryPageState extends State<ReceivingHistoryPage> {
  final _searchController = TextEditingController();
  bool _isNavigatingToEdit = false;
  Receiving? _receivingToEdit; // Store receiving data for edit

  @override
  void initState() {
    super.initState();
    _loadReceivings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadReceivings() {
    context.read<ReceivingBloc>().add(const LoadReceivings());
  }

  void _searchReceivings(String query) {
    if (query.isEmpty) {
      _loadReceivings();
    } else {
      context.read<ReceivingBloc>().add(SearchReceivingsEvent(query));
    }
  }

  Future<void> _showDeleteConfirmation(
    String id,
    String receivingNumber,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Apakah Anda yakin ingin menghapus penerimaan barang $receivingNumber?',
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
      context.read<ReceivingBloc>().add(DeleteReceivingEvent(id));
    }
  }

  Future<void> _navigateToEdit(String id) async {
    // Set flag untuk edit mode
    setState(() {
      _isNavigatingToEdit = true;
    });
    // Load receiving detail first, then load purchase data
    context.read<ReceivingBloc>().add(LoadReceivingById(id));
  }

  Future<void> _navigateToDetail(String id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BlocProvider(
              create: (_) => sl<ReceivingBloc>()..add(LoadReceivingById(id)),
              child: ReceivingDetailPage(receivingId: id),
            ),
      ),
    );

    if (result == true) {
      _loadReceivings();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'DRAFT':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penerimaan Barang'),
        actions: [
          // Button Manajemen Return
          IconButton(
            icon: const Icon(Icons.assignment_return),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => BlocProvider(
                        create: (_) => sl<PurchaseReturnBloc>(),
                        child: const PurchaseReturnListPage(),
                      ),
                ),
              );
            },
            tooltip: 'Manajemen Return',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceivings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Return Management Button Banner

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nomor receiving atau PO...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadReceivings();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchReceivings,
            ),
          ),

          // Receiving List
          Expanded(
            child: MultiBlocListener(
              listeners: [
                BlocListener<ReceivingBloc, ReceivingState>(
                  listener: (context, state) {
                    if (state is ReceivingError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                      // Reset flag jika error
                      setState(() {
                        _isNavigatingToEdit = false;
                      });
                    } else if (state is ReceivingOperationSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadReceivings();
                    } else if (state is ReceivingDetailLoaded &&
                        _isNavigatingToEdit) {
                      // Hanya navigate ke edit form jika flag edit = true
                      final receiving = state.receiving;
                      _receivingToEdit = receiving; // Store for later use
                      context.read<PurchaseBloc>().add(
                        LoadPurchaseById(receiving.purchaseId),
                      );
                    }
                  },
                ),
                BlocListener<PurchaseBloc, PurchaseState>(
                  listener: (context, state) {
                    if (state is PurchaseDetailLoaded && _isNavigatingToEdit) {
                      // Reset flag
                      setState(() {
                        _isNavigatingToEdit = false;
                      });

                      // Navigate to receiving form for edit with existing receiving data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => MultiBlocProvider(
                                providers: [
                                  BlocProvider(
                                    create: (_) => sl<ReceivingBloc>(),
                                  ),
                                  BlocProvider.value(
                                    value: context.read<PurchaseBloc>(),
                                  ),
                                ],
                                child: ReceivingFormPageNew(
                                  purchase: state.purchase,
                                  existingReceiving:
                                      _receivingToEdit, // Pass existing receiving
                                ),
                              ),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _loadReceivings();
                        }
                        // Clear stored receiving
                        _receivingToEdit = null;
                      });
                    }
                  },
                ),
              ],
              child: BlocBuilder<ReceivingBloc, ReceivingState>(
                builder: (context, state) {
                  if (state is ReceivingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ReceivingLoaded) {
                    if (state.receivings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada riwayat penerimaan barang',
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
                      itemCount: state.receivings.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final receiving = state.receivings[index];

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
                                            receiving.receivingNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'PO: ${receiving.purchaseNumber}',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            receiving.supplierName ??
                                                'Supplier tidak tersedia',
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
                                          receiving.status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            receiving.status,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        receiving.status.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(
                                            receiving.status,
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
                                      ).format(receiving.receivingDate),
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
                                      '${receiving.items.length} item',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(receiving.total)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // View Detail Button - Primary Action
                                    ElevatedButton.icon(
                                      onPressed:
                                          () => _navigateToDetail(receiving.id),
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 18,
                                      ),
                                      label: const Text('Detail'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Edit Button
                                    OutlinedButton.icon(
                                      onPressed:
                                          () => _navigateToEdit(receiving.id),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Edit'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Delete Button
                                    OutlinedButton.icon(
                                      onPressed:
                                          () => _showDeleteConfirmation(
                                            receiving.id,
                                            receiving.receivingNumber,
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
          ),
        ],
      ),
    );
  }
}
