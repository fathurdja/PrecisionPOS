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
    return ProductModel(
      id: json['id']?.toString() ?? '', // in case it was int previously
      name: json['name'] ?? json['nama'] ?? 'Unknown',
      categoryId: json['category_id'],
      description: json['description'],
      barcode: json['barcode'],
      purchasePrice: json['purchase_price'] != null ? (json['purchase_price'] as num).toDouble() : null,
      price: ((json['price'] ?? json['harga'] ?? 0) as num).toDouble(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      stok: json['current_stock'] ?? json['stok'] ?? 0,
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
