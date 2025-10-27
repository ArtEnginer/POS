import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../product/presentation/pages/product_list_page.dart';
import '../../../purchase/presentation/bloc/purchase_bloc.dart';
import '../../../purchase/presentation/pages/purchase_list_page.dart';
import '../../../purchase/presentation/pages/receiving_list_page.dart';
import '../../../supplier/presentation/bloc/supplier_bloc.dart';
import '../../../supplier/presentation/pages/supplier_list_page.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/presentation/pages/customer_list_page.dart';

/// Management Dashboard - For data management only (No POS/Cashier)
/// This app is for managing products, purchases, receiving, suppliers, customers
/// For POS/Cashier functionality, use the POS App
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages for MANAGEMENT ONLY
    _pages = [
      const ManagementHomePage(), // Dashboard overview
      const ProductListPage(),
      BlocProvider(
        create: (_) => sl<CustomerBloc>(),
        child: const CustomerListPage(),
      ),
      BlocProvider(
        create: (_) => sl<SupplierBloc>(),
        child: const SupplierListPage(),
      ),
      BlocProvider(
        create: (_) => sl<PurchaseBloc>(),
        child: const PurchaseListPage(),
      ),
      BlocProvider(
        create: (_) => sl<PurchaseBloc>(),
        child: const ReceivingListPage(),
      ),
      const ReportsPage(),
      const SettingsPage(),
    ];
  }

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _NavItem(icon: Icons.inventory_2_outlined, label: 'Produk'),
    _NavItem(icon: Icons.people_outline, label: 'Customer'),
    _NavItem(icon: Icons.business_outlined, label: 'Supplier'),
    _NavItem(icon: Icons.shopping_cart_outlined, label: 'Pembelian'),
    _NavItem(icon: Icons.move_to_inbox, label: 'Receiving'),
    _NavItem(icon: Icons.analytics_outlined, label: 'Laporan'),
    _NavItem(icon: Icons.settings_outlined, label: 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              backgroundColor: AppColors.surface,
              selectedIconTheme: const IconThemeData(
                color: AppColors.primary,
                size: 28,
              ),
              selectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              unselectedIconTheme: IconThemeData(
                color: AppColors.textSecondary,
                size: 24,
              ),
              unselectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              labelType: NavigationRailLabelType.all,
              destinations:
                  _navItems
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
            ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar:
          isWideScreen
              ? null
              : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
                items:
                    _navItems
                        .map(
                          (item) => BottomNavigationBarItem(
                            icon: Icon(item.icon),
                            label: item.label,
                          ),
                        )
                        .toList(),
              ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}

// Management Dashboard Home Page - Overview of business metrics
class ManagementHomePage extends StatelessWidget {
  const ManagementHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Manajemen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Refresh dashboard data
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang di Sistem Manajemen POS',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola data produk, pembelian, supplier, dan customer',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Total Produk',
                    value: '-',
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Purchase Order',
                    value: '-',
                    color: AppColors.info,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    icon: Icons.move_to_inbox,
                    title: 'Receiving',
                    value: '-',
                    color: AppColors.success,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    icon: Icons.people_outline,
                    title: 'Customer',
                    value: '-',
                    color: AppColors.accent,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    icon: Icons.business_outlined,
                    title: 'Supplier',
                    value: '-',
                    color: AppColors.warning,
                    onTap: () {},
                  ),
                  _DashboardCard(
                    icon: Icons.low_priority,
                    title: 'Stok Rendah',
                    value: '-',
                    color: AppColors.error,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text('Laporan & Analitik', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            Text(
              'Laporan penjualan, pembelian, dan inventory',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Coming Soon...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Profil Pengguna',
            subtitle: 'Kelola informasi akun Anda',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.store_outlined,
            title: 'Informasi Toko',
            subtitle: 'Nama, alamat, dan kontak toko',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.receipt_outlined,
            title: 'Pengaturan Struk',
            subtitle: 'Kustomisasi tampilan struk',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            title: 'Backend Server',
            subtitle: 'Node.js + PostgreSQL + Socket.IO',
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Backend Server'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('API: http://localhost:3001/api/v2'),
                          const SizedBox(height: 8),
                          Text('Socket: ws://localhost:3001'),
                          const SizedBox(height: 8),
                          Text('Database: PostgreSQL'),
                          const SizedBox(height: 8),
                          Text('Cache: Redis'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'POS Management App v2.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTextStyles.labelLarge),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
