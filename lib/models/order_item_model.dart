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
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '', // backward compat
      receiptId: json['receipt_number']?.toString() ?? json['receipt_id']?.toString() ?? '',
      qty: parseInt(json['quantity'] ?? json['qty']),
      bonusQty: parseInt(json['bonus_qty']),
      unitPrice: parseDouble(json['unit_price'] ?? json['harga_satuan']),
      subtotal: parseDouble(json['subtotal']),
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
