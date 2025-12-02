import 'package:flutter/material.dart';
import 'stok.dart';
import 'pengguna.dart';
import 'Dasboard.dart';
import 'laporan.dart';

/// -------------------------------
/// BOTTOM NAVIGATOR
/// -------------------------------
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

/// -------------------------------
/// NAVIGATOR SCREEN
/// (Pengganti MainScreen)
/// -------------------------------
class NavigatorScreen extends StatefulWidget {
  final dynamic user;
  const NavigatorScreen({super.key, required this.user});
  
  @override 
  State<NavigatorScreen> createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // No swipe
        children: [
          DashboardPage(user: widget.user),
          PenggunaPage(),
          StokPage(), 
          LaporanPage(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigator(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}