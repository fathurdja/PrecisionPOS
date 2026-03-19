class ProductModel {
  final int id;
  final String nama;
  final double harga;
  final int stok;

  ProductModel({
    required this.id,
    required this.nama,
    required this.harga,
    required this.stok,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      nama: json['nama'],
      harga: (json['harga'] as num).toDouble(),
      stok: json['stok'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
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
