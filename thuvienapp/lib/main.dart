import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:thuvienapp/screens/login_screen.dart';

// 1. Thay đổi import từ login_screen sang home_screen để test trực tiếp
import 'screens/KhachHang/home_screen.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print(
        "Không tìm thấy file .env. Hãy tạo file .env ở thư mục gốc và thêm GEMINI_API_KEY vào đó.");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
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
      theme: AppTheme.lightTheme,
      // 2. Sửa thuộc tính home này thành HomeScreen để khởi chạy thẳng vào trang chủ
      home: const LoginScreen(),
    );
  }
}
