import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gs_mart_aplikasi/App/Admin/Navigator.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:math';
import 'package:gs_mart_aplikasi/database/auth_provider.dart';
import 'package:gs_mart_aplikasi/database/product_service.dart';
import 'package:gs_mart_aplikasi/models/user.dart';

const Color primaryColor = Color.fromARGB(255, 235, 23, 19);
const Color accentColor = Color(0xFF4CAF50);

String formatRupiah(double amount) {
  return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

// ----- CLASS MODEL (Product & CartItem) -----

class Product {
  final String id;
  final String kodeProduk;
  final String namaProduk;
  final String deskripsi;
  final double hargaBeli;
  final double hargaJual;
  final String kategori;
  final String satuan;
  final int stok;
  final String? imageUrl;

  Product(
      {required this.id,
      required this.kodeProduk,
      required this.namaProduk,
      required this.deskripsi,
      required this.hargaBeli,
      required this.hargaJual,
      required this.kategori,
      required this.satuan,
      required this.stok,
      this.imageUrl});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
        id: json['id'] as String? ?? '',
        kodeProduk: json['kode_produk'] as String? ?? '',
        namaProduk: json['nama_produk'] as String? ?? '',
        deskripsi: json['deskripsi'] as String? ?? '',
        hargaBeli: (json['harga_beli'] ?? 0).toDouble(),
        hargaJual: (json['harga_jual'] ?? 0).toDouble(),
        kategori: json['kategori'] as String? ?? '',
        satuan: json['satuan'] as String? ?? '',
        stok: (json['stok_tersedia'] ?? 0) as int,
        imageUrl: json['image_url'] as String?);
  }

  String get emoji {
    final lower = namaProduk.toLowerCase();
    if (lower.contains('tomat')) return '🍅';
    if (lower.contains('cabai')) return '🌶️';
    if (lower.contains('rambutan') || lower.contains('anggur')) return '🍇';
    if (lower.contains('bawang')) return '🧅';
    if (lower.contains('apel')) return '🍎';
    if (lower.contains('sapi')) return '🥩';
    if (lower.contains('ayam')) return '🍗';
    return '📦';
  }
}

class CartItem {
  final Product product;
  int quantity;
  double diskonPersen;

  CartItem({required this.product, this.quantity = 1, this.diskonPersen = 0});

  double get subtotal => product.hargaJual * quantity;
  double get diskonRupiah => subtotal * (diskonPersen / 100);
  double get total => subtotal - diskonRupiah;

  // Update imageUrl untuk menggunakan yang dari Product
  String? get imageUrl => product.imageUrl;
}

// ----- PROVIDER UNTUK KERANJANG -----

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  void addOrIncrement(Product product, BuildContext context) {
    final idx = _items.indexWhere((i) => i.product.id == product.id);
    int currentQtyInCart = idx != -1 ? _items[idx].quantity : 0;

    if (product.stok > currentQtyInCart) {
      if (idx != -1) {
        _items[idx].quantity++;
      } else {
        _items.add(CartItem(product: product));
      }
      notifyListeners();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Stok ${product.namaProduk} tidak mencukupi'),
            backgroundColor: Colors.orange),
      );
    }
  }

  void incrementQuantity(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      final item = _items[idx];
      if (item.product.stok > item.quantity) {
        item.quantity++;
        notifyListeners();
      }
    }
  }

  void decrementQuantity(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      final item = _items[idx];
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _items.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get subtotalCart => _items.fold(0, (s, i) => s + i.subtotal);
  double get totalDiscount => _items.fold(0, (s, i) => s + i.diskonRupiah);
  double get totalPayment => _items.fold(0, (s, i) => s + i.total);
}

// ----- CUSTOM PAINTER (Gelombang Merah) -----
// Anda perlu menambahkan class WavePainter ini
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();

    path.lineTo(0, size.height * 0.5);
    // Gelombang 1
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.75,
        size.width * 0.5, size.height * 0.5);
    // Gelombang 2
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.25, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----- HALAMAN UTAMA (KASIR DASHBOARD) - Tampilan Produk -----

class KasirDashboard extends StatefulWidget {
  final UserModel user; // Ubah tipe data menjadi UserModel

  const KasirDashboard({Key? key, required this.user}) : super(key: key);

  @override
  State<KasirDashboard> createState() => _KasirDashboardState();
}

class _KasirDashboardState extends State<KasirDashboard> {
  String selectedCategory = 'Sayuran';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  int selectedBottomIndex = 1; // Default ke Produk
  List<Product> allProducts = [];
  bool isLoadingProducts = true;

