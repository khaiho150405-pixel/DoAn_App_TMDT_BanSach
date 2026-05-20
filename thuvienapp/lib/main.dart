import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/user_provider.dart';
import 'providers/admin_user_provider.dart';
import 'providers/promotion_provider.dart';
import 'screens/admin/admin_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint(
        'Missing .env file. Add it at the Flutter project root if needed.');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
        ChangeNotifierProvider(create: (_) => PromotionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-BookStore Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
          color: Colors.white,
        ),
      ),
      home: const AdminMainScreen(),
      routes: {
        '/admin-dashboard': (_) => const AdminMainScreen(),
      },
    );
  }
}
