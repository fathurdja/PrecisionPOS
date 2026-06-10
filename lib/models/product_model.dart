class ProductModel {
  final String id;
  final String name;
  final String? categoryId;
  final String? description;
  final String? barcode;
  final double? purchasePrice;
  final double price;
  final bool isActive;
  final int stok; // retained for local stock logic
  final List<dynamic>? variants;

  ProductModel({
    required this.id,
    required this.name,
    this.categoryId,
    this.description,
    this.barcode,
    this.purchasePrice,
    required this.price,
    this.isActive = true,
    required this.stok,
    this.variants,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }
    double? parseDoubleNullable(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return ProductModel(
      id: json['id']?.toString() ?? '', // in case it was int previously
      name: json['name']?.toString() ?? json['nama']?.toString() ?? 'Unknown',
      categoryId: json['category_id']?.toString(),
      description: json['description']?.toString(),
      barcode: json['barcode']?.toString(),
      purchasePrice: parseDoubleNullable(json['purchase_price']),
      price: parseDouble(json['price'] ?? json['harga']),
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1' || json['is_active'] == 'true',
      stok: parseInt(json['current_stock'] ?? json['stok']),
      variants: json['variants'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'description': description,
      'barcode': barcode,
      'purchase_price': purchasePrice,
      'price': price,
      'is_active': isActive ? 1 : 0, // Store as 1/0 for sqlite
      'stok': stok,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
