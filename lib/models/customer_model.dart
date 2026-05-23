class CustomerModel {
  final int? id;
  final String name;
  final String phone;
  final String? createdAt;

  CustomerModel({
    this.id,
    required this.name,
    required this.phone,
    this.createdAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
