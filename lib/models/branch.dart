class Branch {
  final String id;
  final String name;
  final String code;
  final String address;
  final String contactPhone;
  final int totalInventory;

  const Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.contactPhone,
    required this.totalInventory,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'contactPhone': contactPhone,
      'totalInventory': totalInventory,
    };
  }

  factory Branch.fromMap(Map<String, dynamic> map, String docId) {
    return Branch(
      id: docId,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      address: map['address'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      totalInventory: (map['totalInventory'] as num?)?.toInt() ?? 0,
    );
  }
}
