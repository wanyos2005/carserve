
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:driveon_car_platform/pages/main_service_nav.dart';

// Pages
import 'package:driveon_car_platform/pages/welcome_screen.dart';
import 'package:driveon_car_platform/pages/login_page.dart';
import 'package:driveon_car_platform/pages/home_page.dart';
import 'package:driveon_car_platform/pages/Insurance/c_insurance_policy_page.dart';
import 'package:driveon_car_platform/pages/ProviderPages/provider_homepage.dart';
import 'package:driveon_car_platform/pages/ProviderPages/provider_log_service_page.dart';
import 'package:driveon_car_platform/pages/Insurance/p_insurance_log_service_page.dart';
import 'package:driveon_car_platform/pages/AdminPages/admin_dashboard.dart';
import 'package:driveon_car_platform/pages/history_page.dart';
import 'package:driveon_car_platform/pages/expenses_page.dart';
import 'package:driveon_car_platform/pages/add_expense_page.dart';
import 'package:driveon_car_platform/pages/alerts_inbox_page.dart';
import 'package:driveon_car_platform/pages/ProviderPages/provider_settings_page.dart';

// Insurance Pages
import 'package:driveon_car_platform/pages/Insurance/insurance_dashboard.dart';
import 'package:driveon_car_platform/pages/Insurance/insurance_marketplace.dart';

// Services
import 'package:driveon_car_platform/services/user_context_service.dart';
import 'package:driveon_car_platform/services/storage_service.dart';
import 'package:driveon_car_platform/services/fcm_service.dart';
import 'package:driveon_car_platform/services/unified_permission_service.dart';
import 'package:driveon_car_platform/services/mpesa_sms_service.dart';


const abyssBlue = Color(0xFF0A192F); // dark navy blue

void main() async {
  // Initialize Flutter binding first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  await Firebase.initializeApp();
  
  // Initialize storage service
  await StorageService.initialize();
  runApp(const CarPlatformApp());
}

class CarPlatformApp extends StatefulWidget {
  const CarPlatformApp({super.key});

  @override
  State<CarPlatformApp> createState() => _CarPlatformAppState();
}

class _CarPlatformAppState extends State<CarPlatformApp> with WidgetsBindingObserver {
  UserContext? _userContext;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App resumed from background - refresh authentication state
      _refreshAuthenticationState();
    }
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Initialize user context first
      final userContext = await UserContextService.initializeContext();
      
      // 2. Request notification permission and initialize FCM
      await _initializeNotifications();

      // 3. Initialize M-Pesa SMS listener for provider (merchant) accounts
      if (userContext != null && userContext.isProvider) {
        await MpesaSmsService.initialize();
      }

      if (mounted) {
        setState(() {
          _userContext = userContext;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userContext = null;
          _isInitializing = false;
        });
      }
    }
  }
  
  Future<void> _initializeNotifications() async {
    try {
      // Request notification permission
      final notificationGranted = await UnifiedPermissionService.requestNotificationPermission();
      
      if (notificationGranted) {
        // Initialize FCM service
        await FCMService.initialize();
        print('✅ FCM service initialized successfully');
      } else {
        print('❌ Notification permission denied - FCM not initialized');
      }
    } catch (e) {
      print('❌ Failed to initialize notifications: $e');
    }
  }

  Future<void> _refreshAuthenticationState() async {
    try {
      final userContext = await UserContextService.refreshContext();
      
      // If user is now logged in, try to initialize FCM
      if (userContext != null && userContext.userType != UserType.unknown) {
        await _initializeNotifications();
      }
      
      if (mounted) {
        setState(() {
          _userContext = userContext;
        });
      }
    } catch (e) {
      // If refresh fails, try to reinitialize
      await _initializeApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Car Platform",
      theme: _buildLightTheme(),     // Light theme
      darkTheme: _buildDarkTheme(),  // Dark theme
      themeMode: ThemeMode.system,
      routes: {
        "/welcome": (context) => const WelcomeScreen(),
        "/login": (context) => const LoginPage(),
        "/home": (context) => const HomePage(),
        "/insurance": (context) => const CInsurancePolicyPage(),
        "/services": (context) => const MainServiceNav(),
        
        // Insurance Routes
        "/insurance/dashboard": (context) => const InsuranceDashboard(),
        "/insurance/marketplace": (context) => const InsuranceMarketplace(),
        
        // Expenses Routes
        "/expenses": (context) => const ExpensesPage(),
        "/expenses/add": (context) => const AddExpensePage(),
        
        // Alerts Routes
        "/alerts": (context) => const AlertsInboxPage(),
        
        // Provider Routes
        "/provider-log-service": (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final providerId = args?['providerId'] as String?;
          if (providerId == null) {
            return const Scaffold(
              body: Center(child: Text('Provider ID is required')),
            );
          }
          return ProviderLogServicePage(providerId: providerId);
        },
        "/insurance-log-service": (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final providerId = args?['providerId'] as String?;
          if (providerId == null) {
            return const Scaffold(
              body: Center(child: Text('Provider ID is required')),
            );
          }
          return PInsuranceLogServicePage(providerId: providerId);
        },
        "/history": (context) => const HistoryPage(),
        "/provider-settings": (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final providerId = args?['providerId'] as String?;
          if (providerId == null) {
            return const Scaffold(
              body: Center(child: Text('Provider ID is required')),
            );
          }
          return ProviderSettingsPage(providerId: providerId);
        },
       
      },
      home: _buildHomeWidget(),
    );
  }

  Widget _buildHomeWidget() {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    
    if (_userContext != null && _userContext!.userType != UserType.unknown) {
      // User is logged in - route based on user type
      if (_userContext!.isAdmin) {
        return const AdminDashboard();
      } else if (_userContext!.isProvider && _userContext!.providerId != null) {
        return ProviderHomePage(providerId: _userContext!.providerId!);
      } else {
        return const HomePage();
      }
    } else {
      // User is not logged in - show welcome screen
      return const WelcomeScreen();
    }
  }

  // 🌞 Light theme - Enhanced to match service selector design
  ThemeData _buildLightTheme() {
    const primaryAccent = Color(0xFFD32F2F); // red to match enhanced design

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: Colors.grey[50], // Lighter background
      fontFamily: 'Poppins',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
        titleLarge: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2, // Reduced elevation for cleaner look
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shadowColor: Colors.black.withOpacity(0.05), // Subtle shadow
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          minimumSize: const Size(120, 48), // Minimum button size
        ),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        brightness: Brightness.light,
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        labelStyle: TextStyle(color: Colors.black54),
        hintStyle: TextStyle(color: Colors.black38),
      ),
    );
  }

  // 🌑 Dark theme
  ThemeData _buildDarkTheme() {
    const primaryAccent = Color(0xFFD32F2F); // red
    const darkBg = Color(0xFF121212);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Poppins',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: abyssBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),


      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          minimumSize: const Size(120, 48), // Minimum button size
        ),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        brightness: Brightness.dark,
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white38),
      ),
    );
  }
}