  Widget _buildProductImage(Product product) {
    final imageUrl = product.imageUrl;
    debugPrint('🖼️ Image URL: ${product.imageUrl}');

    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        Uri.tryParse(imageUrl)?.hasAbsolutePath == true) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => _buildImagePlaceholder(product),
        ),
      );
    }

    return _buildImagePlaceholder(product);
  }

  Widget _buildImagePlaceholder(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Center(
        child: Text(
          product.emoji,
          style: const TextStyle(fontSize: 60),
        ),
      ),
    );
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
    setState(() => isLoadingProducts = true);
    try {
      final productService = ProductService();
      final productsData = await productService.getAllProductsWithStock();

      setState(() {
        allProducts = productsData.map((e) => Product.fromJson(e)).toList();
        isLoadingProducts = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e')),
        );
      }
    }
  }

  List<Product> get filteredProducts {
    return allProducts.where((p) {
      final matchCat =
          p.kategori.toLowerCase() == selectedCategory.toLowerCase();
      final matchSearch = searchQuery.isEmpty ||
          p.namaProduk.toLowerCase().contains(searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  // Menambahkan logika ke CartProvider
  void addToCart(Product product) {
    context.read<CartProvider>().addOrIncrement(product, context);
  }

// Update method _showProfileDialog() dengan fitur logout
  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color.fromARGB(255, 248, 5, 1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.user.nama,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.email, color: Color.fromARGB(255, 247, 5, 1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.user.email,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.badge,
                    color: Color.fromARGB(255, 235, 23, 19)),
                const SizedBox(width: 8),
                Text(
                  widget.user.jabatan.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 235, 23, 19),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 235, 23, 19),
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await Provider.of<AuthProvider>(context, listen: false)
                    .logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showAdminProductMenu(Product p) {
    // Implementasi menu admin
  }

  Widget _buildCategoryTab(String label) {
    final bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label;
          // Kosongkan pencarian saat ganti kategori (opsional)
          searchController.clear();
          searchQuery = '';
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : const Color.fromARGB(255, 235, 23, 19).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? Colors.white
                  : const Color.fromARGB(255, 235, 23, 19).withOpacity(0.5),
              width: 1), // Hilangkan garis polisi, ganti border
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().items.length;

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedBottomIndex,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => NavigatorScreen(user: widget.user),
                ),
              );
            } else if (index == 1) {
              setState(() {
                selectedBottomIndex = index;
              });
            } else if (index == 2) {
              setState(() {
                selectedBottomIndex = index;
              });
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Statistik',
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
        ),
        floatingActionButton: selectedBottomIndex == 1 && cartItemCount > 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KeranjangPage()),
                  );
                },
                backgroundColor: const Color.fromARGB(255, 236, 227, 227),
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Color.fromARGB(230, 24, 0, 0),
                ),
                label: Text(
                  'Keranjang ($cartItemCount)',
                  style: const TextStyle(
                    color: Color.fromARGB(230, 17, 0, 0),
                  ),
                ))
            : null);
  }

