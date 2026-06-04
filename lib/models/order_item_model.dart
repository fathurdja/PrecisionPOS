class OrderItemModel {
  final String id;
  final String productId;
  final String receiptId;
  final int qty;
  final int bonusQty;
  final double unitPrice;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.receiptId,
    required this.qty,
    this.bonusQty = 0,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? json['product_id'].toString(), // backward compat
      receiptId: json['receipt_number'] ?? json['receipt_id'] ?? '',
      qty: (json['quantity'] ?? json['qty'] ?? 0) as int,
      bonusQty: (json['bonus_qty'] ?? 0) as int,
      unitPrice: ((json['unit_price'] ?? json['harga_satuan'] ?? 0) as num).toDouble(),
      subtotal: ((json['subtotal'] ?? 0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'quantity': qty,
      'bonus_qty': bonusQty,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'receipt_id': receiptId,
      'qty': qty,
      'bonus_qty': bonusQty,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}
