import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/receiving.dart';
import '../../../purchase/presentation/bloc/purchase_bloc.dart';
import '../../../purchase/presentation/bloc/purchase_event.dart';
import '../../../purchase/presentation/bloc/purchase_state.dart';
import '../bloc/receiving_bloc.dart';
import '../bloc/receiving_event.dart';
import '../bloc/receiving_state.dart';
import '../../../purchase_return/presentation/bloc/purchase_return_bloc.dart';
import '../../../purchase_return/presentation/bloc/purchase_return_event.dart';
import '../../../purchase_return/presentation/bloc/purchase_return_state.dart';
import '../../../purchase_return/domain/entities/purchase_return.dart';
import 'receiving_detail_page.dart';
import 'receiving_form_page_new.dart';
import '../../../purchase_return/presentation/pages/purchase_return_list_page.dart';
import '../../../purchase_return/presentation/pages/purchase_return_form_page.dart';
import '../../../purchase_return/presentation/pages/purchase_return_detail_page.dart';

class ReceivingHistoryPage extends StatefulWidget {
  const ReceivingHistoryPage({Key? key}) : super(key: key);

  @override
  State<ReceivingHistoryPage> createState() => _ReceivingHistoryPageState();
}

class _ReceivingHistoryPageState extends State<ReceivingHistoryPage> {
  final _searchController = TextEditingController();
  bool _isNavigatingToEdit = false;
  Receiving? _receivingToEdit; // Store receiving data for edit
  final Map<String, List<PurchaseReturn>> _receivingReturns =
      {}; // Cache returns by receiving ID
  final Set<String> _expandedReceivings = {}; // Track expanded receiving cards
  String? _currentLoadingReceivingId; // Track which receiving is being loaded

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

  void _loadReturnsByReceivingId(String receivingId) {
    debugPrint('Loading returns for receiving: $receivingId');
    _currentLoadingReceivingId = receivingId;
    context.read<PurchaseReturnBloc>().add(
      LoadPurchaseReturnsByReceivingId(receivingId),
    );
  }

  void _toggleExpanded(String receivingId) {
    setState(() {
      if (_expandedReceivings.contains(receivingId)) {
        _expandedReceivings.remove(receivingId);
      } else {
        _expandedReceivings.add(receivingId);
        // Always load returns when expanding to get fresh data
        debugPrint('Expanding receiving: $receivingId');
        _loadReturnsByReceivingId(receivingId);
      }
    });
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
            (_) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create:
                      (_) => sl<ReceivingBloc>()..add(LoadReceivingById(id)),
                ),
                BlocProvider(create: (_) => sl<PurchaseReturnBloc>()),
              ],
              child: ReceivingDetailPage(receivingId: id),
            ),
      ),
    );

    if (result == true) {
      _loadReceivings();
    }
  }

  Future<void> _navigateToReturnForm(Receiving receiving) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MultiBlocProvider(
              providers: [
                BlocProvider<ReceivingBloc>(
                  create: (context) => sl<ReceivingBloc>(),
                ),
                BlocProvider<PurchaseReturnBloc>(
                  create: (context) => sl<PurchaseReturnBloc>(),
                ),
              ],
              child: PurchaseReturnFormPage(receivingId: receiving.id),
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

  Widget _buildReceivingCard(Receiving receiving) {
    final isExpanded = _expandedReceivings.contains(receiving.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            receiving.supplierName ?? 'Supplier tidak tersedia',
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
                          color: _getStatusColor(receiving.status),
                        ),
                      ),
                      child: Text(
                        receiving.status.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(receiving.status),
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
                      DateFormat('dd/MM/yyyy').format(receiving.receivingDate),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                // Returns Section - Show if receiving is COMPLETED
                if (receiving.status.toUpperCase() == 'COMPLETED') ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _toggleExpanded(receiving.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assignment_return,
                            size: 18,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              () {
                                final returns =
                                    _receivingReturns[receiving.id] ?? [];
                                return returns.isEmpty
                                    ? 'Lihat Retur'
                                    : '${returns.length} Retur';
                              }(),
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // View Detail Button - Primary Action
                    ElevatedButton.icon(
                      onPressed: () => _navigateToDetail(receiving.id),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Detail'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Return Button - Only show if COMPLETED
                    if (receiving.status.toUpperCase() == 'COMPLETED') ...[
                      ElevatedButton.icon(
                        onPressed: () => _navigateToReturnForm(receiving),
                        icon: const Icon(Icons.assignment_return, size: 18),
                        label: const Text('Return'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Edit Button
                    OutlinedButton.icon(
                      onPressed: () => _navigateToEdit(receiving.id),
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

          // Expandable Returns List
          if (isExpanded && receiving.status.toUpperCase() == 'COMPLETED')
            _buildReturnsList(receiving.id),
        ],
      ),
    );
  }

  Widget _buildReturnsList(String receivingId) {
    return BlocBuilder<PurchaseReturnBloc, PurchaseReturnState>(
      builder: (context, state) {
        final returns = _receivingReturns[receivingId] ?? [];

        if (state is PurchaseReturnLoading &&
            !_receivingReturns.containsKey(receivingId)) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (returns.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Center(
              child: Text(
                'Belum ada retur untuk penerimaan ini',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(top: BorderSide(color: Colors.orange.shade200)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.orange.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 18,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daftar Retur (${returns.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: returns.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: Colors.orange.shade200),
                itemBuilder: (context, index) {
                  final returnItem = returns[index];
                  return InkWell(
                    onTap: () {
                      // Navigate to return detail
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => BlocProvider(
                                create:
                                    (_) =>
                                        sl<PurchaseReturnBloc>()..add(
                                          LoadPurchaseReturnById(returnItem.id),
                                        ),
                                child: PurchaseReturnDetailPage(
                                  returnId: returnItem.id,
                                ),
                              ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  returnItem.returnNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(returnItem.returnDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (returnItem.reason != null &&
                                    returnItem.reason!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Alasan: ${returnItem.reason}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getReturnStatusColor(
                                    returnItem.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getReturnStatusColor(
                                      returnItem.status,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  returnItem.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getReturnStatusColor(
                                      returnItem.status,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(returnItem.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                '${returnItem.items.length} item',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getReturnStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'DRAFT':
        return Colors.grey;
      default:
        return Colors.orange;
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
                BlocListener<PurchaseReturnBloc, PurchaseReturnState>(
                  listener: (context, state) {
                    if (state is PurchaseReturnLoaded) {
                      // Cache the returns for the receiving that was just loaded
                      if (_currentLoadingReceivingId != null) {
                        debugPrint(
                          'Loaded ${state.purchaseReturns.length} returns for receiving: $_currentLoadingReceivingId',
                        );
                        setState(() {
                          _receivingReturns[_currentLoadingReceivingId!] =
                              state.purchaseReturns;
                        });
                        _currentLoadingReceivingId = null;
                      }
                    } else if (state is PurchaseReturnError) {
                      debugPrint('Error loading returns: ${state.message}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error loading returns: ${state.message}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      _currentLoadingReceivingId = null;
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

                        return _buildReceivingCard(receiving);
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
