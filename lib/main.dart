import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';

/// App Entry Point
/// This is the first function that runs when the Flutter application starts.
void main() async {
  // Ensure that Flutter widget binding is initialized before calling async code
  WidgetsFlutterBinding.ensureInitialized();

  // Configure device status bar and bottom navigation bar colors for a seamless look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar for edge-to-edge design
      statusBarIconBrightness: Brightness.dark, // Dark status icons (time, battery, wifi)
      systemNavigationBarColor: Colors.white, // White bottom navigation bar on Android
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 1. Initialize API configuration (loads saved server URL or defaults to localhost:5001)
  await ApiConfig.init();

  // 2. Initialize HTTP Client (loads saved Bearer token from local storage)
  await ApiClient().init();

  // 3. Launch the root widget of the Flutter application
  runApp(const TransnovaApp());
}

/// Root Application Widget
/// Sets up Global State Management (Provider), Theme, and App Navigation Routing.
class TransnovaApp extends StatelessWidget {
  const TransnovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider injects all shared state providers at the very top of the widget tree
    // so any screen or component can easily access them via context.watch() or context.read().
    return MultiProvider(
      providers: [
        // AuthProvider: Manages user login, registration, token persistence, and session check
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // WalletProvider: Manages Circle Smart Contract Accounts (SCA), USDC balance, and Polygon address
        ChangeNotifierProvider(create: (_) => WalletProvider()),

        // TransactionProvider: Manages transfer execution, gas fee estimation, and transaction activity history
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'Transnova E-Wallet',
        debugShowCheckedModeBanner: false, // Hides the debug banner in top right corner
        theme: AppTheme.lightTheme, // Applies the high-fidelity Figma Fintech Coral theme
        builder: (context, child) {
          final size = MediaQuery.of(context).size;
          // On desktop / wide web browsers, frame the mobile app into a modern smartphone viewport
          if (size.width > 500) {
            return Scaffold(
              backgroundColor: const Color(0xFFF0F2F6),
              body: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 430, maxHeight: 920),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 38,
                        spreadRadius: 2,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E5EB), width: 1.5),
                  ),
                  child: child!,
                ),
              ),
            );
          }
          return child!;
        },
        home: const SplashScreen(), // Starts with the animated splash screen to check session
      ),
    );
  }
}