// ✅ Helper method untuk AppBar
  PreferredSizeWidget? _buildAppBar() {
    if (selectedBottomIndex == 1) {
      // AppBar untuk Produk
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
                    children: [
                      _buildCategoryTab('Sayuran'),
                      _buildCategoryTab('Buah'),
                      _buildCategoryTab('Daging'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // AppBar untuk Statistik dan Profil
      return AppBar(
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

// ✅ Helper method untuk Body
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

// ✅ Halaman Profil
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.email,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
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
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Konfirmasi Logout'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Batal',
                          style: const TextStyle(
                            color: Color.fromARGB(230, 17, 0, 0),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 241, 241, 241),
                        ),
                        child: const Text(
                          'Logout',
                          style: const TextStyle(
                            color: Color.fromARGB(230, 17, 0, 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await Provider.of<AuthProvider>(context, listen: false)
                      .logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              icon: const Icon(Icons.logout,
                  color: Color.fromARGB(230, 17, 0, 0)),
              label: const Text(
                'Logout',
                style: TextStyle(
                    fontSize: 16, color: Color.fromARGB(230, 17, 0, 0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Pisahkan grid produk ke method terpisah
  Widget _buildProductGrid() {
    return isLoadingProducts
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : filteredProducts.isEmpty
            ? Center(child: Text('Tidak ada produk kategori $selectedCategory'))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.70,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (_, i) {
                  final p = filteredProducts[i];
                  return GestureDetector(
                    onTap: () => addToCart(p),
                    onLongPress: (widget.user?.isAdmin ?? false)
                        ? () => _showAdminProductMenu(p)
                        : null,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                });
  }
}

// ----- HALAMAN KERANJANG (SESUAI UI/UX KEEMPAT) -----

class KeranjangPage extends StatelessWidget {
  const KeranjangPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final List<CartItem> cartItems = cart.items;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Keranjang',
            style: TextStyle(
                color: Color.fromARGB(255, 255, 253, 253),
                fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Text('Keranjang kosong'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      // Mirip List Tile UI/UX
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Area Gambar Produk (menggunakan emoji sebagai placeholder)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(item.product.emoji,
                                    style: const TextStyle(fontSize: 30)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Nama dan Harga Produk
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.namaProduk,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(formatRupiah(item.product.hargaJual),
                                      style: const TextStyle(
                                          color: primaryColor, fontSize: 14)),
                                ],
                              ),
                            ),
                            // Kuantitas dan Hapus
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tombol Minus
                                _buildQuantityButton(
                                    Icons.remove,
                                    () =>
                                        cart.decrementQuantity(item.product.id),
                                    item.quantity == 1),
                                // Kuantitas
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(item.quantity.toString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                // Tombol Plus
                                _buildQuantityButton(
                                    Icons.add,
                                    () =>
                                        cart.incrementQuantity(item.product.id),
                                    item.quantity >= item.product.stok),
                                // Tombol Hapus (Mirip tempat sampah merah)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: primaryColor),
                                  onPressed: () =>
                                      cart.removeFromCart(item.product.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // --- Ringkasan Total & Tombol Cetak Struk ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryRow('Bayar:', formatRupiah(cart.subtotalCart)),
                _buildSummaryRow('Diskon:', formatRupiah(cart.totalDiscount)),
                const Divider(),
                _buildSummaryRow('Total:', formatRupiah(cart.totalPayment),
                    isTotal: true),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: cart.items.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutPage(
                                cartItems: List.from(cartItems),
                                onCheckoutComplete: () => cart.clearCart(),
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Checkout',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Pembantu untuk Tombol Kuantitas
  Widget _buildQuantityButton(
      IconData icon, VoidCallback onPressed, bool isDisabled) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey.shade300 : primaryColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // Widget Pembantu untuk Baris Ringkasan
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 20 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? primaryColor : Colors.black)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 20 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? primaryColor : Colors.black)),
        ],
      ),
    );
  }
}

// ----- HALAMAN CHECKOUT (SESUAI UI/UX KEEMPAT) -----
// ... (Kelas CheckoutPage dan _CheckoutPageState tetap sama, tetapi tombol ganti 'Checkout') ...
// Catatan: Saya mengubah tombol CheckoutPage menjadi "Checkout" (sesuai navigasi Keranjang)

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final VoidCallback onCheckoutComplete;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.onCheckoutComplete,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = false;

  // Hitung total belanja
  double get totalBelanja =>
      widget.cartItems.fold(0, (sum, item) => sum + item.total);

  // LOGIKA CETAK PDF
  Future<void> _generateAndOpenPdf(List<CartItem> items, double total) async {
    // ... (Implementasi PDF sama seperti sebelumnya) ...
    // ... (Hanya ganti tombol "Cetak Struk" di bawah) ...
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Tanggal: ${DateTime.now().toLocal().toString().substring(0, 16)}'),
              pw.Divider(height: 20),

              // Header Tabel
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      flex: 3,
                      child: pw.Text('Item',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(
                      flex: 1,
                      child: pw.Text('Qty',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center)),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text('Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Divider(height: 10),

              // Daftar Item
              ...items.map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                        flex: 3, child: pw.Text(item.product.namaProduk)),
                    pw.Expanded(
                        flex: 1,
                        child: pw.Text(item.quantity.toString(),
                            textAlign: pw.TextAlign.center)),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text(formatRupiah(item.total),
                            textAlign: pw.TextAlign.right)),
                  ],
                );
              }).toList(),

              pw.Divider(height: 20),

              // Total Keseluruhan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Belanja: ',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    formatRupiah(total),
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Center(child: pw.Text('Terima kasih telah berbelanja!')),
            ],
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final trxNumber = Random().nextInt(999999).toString().padLeft(6, '0');
      final file = File('${output.path}/struk_belanja_$trxNumber.pdf');
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Struk $trxNumber berhasil dibuat. Membuka file...'),
              backgroundColor: accentColor),
        );
      }
      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _processCheckout() async {
    setState(() => _isLoading = true);

    try {
      final productService = ProductService();

      // Siapkan detail transaksi
      final details = widget.cartItems
          .map((item) => {
                'produk_id': item.product.id,
                'jumlah': item.quantity,
                'harga_satuan': item.product.hargaJual,
                'subtotal': item.total,
                'diskon_item': item.diskonRupiah,
              })
          .toList();

      // Ambil kasir ID dari context
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final kasirId = authProvider.currentUser!.id;

      // Buat transaksi dan update stok
      final result = await productService.createTransactionWithStockUpdate(
        kasirId: kasirId,
        totalHarga: totalBelanja,
        details: details,
      );

      if (result['success']) {
        // Generate PDF
        await _generateAndOpenPdf(widget.cartItems, totalBelanja);

        // Clear cart
        widget.onCheckoutComplete();

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi Berhasil! Struk sedang dibuka...'),
            backgroundColor: accentColor,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Transaksi gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Checkout',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  elevation:
                      1, // Menghilangkan border dan memberikan shadow ringan
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Text(item.product.emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                    title: Text(item.product.namaProduk,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${item.quantity} x ${formatRupiah(item.product.hargaJual)}'),
                    trailing: Text(
                      formatRupiah(item.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                );
              },
            ),
          ),
          // Ringkasan & Tombol Checkout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(formatRupiah(totalBelanja),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: accentColor)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _processCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Konfirmasi & Cetak Struk',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
