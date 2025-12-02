import 'package:flutter/material.dart';
import 'package:gs_mart_aplikasi/models/cart_item_model.dart';
import 'package:gs_mart_aplikasi/models/products.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  void addOrIncrement(ProductModel product, BuildContext context) {
    final idx = _items.indexWhere((i) => i.product.id == product.id);
    int currentQtyInCart = idx != -1 ? _items[idx].quantity : 0;

    if (product.stokTersedia > currentQtyInCart) {
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
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void incrementQuantity(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx != -1) {
      final item = _items[idx];
      if (item.product.stokTersedia > item.quantity) {
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