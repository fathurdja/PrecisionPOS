import 'order_item_model.dart';

class TransactionModel {
  final String id;
  final String receiptNumber;
  final String tanggal;
  final double totalHarga;
  final String status; // completed, pending, canceled, voided
  final String orderType; // dine-in, take-away, delivery
  final String paymentMethod; // cash, qris, bon
  
  final double taxAmount;
  final double discountAmount;
  final double receivedAmount;
  final double changeAmount;
  
  final String? customerName;
  final String? customerPhone;
  final String? cashierName; // Added back for compatibility
  final double serviceAmount; // Added back for compatibility
  final int? deviceId;
  
  final List<OrderItemModel>? items;
  
  // Local only
  final String syncStatus; // synced, pending

  String get receiptId => id; // Alias for backward compatibility

  TransactionModel({
    required this.id,
    required this.receiptNumber,
    required this.tanggal,
    required this.totalHarga,
    required this.status,
    required this.orderType,
    required this.paymentMethod,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.receivedAmount = 0.0,
    this.changeAmount = 0.0,
    this.customerName,
    this.customerPhone,
    this.cashierName,
    this.serviceAmount = 0.0,
    this.deviceId,
    this.items,
    this.syncStatus = 'synced',
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List?;
    List<OrderItemModel>? parsedItems;
    if (itemsList != null) {
      parsedItems = itemsList.map((e) => OrderItemModel.fromJson(e)).toList();
    }

    return TransactionModel(
      id: json['id'] ?? '',
      receiptNumber: json['receipt_number'] ?? json['receipt_id'] ?? '',
      tanggal: json['created_at'] ?? json['tanggal'] ?? DateTime.now().toIso8601String(),
      totalHarga: ((json['total_price'] ?? json['total_harga'] ?? 0) as num).toDouble(),
      status: json['status'] ?? 'completed',
      orderType: json['order_type'] ?? 'take-away',
      paymentMethod: json['payment_method'] ?? 'cash',
      taxAmount: ((json['tax_amount'] ?? 0) as num).toDouble(),
      discountAmount: ((json['discount_amount'] ?? 0) as num).toDouble(),
      receivedAmount: ((json['received_amount'] ?? 0) as num).toDouble(),
      changeAmount: ((json['change_amount'] ?? 0) as num).toDouble(),
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      cashierName: json['cashier_name'] ?? json['user_name'],
      serviceAmount: ((json['service_amount'] ?? 0) as num).toDouble(),
      deviceId: json['device_id'],
      items: parsedItems,
      syncStatus: json['sync_status'] ?? 'synced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'created_at': tanggal,
      'total_price': totalHarga,
      'status': status,
      'order_type': orderType,
      'payment_method': paymentMethod,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'received_amount': receivedAmount,
      'change_amount': changeAmount,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_number': receiptNumber,
      'tanggal': tanggal,
      'total_harga': totalHarga,
      'status': status,
      'order_type': orderType,
      'payment_method': paymentMethod,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'received_amount': receivedAmount,
      'change_amount': changeAmount,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'cashier_name': cashierName,
      'service_amount': serviceAmount,
      'device_id': deviceId,
      'sync_status': syncStatus,
    };
  }
}
