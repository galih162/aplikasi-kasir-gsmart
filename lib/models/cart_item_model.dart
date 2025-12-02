
import 'products.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  double diskonPersen;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.diskonPersen = 0,
  });

  double get subtotal => product.hargaJual * quantity;
  double get diskonRupiah => subtotal * (diskonPersen / 100);
  double get total => subtotal - diskonRupiah;

  String? get imageUrl => product.imageUrl;
}