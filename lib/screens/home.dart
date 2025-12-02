import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gs_mart_aplikasi/models/user.dart';
import 'package:gs_mart_aplikasi/models/products.dart';
import 'package:gs_mart_aplikasi/database/cart_provider.dart';
import 'package:gs_mart_aplikasi/utils/constants.dart';
import 'package:gs_mart_aplikasi/database/auth_provider.dart';
import 'package:gs_mart_aplikasi/database/product_service.dart';
import 'package:gs_mart_aplikasi/App/Admin/Navigator.dart';
import 'cart_page.dart';

class KasirDashboard extends StatefulWidget {
  final UserModel user;

  const KasirDashboard({Key? key, required this.user}) : super(key: key);

  @override
  State<KasirDashboard> createState() => _KasirDashboardState();
}

class _KasirDashboardState extends State<KasirDashboard> {
  String selectedCategory = 'Sayuran';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  int selectedBottomIndex = 1;
  List<ProductModel> allProducts = [];
  bool isLoadingProducts = true;

  final List<String> categories = ['Sayuran', 'Buah', 'Daging'];

  Color primaryColorWithOpacity(double opacity) {
    return primaryColor.withOpacity(opacity);
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    print("=== DEBUG _loadProducts ===");

    setState(() => isLoadingProducts = true);

    final products = await ProductService().getAllProducts();

    print("Response type: ${products.runtimeType}");
    print("Response value: $products");

    setState(() {
      allProducts = products; // <-- langsung assign, JANGAN diparse lagi
      isLoadingProducts = false;
    });
  }

  List<ProductModel> get filteredProducts {
    if (allProducts.isEmpty) return [];

    return allProducts.where((p) {
      // Null safety untuk semua properti
      final category = p.kategori?.toLowerCase() ?? '';
      final productName = p.namaProduk?.toLowerCase() ?? '';
      final selectedCategoryLower = selectedCategory.toLowerCase();
      final searchLower = searchQuery.toLowerCase();

      final matchCat = category == selectedCategoryLower;
      final matchSearch =
          searchQuery.isEmpty || productName.contains(searchLower);

      return matchCat && matchSearch;
    }).toList();
  }

  void addToCart(ProductModel product) {
    context.read<CartProvider>().addOrIncrement(product, context);
  }

  // HAPUS method _showProfileDialog karena tidak digunakan
  // void _showProfileDialog() { ... }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Tambah mounted check sebelum logout
      if (!mounted) return;

      await Provider.of<AuthProvider>(context, listen: false).logout();

      // Tambah mounted check sebelum navigate
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().items.length;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(cartItemCount),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (selectedBottomIndex == 1) {
      return AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProducts,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Klik untuk mencari',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = selectedCategory == category;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : primaryColorWithOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : primaryColorWithOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? primaryColor : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return AppBar(
        leading: Container(),
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          selectedBottomIndex == 0 ? 'Statistik' : 'Profil',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  Widget _buildBody() {
    switch (selectedBottomIndex) {
      case 1:
        return _buildProductGrid();
      case 2:
        return _buildProfilePage();
      default:
        return _buildProductGrid();
    }
  }

  Widget _buildProductGrid() {
    // DEBUG
    print('=== DEBUG _buildProductGrid ===');
    print('isLoadingProducts: $isLoadingProducts');
    print('allProducts length: ${allProducts.length}');

    if (isLoadingProducts) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (allProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'Belum ada produk',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final filtered = filteredProducts;
    print('filteredProducts length: ${filtered.length}');

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'Tidak ada produk untuk kategori "$selectedCategory"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Dengan kata kunci: "$searchQuery"',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  searchController.clear();
                });
              },
              child: const Text('Reset Pencarian'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.70,
      ),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final product = filtered[i];

        // DEBUG per product
        print(
            'Product $i: ${product.namaProduk}, Kategori: ${product.kategori}');

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar produk
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 40),
                            ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.namaProduk,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.kategori != null &&
                        product.kategori!.isNotEmpty)
                      Text(
                        product.kategori!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatRupiah(product.hargaJual),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: accentColor,
                          ),
                        ),
                        Text(
                          'Stok: ${product.stokTersedia}',
                          style: TextStyle(
                            fontSize: 14,
                            color: product.stokTersedia > 0
                                ? Colors.blue
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilePage() {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: primaryColor,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              widget.user.nama,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColorWithOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.user.jabatan.toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildBottomNavigationBar(int cartItemCount) {
  final isAdmin = widget.user.jabatan.toLowerCase() == 'admin';

  return BottomNavigationBar(
    currentIndex: selectedBottomIndex,
    onTap: (index) {
      if (index == 0) {
        // Jika Admin, ke NavigatorScreen; jika Kasir, ke Statistik
        if (isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NavigatorScreen(user: widget.user),
            ),
          );
        } else {
          setState(() => selectedBottomIndex = index);
        }
      } else if (index == 1) {
        // Produk - TETAP di halaman KasirDashboard (tampilan produk)
        setState(() => selectedBottomIndex = index);
      } else if (index == 2) {
        // Profil - TETAP di halaman KasirDashboard (tampilan profil)
        setState(() => selectedBottomIndex = index);
      }
    },
    items: [
      BottomNavigationBarItem(
        icon: const Icon(Icons.bar_chart),
        label: isAdmin ? 'Dashboard' : 'Statistik',
      ),
      BottomNavigationBarItem(
        icon: Badge(
          label: cartItemCount > 0 ? Text('$cartItemCount') : null,
          isLabelVisible: cartItemCount > 0,
          child: const Icon(Icons.store),
        ),
        label: 'Produk',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profil',
      ),
    ],
  );
}
}