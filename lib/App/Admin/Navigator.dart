import 'package:flutter/material.dart';
import 'stok.dart';
import 'pengguna.dart';
import 'Dasboard.dart';

class AppBottomNavigator extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNavigator({
    super.key,
    required this.currentIndex,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Tambah'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stok'),
        BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Laporan'),
      ],
    );
  }
}

class MainScreen extends StatefulWidget {
  final dynamic user;
  const MainScreen({super.key, required this.user});
  
  @override 
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DashboardPage(user: widget.user),    // Index 0
      const PenggunaPage(),                // Index 1
      const StokPage(),                    // Index 2
      const Placeholder(child: Center(child: Text('Halaman Laporan'))), // Index 3
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNavigator(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}