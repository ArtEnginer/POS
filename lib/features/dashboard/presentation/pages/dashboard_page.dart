import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/pages/product_list_page.dart';
import '../../../purchase/presentation/bloc/purchase_bloc.dart';
import '../../../purchase/presentation/pages/purchase_list_page.dart';
import '../../../purchase/presentation/pages/receiving_list_page.dart';
import '../../../sales/presentation/bloc/sale_bloc.dart';
import '../../../sales/presentation/pages/pos_page.dart';
import '../../../sales/presentation/pages/sale_list_page.dart';
import '../../../supplier/presentation/bloc/supplier_bloc.dart';
import '../../../supplier/presentation/pages/supplier_list_page.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/presentation/pages/customer_list_page.dart';
import 'mysql_settings_page.dart';

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
    // Initialize pages once
    _pages = [
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<ProductBloc>()),
          BlocProvider(create: (_) => sl<SaleBloc>()),
          BlocProvider(create: (_) => sl<CustomerBloc>()),
        ],
        child: const POSPage(),
      ),
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
      BlocProvider(create: (_) => sl<SaleBloc>(), child: const SaleListPage()),
      const ReportsPage(),
      const SettingsPage(),
    ];
  }

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.point_of_sale, label: 'Kasir'),
    _NavItem(icon: Icons.inventory_2_outlined, label: 'Produk'),
    _NavItem(icon: Icons.people_outline, label: 'Customer'),
    _NavItem(icon: Icons.business_outlined, label: 'Supplier'),
    _NavItem(icon: Icons.shopping_cart_outlined, label: 'Pembelian'),
    _NavItem(icon: Icons.move_to_inbox, label: 'Receiving'),
    _NavItem(icon: Icons.receipt_long, label: 'Transaksi'),
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
                color: AppColors.textSecondary.withOpacity(0.7),
                size: 24,
              ),
              unselectedLabelTextStyle: AppTextStyles.labelMedium.copyWith(
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
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar:
          isWideScreen
              ? null
              : NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.primary.withOpacity(0.1),
                destinations:
                    _navItems
                        .map(
                          (item) => NavigationDestination(
                            icon: Icon(item.icon),
                            label: item.label,
                            selectedIcon: Icon(
                              item.icon,
                              color: AppColors.primary,
                            ),
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

// Placeholder pages - akan kita develop nanti
class CashierPage extends StatelessWidget {
  const CashierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {},
            tooltip: 'Scan Barcode',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {},
            tooltip: 'Sinkronisasi',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.point_of_sale,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text('Halaman Kasir', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            Text(
              'Coming Soon...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
            tooltip: 'Tambah Produk',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text('Manajemen Produk', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            Text(
              'Coming Soon...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text('Riwayat Transaksi', style: AppTextStyles.h4),
            const SizedBox(height: 10),
            Text(
              'Coming Soon...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
              'Coming Soon...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
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
          // MySQL Settings - BARU!
          _SettingsTile(
            icon: Icons.cloud_sync,
            title: 'MySQL Server',
            subtitle: 'Konfigurasi sinkronisasi dengan MySQL',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MySQLSettingsPage(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.sync,
            title: 'Sinkronisasi',
            subtitle: 'Atur sinkronisasi data',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.receipt_outlined,
            title: 'Pengaturan Struk',
            subtitle: 'Kustomisasi tampilan struk',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'Versi & informasi aplikasi',
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
