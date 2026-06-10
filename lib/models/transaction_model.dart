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
    this.syncStatus = 'pending',
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }
    
    var itemsList = json['items'] as List?;
    List<OrderItemModel>? parsedItems;
    if (itemsList != null) {
      parsedItems = itemsList.map((e) => OrderItemModel.fromJson(e)).toList();
    }

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      receiptNumber: json['receipt_number']?.toString() ?? json['receipt_id']?.toString() ?? '',
      tanggal: json['created_at']?.toString() ?? json['tanggal']?.toString() ?? DateTime.now().toIso8601String(),
      totalHarga: parseDouble(json['total_price'] ?? json['total_harga']),
      status: json['status']?.toString() ?? 'completed',
      orderType: json['order_type']?.toString() ?? 'take-away',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      taxAmount: parseDouble(json['tax_amount']),
      discountAmount: parseDouble(json['discount_amount']),
      receivedAmount: parseDouble(json['received_amount']),
      changeAmount: parseDouble(json['change_amount']),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      cashierName: json['cashier_name']?.toString() ?? json['user_name']?.toString(),
      serviceAmount: parseDouble(json['service_amount']),
      deviceId: json['device_id'] != null ? int.tryParse(json['device_id'].toString()) : null,
      items: parsedItems,
      syncStatus: json['sync_status']?.toString() ?? 'synced',
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
      'total_price': totalHarga,
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
