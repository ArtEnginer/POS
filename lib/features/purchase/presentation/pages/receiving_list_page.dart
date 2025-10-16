import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../bloc/purchase_bloc.dart';
import '../bloc/purchase_event.dart';
import '../bloc/purchase_state.dart';
import '../bloc/receiving_bloc.dart';
import 'receiving_form_page.dart';

class ReceivingListPage extends StatefulWidget {
  const ReceivingListPage({Key? key}) : super(key: key);

  @override
  State<ReceivingListPage> createState() => _ReceivingListPageState();
}

class _ReceivingListPageState extends State<ReceivingListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPurchases() {
    context.read<PurchaseBloc>().add(const LoadPurchases());
  }

  void _searchPurchases(String query) {
    if (query.isEmpty) {
      _loadPurchases();
    } else {
      context.read<PurchaseBloc>().add(SearchPurchases(query));
    }
  }

  Future<void> _openReceivingForm(String purchaseId) async {
    // Load purchase detail first
    context.read<PurchaseBloc>().add(LoadPurchaseById(purchaseId));
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return Colors.grey;
      case 'APPROVED':
        return Colors.orange;
      case 'RECEIVED':
        return Colors.green;
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
        title: const Text('Penerimaan Barang (Receiving)'),
        actions: [
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nomor PO atau supplier...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadPurchases();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchPurchases,
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
                    'Halaman ini menampilkan semua PO. Proses receiving hanya tersedia untuk PO dengan status APPROVED.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Purchase List
          Expanded(
            child: BlocConsumer<PurchaseBloc, PurchaseState>(
              listener: (context, state) {
                if (state is PurchaseError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is PurchaseOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadPurchases();
                } else if (state is PurchaseDetailLoaded) {
                  // Navigate to receiving form
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider(create: (_) => sl<PurchaseBloc>()),
                              BlocProvider(create: (_) => sl<ReceivingBloc>()),
                            ],
                            child: ReceivingFormPage(purchase: state.purchase),
                          ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadPurchases();
                    }
                  });
                }
              },
              builder: (context, state) {
                if (state is PurchaseLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PurchaseLoaded) {
                  if (state.purchases.isEmpty) {
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
                    itemCount: state.purchases.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final purchase = state.purchases[index];
                      final canReceive =
                          purchase.status.toUpperCase() == 'APPROVED';
                      final isReceived =
                          purchase.status.toUpperCase() == 'RECEIVED';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: InkWell(
                          onTap: () {
                            // Navigate to detail if needed
                          },
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
                                            purchase.purchaseNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            purchase.supplierName ??
                                                'Supplier tidak tersedia',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
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
                                          purchase.status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            purchase.status,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        purchase.status.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(
                                            purchase.status,
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
                                      ).format(purchase.purchaseDate),
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
                                      '${purchase.items.length} item',
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
                                      'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(purchase.total)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    if (canReceive)
                                      ElevatedButton.icon(
                                        onPressed:
                                            () =>
                                                _openReceivingForm(purchase.id),
                                        icon: const Icon(
                                          Icons.check_circle,
                                          size: 18,
                                        ),
                                        label: const Text('Proses Receiving'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      )
                                    else if (isReceived)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: Colors.green.shade700,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Sudah Diterima',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Text(
                                        'Menunggu approval',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
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
