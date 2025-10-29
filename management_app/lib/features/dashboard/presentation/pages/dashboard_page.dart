import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../../product/presentation/pages/product_list_page.dart';
import '../../../purchase/presentation/bloc/purchase_bloc.dart';
import '../../../purchase/presentation/pages/purchase_list_page.dart';
import '../../../receiving/presentation/pages/receiving_list_page.dart';
import '../../../supplier/presentation/bloc/supplier_bloc.dart';
import '../../../supplier/presentation/pages/supplier_list_page.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/presentation/pages/customer_list_page.dart';
import '../../../branch/presentation/bloc/branch_bloc.dart';
import '../../../branch/presentation/pages/branch_list_page.dart';
import '../../../user/presentation/pages/user_list_page.dart';
import '../bloc/dashboard_bloc.dart';
import 'management_home_page.dart';
import 'app_settings_page.dart';
import 'server_settings_page.dart';

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

  // Create BLoCs once and reuse
  late final DashboardBloc _dashboardBloc;
  late final CustomerBloc _customerBloc;
  late final SupplierBloc _supplierBloc;
  late final PurchaseBloc _purchaseBloc;
  late final PurchaseBloc _receivingBloc;

  @override
  void initState() {
    super.initState();
    // Initialize BLoCs once
    _dashboardBloc = sl<DashboardBloc>();
    _customerBloc = sl<CustomerBloc>();
    _supplierBloc = sl<SupplierBloc>();
    _purchaseBloc = sl<PurchaseBloc>();
    _receivingBloc = sl<PurchaseBloc>();

    // Load dashboard data immediately
    _dashboardBloc.add(LoadDashboardSummary());
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    _customerBloc.close();
    _supplierBloc.close();
    _purchaseBloc.close();
    _receivingBloc.close();
    super.dispose();
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
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                BlocProvider.value(
                  value: _dashboardBloc,
                  child: const ManagementHomePage(),
                ),
                const ProductListPageOptimized(),
                BlocProvider.value(
                  value: _customerBloc,
                  child: const CustomerListPage(),
                ),
                BlocProvider.value(
                  value: _supplierBloc,
                  child: const SupplierListPage(),
                ),
                BlocProvider.value(
                  value: _purchaseBloc,
                  child: const PurchaseListPage(),
                ),
                BlocProvider.value(
                  value: _receivingBloc,
                  child: const ReceivingListPage(),
                ),
                const ReportsPage(),
                const SettingsPage(),
              ],
            ),
          ),
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
            onTap: () {
              // TODO: Navigate to user profile page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur profil akan segera hadir')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.people_outline,
            title: 'Manajemen Pengguna',
            subtitle: 'Kelola user dan permissions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserListPage()),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.store,
            title: 'Manajemen Cabang',
            subtitle: 'Kelola data cabang/kantor pusat',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BlocProvider.value(
                        value: BlocProvider.of<BranchBloc>(context),
                        child: const BranchListPage(),
                      ),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.business,
            title: 'Identitas Aplikasi',
            subtitle: 'Nama, alamat, kontak toko, dan NPWP',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppSettingsPage(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.receipt_outlined,
            title: 'Pengaturan Printer',
            subtitle: 'Konfigurasi printer untuk cetak struk',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur printer settings akan segera hadir'),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            title: 'Pengaturan Server',
            subtitle: 'Konfigurasi Backend API dan WebSocket',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServerSettingsPage(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'POS Management App v2.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'POS Management',
                applicationVersion: '2.0.0',
                applicationIcon: const Icon(Icons.point_of_sale, size: 48),
                children: [
                  const Text('Enterprise Point of Sale Management System'),
                  const SizedBox(height: 8),
                  const Text('Backend: Node.js + PostgreSQL + Redis'),
                  const Text('Frontend: Flutter'),
                ],
              );
            },
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
