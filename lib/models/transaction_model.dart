class TransactionModel {
  final int? id;
  final double amount;
  final String date;
  final String merchant;
  final String category;
  final String? imagePath;
  final String createdAt;

  const TransactionModel({
    this.id,
    required this.amount,
    required this.date,
    required this.merchant,
    required this.category,
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'date': date,
      'merchant': merchant,
      'category': category,
      'imagePath': imagePath,
      'createdAt': createdAt,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      merchant: map['merchant'] as String,
      category: map['category'] as String,
      imagePath: map['imagePath'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  TransactionModel copyWith({
    int? id,
    double? amount,
    String? date,
    String? merchant,
    String? category,
    String? imagePath,
    String? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
