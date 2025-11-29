import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gs_mart_aplikasi/database/service.dart';
import 'package:gs_mart_aplikasi/screens/loading_screen.dart';
import 'package:gs_mart_aplikasi/screens/login_screen.dart';
import 'package:gs_mart_aplikasi/screens/home.dart';
import 'package:gs_mart_aplikasi/App/Admin/navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..checkSession(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GSMart',
        theme: ThemeData(primarySwatch: Colors.red),
        home: const AppWrapper(),
        // Define all your named routes here
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const AppWrapper(),
          '/dashboard': (context) {
            final auth = context.read<AuthProvider>();
            return KasirDashboard(user: auth.currentUser!);
          },
           '/admin': (context) { // ✅ TAMBAH ROUTE KE ADMIN
            final auth = context.read<AuthProvider>();
            return MainScreen(user: auth.currentUser!);
          },
        },
        // Handle unknown routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text('Page not found: ${settings.name}'),
              ),
            ),
          );
        },
      ),
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
      context.read<AuthProvider>().checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading || !auth.isInitialized) {
          return const LoadingScreen();
        }

        return auth.isAuthenticated
            ? KasirDashboard(user: auth.currentUser!)
            : const LoginScreen();
      },
    );
  }
}