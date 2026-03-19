class TransactionModel {
  final String receiptId;
  final String tanggal;
  final double totalHarga;
  final String status;

  TransactionModel({
    required this.receiptId,
    required this.tanggal,
    required this.totalHarga,
    required this.status,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      receiptId: json['receipt_id'],
      tanggal: json['tanggal'],
      totalHarga: (json['total_harga'] as num).toDouble(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_id': receiptId,
      'tanggal': tanggal,
      'total_harga': totalHarga,
      'status': status,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
