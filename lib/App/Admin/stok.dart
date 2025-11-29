import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:gs_mart_aplikasi/Database/Service.dart';// Import service.dart Anda

class StokPage extends StatefulWidget {
  const StokPage({super.key});

  @override
  State<StokPage> createState() => _StokPageState();
}

class _StokPageState extends State<StokPage> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Tunda pemanggilan sampai setelah build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    // ✅ PASTIKAN CONTEXT SUDAH READY
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final products =
          await authProvider.productService.getAllProductsWithStock();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('loadProducts error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? product}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider, // pakai instance yang sama
        child: ProductFormDialog(
          product: product,
          onSaved: () {
            Navigator.of(context).pop();
            _loadProducts();
          },
        ),
      ),
    );
  }

  Future<void> _deleteProduct(String productId, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (imageUrl != null && imageUrl.isNotEmpty) {
          await authProvider.storageService.deleteProductImage(imageUrl);
        }

        await SupabaseConfig.client
            .from('products')
            .delete()
            .eq('id', productId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil dihapus')),
          );
          _loadProducts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 247, 5, 1),
        leading: Container(),
        title: const Text(
          'Stok Barang',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 212, 44, 32)))
          : RefreshIndicator(
              onRefresh: _loadProducts,
              color: Colors.red,
              child: _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada produk',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return ProductCard(
                          product: product,
                          onEdit: () => _showAddEditDialog(product: product),
                          onDelete: () => _deleteProduct(
                            product['id'],
                            product['image_url'],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
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
    final imageUrl = product['image_url'] as String?;
    final stok = product['stok_tersedia'] ?? 0;
    final harga = product['harga_jual'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Produk
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
                  )
                : Container(
                    height: 120,
                    color: Colors.grey[200],
                    child:
                        const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
          ),

          // Info Produk
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['nama_produk'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${harga.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 250, 62, 49),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: stok > 0 ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Stok: $stok',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: stok > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Colors.blue,
                              ),
                            ),
                          ),
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

class ProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final VoidCallback onSaved;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.onSaved,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kodeProdukController = TextEditingController();
  final _namaProdukController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _stokController = TextEditingController();
  final _deskripsiController = TextEditingController();

  String _kategori = 'sayuran';
  String _satuan = 'Kg';
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;

  final List<String> _kategoriOptions = [
    'sayuran',
    'buah',
    'daging',
  ];

  final List<String> _satuanOptions = [
    'Kg',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _kodeProdukController.text = widget.product!['kode_produk'] ?? '';
      _namaProdukController.text = widget.product!['nama_produk'] ?? '';
      _hargaBeliController.text =
          widget.product!['harga_beli']?.toString() ?? '';
      _hargaJualController.text =
          widget.product!['harga_jual']?.toString() ?? '';
      _stokController.text = widget.product!['stok_tersedia']?.toString() ?? '';
      _deskripsiController.text = widget.product!['deskripsi'] ?? '';
      _kategori = widget.product!['kategori'] ?? 'sayuran';
      _satuan = widget.product!['satuan'] ?? 'Kg';
      _currentImageUrl = widget.product!['image_url'];
    }
  }

  Future<void> _pickImage() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final image = await authProvider.storageService.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.product == null) {
        // CREATE
        final result = await authProvider.productService.createProductWithImage(
          kodeProduk: _kodeProdukController.text.trim(),
          namaProduk: _namaProdukController.text.trim(),
          hargaBeli: double.parse(_hargaBeliController.text),
          hargaJual: double.parse(_hargaJualController.text),
          kategori: _kategori,
          satuan: _satuan,
          stokAwal: int.parse(_stokController.text),
          imageFile: _selectedImage,
          deskripsi: _deskripsiController.text.trim(),
        );

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'])),
            );
            widget.onSaved();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: const Color.fromARGB(255, 247, 5, 1),
              ),
            );
          }
        }
      } else {
        // UPDATE
        String? newImageUrl = _currentImageUrl;

        // Upload gambar baru jika ada
        if (_selectedImage != null) {
          final uploadResult =
              await authProvider.productService.updateProductImage(
            productId: widget.product!['id'],
            currentImageUrl: _currentImageUrl ?? '',
            newImageFile: _selectedImage!,
          );

          if (uploadResult['success']) {
            newImageUrl = uploadResult['image_url'];
          }
        }

        // Update data produk
        await SupabaseConfig.client.from('products').update({
          'kode_produk': _kodeProdukController.text.trim(),
          'nama_produk': _namaProdukController.text.trim(),
          'harga_beli': double.parse(_hargaBeliController.text),
          'harga_jual': double.parse(_hargaJualController.text),
          'kategori': _kategori,
          'satuan': _satuan,
          'stok_tersedia': int.parse(_stokController.text),
          'deskripsi': _deskripsiController.text.trim(),
          'image_url': newImageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', widget.product!['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produk berhasil diupdate')),
          );
          widget.onSaved();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color.fromARGB(255, 247, 5, 1),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: const Color.fromARGB(255, 247, 5, 1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    widget.product == null ? 'Tambah Produk' : 'Edit Produk',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Upload Gambar
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _currentImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _currentImageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate,
                                            size: 50, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap untuk upload gambar',
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kode Produk
                      TextFormField(
                        controller: _kodeProdukController,
                        decoration: const InputDecoration(
                          labelText: 'Kode Produk',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Nama Produk
                      TextFormField(
                        controller: _namaProdukController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag),
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Kategori & Satuan
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _kategori,
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
                                border: OutlineInputBorder(),
                              ),
                              items: _kategoriOptions.map((k) {
                                return DropdownMenuItem(
                                    value: k, child: Text(k));
                              }).toList(),
                              onChanged: (v) => setState(() => _kategori = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _satuan,
                              decoration: const InputDecoration(
                                labelText: 'Satuan',
                                border: OutlineInputBorder(),
                              ),
                              items: _satuanOptions.map((s) {
                                return DropdownMenuItem(
                                    value: s, child: Text(s));
                              }).toList(),
                              onChanged: (v) => setState(() => _satuan = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Harga Beli & Jual
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hargaBeliController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga Beli',
                                border: OutlineInputBorder(),
                                prefixText: 'Rp ',
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _hargaJualController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga Jual',
                                border: OutlineInputBorder(),
                                prefixText: 'Rp ',
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stok
                      TextFormField(
                        controller: _stokController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stok Awal',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Deskripsi
                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tombol Simpan
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SIMPAN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _kodeProdukController.dispose();
    _namaProdukController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _stokController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }
}
