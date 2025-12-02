import 'package:flutter/material.dart';
import 'package:gs_mart_aplikasi/App/Admin/Navigator.dart';
import 'package:gs_mart_aplikasi/screens/loading_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:gs_mart_aplikasi/database/auth_provider.dart'; // AuthProvider yang sudah benar
import 'package:gs_mart_aplikasi/database/cart_provider.dart';
import 'package:gs_mart_aplikasi/database/supabase_config.dart'; 
import 'screens/login_screen.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AppSupabase.initialize();
  await initializeDateFormatting('id_ID');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GSMart',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const AppWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const AppWrapper(),
        '/dashboard': (context) {
          final auth = context.read<AuthProvider>();
          // Periksa apakah currentUser tidak null sebelum mengakses
          if (auth.currentUser != null) {
            return KasirDashboard(user: auth.currentUser!);
          } else {
            return const LoginScreen();
          }
        },
        '/admin': (context) {
          final auth = context.read<AuthProvider>();
          // Periksa apakah currentUser tidak null sebelum mengakses
          if (auth.currentUser != null) {
            return NavigatorScreen(user: auth.currentUser!);
          } else {
            return const LoginScreen();
          }
        },
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Page not found: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Panggil checkSession() di AuthProvider
      context.read<AuthProvider>().checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Gunakan isLoading dari AuthProvider Anda
        if (auth.isLoading) {
          return const LoadingScreen();
        }

        // Cek apakah user sudah login
        if (auth.currentUser != null) {
          return KasirDashboard(user: auth.currentUser!);
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}