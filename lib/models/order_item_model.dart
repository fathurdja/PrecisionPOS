class OrderItemModel {
  final int? id;
  final String receiptId;
  final int productId;
  final int qty;
  final double subtotal;

  OrderItemModel({
    this.id,
    required this.receiptId,
    required this.productId,
    required this.qty,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      receiptId: json['receipt_id'],
      productId: json['product_id'],
      qty: json['qty'],
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receipt_id': receiptId,
      'product_id': productId,
      'qty': qty,
      'subtotal': subtotal,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
