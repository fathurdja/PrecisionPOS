class TransactionModel {
  final String receiptId;
  final String tanggal;
  final double totalHarga;
  final String status;
  final String? customerName;
  final String? customerPhone;
  final String? cashierName;
  final double taxAmount;
  final double serviceAmount;

  TransactionModel({
    required this.receiptId,
    required this.tanggal,
    required this.totalHarga,
    required this.status,
    this.customerName,
    this.customerPhone,
    this.cashierName,
    this.taxAmount = 0.0,
    this.serviceAmount = 0.0,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      receiptId: json['receipt_id'],
      tanggal: json['tanggal'],
      totalHarga: (json['total_harga'] as num).toDouble(),
      status: json['status'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      cashierName: json['cashier_name'],
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      serviceAmount: (json['service_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_id': receiptId,
      'tanggal': tanggal,
      'total_harga': totalHarga,
      'status': status,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (cashierName != null) 'cashier_name': cashierName,
      'tax_amount': taxAmount,
      'service_amount': serviceAmount,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
