import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gs_mart_aplikasi/database/product_service.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:gs_mart_aplikasi/models/products.dart';

class StokPage extends StatefulWidget {
  const StokPage({super.key});

  @override
  State<StokPage> createState() => _StokPageState();
}

class _StokPageState extends State<StokPage> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  final _productService = ProductService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("loadProducts error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog({ProductModel? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        product: product,
        productService: _productService,
        onSaved: _loadProducts,
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk"),
        content: const Text("Yakin ingin menghapus produk ini?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final success = await _productService.deleteProduct(product.id);
      if (success) {
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Produk berhasil dihapus")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Gagal menghapus: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        leading: Container(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _products.isEmpty
              ? const Center(child: Text("Belum ada produk"))
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, i) {
                      final product = _products[i];
                      return ProductCard(
                        product: product,
                        onEdit: () => _showAddEditDialog(product: product),
                        onDelete: () => _deleteProduct(product),
                      );
                    },
                  ),
                ),
    );
  }
}

// ---------------- ProductCard ----------------

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final harga = product.hargaJual;
    final stok = product.stokTersedia;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: product.imageUrl != null
                ? Image.network(product.imageUrl!,
                    height: 120, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 40),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.namaProduk,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text("Rp ${harga.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.red)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Stok: $stok"),
                      Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18, color: Colors.blue),
                              onPressed: onEdit),
                          IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              onPressed: onDelete),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- ProductFormDialog ----------------

