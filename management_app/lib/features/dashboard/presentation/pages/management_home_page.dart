import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/dashboard_bloc.dart';

class ManagementHomePage extends StatefulWidget {
  const ManagementHomePage({super.key});

  @override
  State<ManagementHomePage> createState() => _ManagementHomePageState();
}

class _ManagementHomePageState extends State<ManagementHomePage> {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Manajemen'),
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed:
                    state is DashboardLoading
                        ? null
                        : () {
                          context.read<DashboardBloc>().add(
                            RefreshDashboardSummary(),
                          );
                        },
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Gagal memuat data', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<DashboardBloc>().add(LoadDashboardSummary());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is DashboardLoaded) {
            final summary = state.summary;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(RefreshDashboardSummary());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeader(summary),
                    const SizedBox(height: 24),

                    // Quick Stats Grid
                    _buildStatsGrid(summary, isWideScreen),
                    const SizedBox(height: 24),

                    // Financial Overview
                    if (isWideScreen) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildFinancialCard(
                              'Total Pembelian',
                              summary.totalPurchaseAmount,
                              Icons.shopping_cart_outlined,
                              AppColors.info,
                              '${summary.totalPurchases} transaksi',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFinancialCard(
                              'Total Penjualan',
                              summary.totalSalesAmount,
                              Icons.point_of_sale,
                              AppColors.success,
                              '${summary.totalSales} transaksi',
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildFinancialCard(
                        'Total Pembelian',
                        summary.totalPurchaseAmount,
                        Icons.shopping_cart_outlined,
                        AppColors.info,
                        '${summary.totalPurchases} transaksi',
                      ),
                      const SizedBox(height: 12),
                      _buildFinancialCard(
                        'Total Penjualan',
                        summary.totalSalesAmount,
                        Icons.point_of_sale,
                        AppColors.success,
                        '${summary.totalSales} transaksi',
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Alerts Section
                    if (summary.lowStockProducts > 0 ||
                        summary.pendingPurchases > 0)
                      _buildAlertsSection(summary),
                  ],
                ),
              ),
            );
          }

          // Initial state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.dashboard_outlined,
                  size: 80,
                  color: AppColors.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text('Dashboard Manajemen', style: AppTextStyles.h4),
                const SizedBox(height: 10),
                Text(
                  'Tekan refresh untuk memuat data',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.update, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              'Terakhir diperbarui: ${_formatDateTime(summary.lastUpdated)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(summary, bool isWideScreen) {
    final stats = [
      _StatItem(
        icon: Icons.inventory_2_outlined,
        title: 'Total Produk',
        value: summary.totalProducts.toString(),
        color: AppColors.primary,
      ),
      _StatItem(
        icon: Icons.people_outline,
        title: 'Customer',
        value: summary.totalCustomers.toString(),
        color: AppColors.accent,
      ),
      _StatItem(
        icon: Icons.business_outlined,
        title: 'Supplier',
        value: summary.totalSuppliers.toString(),
        color: AppColors.warning,
      ),
      _StatItem(
        icon: Icons.low_priority,
        title: 'Stok Rendah',
        value: summary.lowStockProducts.toString(),
        color: AppColors.error,
        alert: summary.lowStockProducts > 0,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(stat);
      },
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Card(
      elevation: stat.alert ? 4 : 2,
      color: stat.alert ? stat.color.withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            stat.alert
                ? BorderSide(color: stat.color, width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: stat.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(stat.icon, size: 24, color: stat.color),
                  ),
                  if (stat.alert)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stat.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ALERT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                stat.title,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat.value,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: stat.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialCard(
    String title,
    double amount,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                Icon(Icons.trending_up, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: AppTextStyles.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perhatian',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (summary.lowStockProducts > 0)
          _buildAlertCard(
            icon: Icons.inventory_outlined,
            title: 'Produk Stok Rendah',
            message:
                '${summary.lowStockProducts} produk memiliki stok di bawah minimum',
            color: AppColors.error,
            actionLabel: 'Lihat Detail',
            onTap: () {},
          ),
        if (summary.pendingPurchases > 0) ...[
          const SizedBox(height: 12),
          _buildAlertCard(
            icon: Icons.pending_actions,
            title: 'Purchase Order Pending',
            message: '${summary.pendingPurchases} PO menunggu persetujuan',
            color: AppColors.warning,
            actionLabel: 'Proses',
            onTap: () {},
          ),
        ],
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
      return formatter.format(dateTime);
    }
  }
}

class _StatItem {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool alert;

  _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.alert = false,
  });
}
