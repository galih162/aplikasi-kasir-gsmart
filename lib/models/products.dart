class ProductModel {
  final String id;
  final String kodeProduk;
  final String namaProduk;
  final String? deskripsi;
  final double hargaBeli;
  final double hargaJual;
  final String? kategori;
  final String satuan;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final int stokTersedia;
  final int stokMinimum;
  final DateTime lastStockUpdate;
  final String? imageUrl;

  ProductModel({
    required this.id,
    required this.kodeProduk,
    required this.namaProduk,
    required this.deskripsi,
    required this.hargaBeli,
    required this.hargaJual,
    required this.kategori,
    required this.satuan,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.stokTersedia,
    required this.stokMinimum,
    required this.lastStockUpdate,
    required this.imageUrl,
  });

  /// Convert data Supabase → Dart model
  factory ProductModel.fromDatabase(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      kodeProduk: map['kode_produk'],
      namaProduk: map['nama_produk'],
      deskripsi: map['deskripsi'],
      hargaBeli: (map['harga_beli'] as num).toDouble(),
      hargaJual: (map['harga_jual'] as num).toDouble(),
      kategori: map['kategori'],
      satuan: map['satuan'] ?? 'pcs',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      createdBy: map['created_by'],
      stokTersedia: map['stok_tersedia'] ?? 0,
      stokMinimum: map['stok_minimum'] ?? 5,
      lastStockUpdate: DateTime.parse(map['last_stock_update']),
      imageUrl: map['image_url'],
    );
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

  /// Convert model → Map (untuk insert/update Supabase)
  Map<String, dynamic> toJson() {
    return {
      'kode_produk': kodeProduk,
      'nama_produk': namaProduk,
      'deskripsi': deskripsi,
      'harga_beli': hargaBeli,
      'harga_jual': hargaJual,
      'kategori': kategori,
      'satuan': satuan,
      'created_by': createdBy,
      'stok_tersedia': stokTersedia,
      'stok_minimum': stokMinimum,
      'image_url': imageUrl,
      'last_stock_update': lastStockUpdate.toIso8601String(),
    };
  }
}