class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final ProductService productService;
  final VoidCallback onSaved;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.productService,
    required this.onSaved,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaProdukController;
  late TextEditingController _kodeProdukController;
  late TextEditingController _hargaBeliController;
  late TextEditingController _hargaJualController;
  late TextEditingController _stokController;
  late TextEditingController _deskripsiController;

  String _selectedKategori = "Sayuran"; // nilai default
  String _selectedSatuan = "kg"; // hanya kg

  // List pilihan
  final List<String> _kategoriList = ["Sayuran", "Buah", "Daging"];
  final List<String> _satuanList = ["kg"];

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _namaProdukController =
        TextEditingController(text: widget.product?.namaProduk ?? "");
    _kodeProdukController =
        TextEditingController(text: widget.product?.kodeProduk ?? "");
    _hargaBeliController =
        TextEditingController(text: widget.product?.hargaBeli.toString() ?? "");
    _hargaJualController =
        TextEditingController(text: widget.product?.hargaJual.toString() ?? "");
    _stokController = TextEditingController(
        text: widget.product?.stokTersedia.toString() ?? "");
    _deskripsiController =
        TextEditingController(text: widget.product?.deskripsi ?? "");

    _currentImageUrl = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _namaProdukController.dispose();
    _kodeProdukController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _stokController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      print('📸 === PICK IMAGE START ===');
      print('Platform: ${kIsWeb ? "WEB" : "MOBILE"}');

      final picker = ImagePicker();
      print('1. Membuka gallery...');

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        print('2. Gambar dipilih!');
        print('   - Nama: ${image.name}');
        print('   - Path: ${image.path}');

        if (kIsWeb) {
          print('3. Platform: WEB');
          print('   - Ini adalah blob URL, bukan file path');

          // Untuk web, kita perlu read as bytes
          final bytes = await image.readAsBytes();
          print('   - Bytes length: ${bytes.length}');

          setState(() {
            _selectedImage = image;
            _selectedImageBytes = bytes; // Simpan bytes untuk web
            _currentImageUrl = null;
          });
        } else {
          print('3. Platform: MOBILE');
          final size = await image.length();
          print('   - Ukuran: ${size} bytes');

          setState(() {
            _selectedImage = image;
            _selectedImageBytes = null; // Tidak perlu untuk mobile
            _currentImageUrl = null;
          });
        }

        print('✅ Gambar siap diupload');
      } else {
        print('2. User membatalkan pemilihan gambar');
      }

      print('📸 === PICK IMAGE END ===');
    } catch (e) {
      print('❌ Error pickImage: $e');
      print('   Stack: ${e.toString()}');
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    print('💾 === SAVE PRODUCT START ===');
    print('Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
    print('Mode: ${widget.product == null ? "TAMBAH BARU" : "EDIT"}');

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _currentImageUrl;

      if (_selectedImage != null) {
        print('1. Ada gambar baru yang dipilih');
        print('   - Nama: ${_selectedImage!.name}');

        if (kIsWeb) {
          print('2. Platform: WEB');
          // Baca bytes dari XFile
          final bytes = await _selectedImage!.readAsBytes();
          print('   - Bytes length: ${bytes.length}');

          print('3. Memanggil uploadImage dengan bytes...');
          final uploadedUrl = await widget.productService.uploadImage(bytes);

          if (uploadedUrl != null) {
            print('✅ Upload BERHASIL!');
            print('   URL: $uploadedUrl');
            imageUrl = uploadedUrl;

            // TEST: Buka URL di tab baru
            print('   🔗 Coba buka di browser:');
            print('   $uploadedUrl');
          } else {
            print('❌ Upload GAGAL!');
            print('   Menggunakan URL lama: $_currentImageUrl');
          }
        }
      } else {
        print('1. Tidak ada gambar baru');
        print('   Menggunakan URL existing: $_currentImageUrl');
      }

      

      // Buat product object
      final product = ProductModel(
        id: widget.product?.id ?? '',
        kodeProduk: _kodeProdukController.text.trim(),
        namaProduk: _namaProdukController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        hargaBeli: double.parse(_hargaBeliController.text),
        hargaJual: double.parse(_hargaJualController.text),
        kategori: _selectedKategori,
        satuan: _selectedSatuan,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.productService.supabase.auth.currentUser?.id ?? widget.product?.createdBy,
        stokTersedia: int.parse(_stokController.text),
        stokMinimum: widget.product?.stokMinimum ?? 5,
        lastStockUpdate: DateTime.now(),
        imageUrl: imageUrl,
      );

      print('4. Menyimpan product ke database...');
      print('   - Nama: ${product.namaProduk}');
      print('   - Image URL: ${product.imageUrl ?? "NULL"}');

      bool success = widget.product == null
          ? await widget.productService.createProduct(product)
          : await widget.productService.updateProduct(product);

      if (success && mounted) {
        print('✅ Database save BERHASIL!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.product == null
                  ? "Produk berhasil ditambahkan"
                  : "Produk berhasil diupdate")),
        );
        widget.onSaved();
        Navigator.pop(context);
      } else {
        print('❌ Database save GAGAL!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan produk ke database")),
        );
      }
    } catch (e) {
      print('💥 ERROR saveProduct:');
      print('   Type: ${e.runtimeType}');
      print('   Message: $e');
      print('   Stack: ${e.toString()}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      print('💾 === SAVE PRODUCT END ===');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? "Tambah Produk" : "Edit Produk"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode:
              AutovalidateMode.onUserInteraction, // ← TAMBAHKAN INI
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _kodeProdukController,
                decoration: const InputDecoration(labelText: "Kode Produk"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              TextFormField(
                controller: _namaProdukController,
                decoration: const InputDecoration(labelText: "Nama Produk"),
                validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama wajib diisi';
                      }

                      final trimmedValue = value.trim();

                      // Hanya huruf dan spasi
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmedValue)) {
                        return 'Hanya boleh huruf dan spasi';
                      }
                      return null;
                    },
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kategori *",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedKategori,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.red),
                          items: _kategoriList.map((String kategori) {
                            return DropdownMenuItem<String>(
                              value: kategori,
                              child: Text(kategori),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedKategori = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

// ⭐ SATUAN (HANYA KG - DISABLED)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Satuan *",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.scale, color: Colors.blue),
                          const SizedBox(width: 10),
                          const Text("Satuan:", style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Text(
                            _selectedSatuan,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _hargaBeliController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Harga Beli",
                  hintText: "Contoh: 10000 atau 10000.50",
                  errorMaxLines: 2, // ← TAMBAHKAN INI
                ),
                onChanged: (value) {
                  // Trigger validasi harga jual ketika harga beli berubah
                  if (_formKey.currentState != null &&
                      _hargaJualController.text.isNotEmpty) {
                    _formKey.currentState!.validate();
                  }
                },
                validator: (v) {
                  if (v!.isEmpty) return "Wajib diisi";
                  // Regex yang lebih permisif untuk validasi real-time
                  if (!RegExp(r'^\d*\.?\d*$').hasMatch(v)) {
                    return "Hanya boleh angka dan titik";
                  }
                  if (v == '.') return "Format angka salah";

                  // Cek jika ada titik desimal, pastikan format benar
                  if (v.contains('.')) {
                    final parts = v.split('.');
                    if (parts.length > 2) return "Format angka salah";
                    if (parts[1].length > 2) return "Maksimal 2 angka desimal";
                  }

                  final value = double.tryParse(v);
                  if (value == null) return "Format angka salah";
                  if (value <= 0) return "Harus lebih besar dari 0";
                  return null;
                },
              ),
              TextFormField(
                controller: _hargaJualController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Harga Jual",
                  hintText: "Contoh: 15000 atau 15000.75",
                  errorMaxLines: 2, // ← TAMBAHKAN INI
                ),
                validator: (v) {
                  if (v!.isEmpty) return "Wajib diisi";
                  // Regex yang lebih permisif untuk validasi real-time
                  if (!RegExp(r'^\d*\.?\d*$').hasMatch(v)) {
                    return "Hanya boleh angka dan titik";
                  }
                  if (v == '.') return "Format angka salah";

                  // Cek jika ada titik desimal, pastikan format benar
                  if (v.contains('.')) {
                    final parts = v.split('.');
                    if (parts.length > 2) return "Format angka salah";
                    if (parts[1].length > 2) return "Maksimal 2 angka desimal";
                  }

                  final value = double.tryParse(v);
                  if (value == null) return "Format angka salah";
                  if (value <= 0) return "Harus lebih besar dari 0";

                  // Validasi harga jual harus >= harga beli
                  final hargaBeliText = _hargaBeliController.text;
                  if (hargaBeliText.isNotEmpty) {
                    final hargaBeli = double.tryParse(hargaBeliText);
                    if (hargaBeli != null && value < hargaBeli) {
                      return "Harga jual harus ≥ harga beli";
                    }
                  }

                  return null;
                },
              ),
              TextFormField(
                controller: _stokController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stok Awal",
                  hintText: "Contoh: 100",
                ),
                validator: (v) {
                  if (v!.isEmpty) return "Wajib diisi";
                  if (!RegExp(r'^\d*$').hasMatch(v)) {
                    // ← Regex yang lebih permisif
                    return "Hanya boleh angka";
                  }
                  if (v.isEmpty) return null; // Biarkan kosong sementara

                  final value = int.tryParse(v);
                  if (value == null) return "Harus angka bulat";
                  if (value < 0) return "Tidak boleh negatif";
                  return null;
                },
              ),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: "Deskripsi"),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: Text(
                  _selectedImage != null
                      ? "Ganti Gambar"
                      : (_currentImageUrl != null
                          ? "Gambar Saat Ini"
                          : "Pilih Gambar"),
                ),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 8),
              if (_selectedImage != null)
                kIsWeb
                    ? Image.memory(_selectedImageBytes!, height: 100)
                    : Image.file(File(_selectedImage!.path), height: 100)
              else if (_currentImageUrl != null)
                Image.network(_currentImageUrl!, height: 100),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text("Simpan"),
        ),
      ],
    );
  }
}
// CRUD Produk selesai
