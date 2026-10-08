import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment,
}

class CategoryMetadata {
  final String key;
  final String displayName;
  final IconData icon;
  final Color color;

  const CategoryMetadata({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.color,
  });
}

class CategoryConstants {
  static const Map<ExpenseCategory, CategoryMetadata> categories = {
    ExpenseCategory.food: CategoryMetadata(
      key: 'Food',
      displayName: 'Ăn uống (Food)',
      icon: Icons.restaurant,
      color: Color(0xFFEF4444), // Đỏ
    ),
    ExpenseCategory.study: CategoryMetadata(
      key: 'Study',
      displayName: 'Học tập (Study)',
      icon: Icons.school,
      color: Color(0xFF3B82F6), // Xanh dương
    ),
    ExpenseCategory.travel: CategoryMetadata(
      key: 'Travel',
      displayName: 'Di chuyển (Travel)',
      icon: Icons.directions_car,
      color: Color(0xFF10B981), // Xanh lá
    ),
    ExpenseCategory.gear: CategoryMetadata(
      key: 'Gear',
      displayName: 'Thiết bị (Gear)',
      icon: Icons.devices,
      color: Color(0xFFF59E0B), // Cam
    ),
    ExpenseCategory.entertainment: CategoryMetadata(
      key: 'Entertainment',
      displayName: 'Giải trí (Entertainment)',
      icon: Icons.sports_esports,
      color: Color(0xFF8B5CF6), // Tím
    ),
  };

  static List<String> get categoryKeys =>
      categories.values.map((c) => c.key).toList();

  static CategoryMetadata getMetadataByKey(String key) {
    for (final entry in categories.entries) {
      if (entry.value.key.toLowerCase() == key.toLowerCase()) {
        return entry.value;
      }
    }
    return categories[ExpenseCategory.food]!;
  }

  static Color getColorByKey(String key) => getMetadataByKey(key).color;
  static IconData getIconByKey(String key) => getMetadataByKey(key).icon;
}
