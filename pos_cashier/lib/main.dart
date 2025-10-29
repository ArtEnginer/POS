import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/database/hive_service.dart';
import 'core/network/api_service.dart';
import 'core/socket/socket_service.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/auth_service.dart';
import 'core/utils/product_repository.dart';
import 'core/utils/app_settings.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/server_check_page.dart';
import 'features/server_settings_page.dart';
import 'features/cashier/presentation/bloc/cashier_bloc.dart';
import 'features/cashier/presentation/pages/cashier_page.dart';
import 'features/sync/data/datasources/sync_service.dart';

// Global services
late final ApiService apiService;
late final SocketService socketService;
late final AuthService authService;
late final ProductRepository productRepository;
late final SyncService syncService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Indonesian locale
  await initializeDateFormatting('id_ID', null);

  // Lock to landscape orientation for tablet/cashier mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide status bar for full-screen cashier experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Hive database (offline-first)
  await HiveService.instance.init();

  // Initialize services
  apiService = ApiService();

  // Update API base URL from settings (if configured)
  await apiService.updateBaseUrlFromSettings();

  // Initialize Socket.IO service
  socketService = SocketService(HiveService.instance);

  authService = AuthService(
    hiveService: HiveService.instance,
    apiService: apiService,
  );
  productRepository = ProductRepository(
    hiveService: HiveService.instance,
    apiService: apiService,
  );
  syncService = SyncService(
    hiveService: HiveService.instance,
    apiService: apiService,
    productRepository: productRepository,
    socketService: socketService, // Pass socket service
  );

  // Check if server has been configured OR if user has saved credentials
  final isServerConfigured = await AppSettings.isServerConfigured();
  final authBox = HiveService.instance.getBox(AppConstants.authBox);
  final hasSavedCredentials = authBox.get('saved_username') != null;

  // Restore session if exists
  final hasSession = await authService.restoreSession();
  if (hasSession) {
    print('✅ Session restored');

    // Check if session was offline or online
    final isOffline = authBox.get('is_offline', defaultValue: false);

    // Set online status based on saved mode
    syncService.setOnlineStatus(!isOffline);
    print(
      isOffline
          ? '📴 Restored session was OFFLINE mode'
          : '🟢 Restored session was ONLINE mode',
    );

    // Connect WebSocket and start sync for restored session
    try {
      await socketService.connect();
      print('🔌 WebSocket connected for restored session');
    } catch (e) {
      print('⚠️ WebSocket connection failed: $e');
    }

    syncService.startBackgroundSync();
    print('⏰ Background sync started for restored session');
  }

  runApp(
    POSCashierApp(
      isServerConfigured: isServerConfigured,
      hasSession: hasSession,
      hasSavedCredentials: hasSavedCredentials,
    ),
  );
}

class POSCashierApp extends StatelessWidget {
  final bool isServerConfigured;
  final bool hasSession;
  final bool hasSavedCredentials;

  const POSCashierApp({
    super.key,
    required this.isServerConfigured,
    required this.hasSession,
    required this.hasSavedCredentials,
  });

  @override
  Widget build(BuildContext context) {
    // Determine initial page based on configuration and session
    Widget initialPage;

    print('📍 Routing Decision:');
    print('   - Has Session: $hasSession');
    print('   - Has Saved Credentials: $hasSavedCredentials');
    print('   - Server Configured: $isServerConfigured');

    if (hasSession) {
      // Priority 1: Has active session - go directly to cashier
      print('   → Going to CASHIER PAGE (active session)');
      initialPage = const CashierPage();
    } else if (hasSavedCredentials) {
      // Priority 2: Has saved credentials - go to login (offline-capable)
      print('   → Going to LOGIN PAGE (has saved credentials)');
      initialPage = const LoginPage();
    } else if (!isServerConfigured) {
      // Priority 3: First time setup - need to configure server
      print('   → Going to SERVER CHECK PAGE (first time setup)');
      initialPage = const ServerCheckPage();
    } else {
      // Priority 4: Server configured but no credentials - go to login
      print('   → Going to LOGIN PAGE (no credentials)');
      initialPage = const LoginPage();
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (_) => CashierBloc(
                hiveService: HiveService.instance,
                syncService:
                    syncService, // Inject SyncService for real-time sync
              ),
        ),
      ],
      child: MaterialApp(
        title: 'POS Kasir',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: initialPage,
        routes: {
          '/cashier': (context) => const CashierPage(),
          '/login': (context) => const LoginPage(),
          '/server-check': (context) => const ServerCheckPage(),
          '/server-settings': (context) => const ServerSettingsPage(),
        },
      ),
    );
  }
}
