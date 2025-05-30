class ShoppingItem {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isCompleted;
  final String? notes;
  final String? category;
  final double? price;
  final int? quantity;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isCompleted = false,
    this.notes,
    this.category,
    this.price,
    this.quantity,
  });

  // JSON 변환을 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
      'category': category,
      'price': price,
      'quantity': quantity,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      isCompleted: json['isCompleted'] == 1,
      notes: json['notes'],
      category: json['category'],
      price: json['price']?.toDouble(),
      quantity: json['quantity'],
    );
  }

  // 복사 생성자
  ShoppingItem copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isCompleted,
    String? notes,
    String? category,
    double? price,
    int? quantity,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'ShoppingItem(id: $id, name: $name, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShoppingItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
