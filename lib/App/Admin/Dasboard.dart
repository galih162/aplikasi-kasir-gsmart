import 'package:flutter/material.dart';
import 'package:gs_mart_aplikasi/screens/home.dart';
import 'pengguna.dart';

class DashboardPage extends StatefulWidget {
  final dynamic user; // Sesuaikan tipe data dengan model User Anda
  
  const DashboardPage({Key? key, required this.user}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // ✅ TAMBAHKAN METHOD NAVIGASI DI SINI
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0:
        
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PenggunaPage()),
        );
        break;
      // case 2:
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) => StockPage()), // Ganti dengan halaman stok
      //   );
      //   break;
      // case 3:
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) => ReportPage()), // Ganti dengan halaman laporan
      //   );
      //   break;
    }
  }

  final List<ChartData> chartData = [
    ChartData('Sen', 400),
    ChartData('Sel', 200),
    ChartData('Rab', 500),
    ChartData('Kam', 100),
    ChartData('Jum', 100),
    ChartData('Sab', 100),
    ChartData('Min', 300),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 235, 25, 10),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => KasirDashboard(user: widget.user),
              ),
            );
          },
        ),
        title: const Text(
          'Statistik',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Card
            Card(
              color: const Color.fromARGB(230, 250, 250, 250),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: chartData.map((data) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: (data.value / 500) * 150,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 235, 25, 10),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    data.day,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0k', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        Text('100k', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        Text('200k', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        Text('300k', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        Text('400k', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        Text('500k', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistics Card
            Container(
              width: 400.0,
              child: Card(
                color:   Color.fromARGB(230, 250, 250, 250),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Statiska Hari ini',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 235, 25, 10),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10,
                      ),
                      Text(
                        'Rp 1.000.000',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Info Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 1,
                    color: const Color.fromARGB(230, 250, 250, 250),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengguna aktif',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: const [
                              Icon(
                                Icons.person_add,
                                color: const Color.fromARGB(255, 235, 25, 10),
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 235, 25, 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 1,
                    color: const Color.fromARGB(230, 250, 250, 250),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Stok',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: const [
                              Icon(
                                Icons.inventory_2,
                                color: Colors.red,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: _onItemTapped, // ✅ GUNAKAN METHOD _onItemTapped YANG SUDAH DIBUAT
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Tambah',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Stok',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String day;
  final double value;

  ChartData(this.day, this.value);
}
