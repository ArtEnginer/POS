import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../domain/entities/sale.dart';
import '../bloc/sale_bloc.dart';
import '../bloc/sale_event.dart';
import '../bloc/sale_state.dart';
import 'pos_page.dart';
import 'sale_detail_page.dart';

class SaleListPage extends StatefulWidget {
  const SaleListPage({super.key});

  @override
  State<SaleListPage> createState() => _SaleListPageState();
}

class _SaleListPageState extends State<SaleListPage> {
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  void _loadSales() {
    if (_startDate != null && _endDate != null) {
      context.read<SaleBloc>().add(
        LoadSalesByDateRange(_startDate!, _endDate!),
      );
    } else {
      context.read<SaleBloc>().add(const LoadAllSales());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_sale_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider(create: (_) => sl<ProductBloc>()),
                      BlocProvider(create: (_) => sl<SaleBloc>()),
                      BlocProvider(create: (_) => sl<CustomerBloc>()),
                    ],
                    child: const POSPage(),
                  ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Transaksi Baru'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: BlocBuilder<SaleBloc, SaleState>(
              builder: (context, state) {
                if (state is SaleLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SaleError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSales,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is SaleLoaded) {
                  var sales = state.sales;

                  // Filter by status
                  if (_selectedStatus != 'ALL') {
                    sales =
                        sales
                            .where((sale) => sale.status == _selectedStatus)
                            .toList();
                  }

                  if (sales.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada transaksi',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      return _buildSaleCard(sales[index]);
                    },
                  );
                }

                return const Center(child: Text('Memuat transaksi...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nomor transaksi, pelanggan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadSales();
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                _loadSales();
              } else {
                context.read<SaleBloc>().add(SearchSales(value));
              }
            },
          ),
          const SizedBox(height: 12),
          // Filter Row
          Row(
            children: [
              // Date Range
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 20),
                  label: Text(
                    _startDate == null || _endDate == null
                        ? 'Pilih Tanggal'
                        : '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('Semua Status')),
                    DropdownMenuItem(
                      value: 'COMPLETED',
                      child: Text('Selesai'),
                    ),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('Batal')),
                    DropdownMenuItem(value: 'REFUNDED', child: Text('Refund')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Clear Filter
              if (_startDate != null || _endDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _loadSales();
                  },
                  tooltip: 'Hapus Filter',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    Color statusColor;
    String statusText;
    switch (sale.status) {
      case 'COMPLETED':
        statusColor = Colors.green;
        statusText = 'Selesai';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = 'Batal';
        break;
      case 'REFUNDED':
        statusColor = Colors.orange;
        statusText = 'Refund';
        break;
      default:
        statusColor = Colors.grey;
        statusText = sale.status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BlocProvider(
                    create: (_) => sl<SaleBloc>()..add(LoadSaleById(sale.id)),
                    child: const SaleDetailPage(),
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.saleNumber,
                          style: AppTextStyles.h6.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(sale.saleDate),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kasir: ${sale.cashierName}',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (sale.customerId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'ID Pelanggan: ${sale.customerId}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${sale.items.length} Item',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        currencyFormat.format(sale.total),
                        style: AppTextStyles.h5.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getPaymentMethodText(sale.paymentMethod),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'CASH':
        return 'Tunai';
      case 'CARD':
        return 'Kartu';
      case 'QRIS':
        return 'QRIS';
      case 'E_WALLET':
        return 'E-Wallet';
      default:
        return method;
    }
  }

  Future<void> _selectDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
      _loadSales();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
