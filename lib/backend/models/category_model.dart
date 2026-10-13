import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String? uid;
  final String name;
  final String iconKey;
  final String type; // 'expense' or 'income'
  final int sortOrder;
  final bool isDefault;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;
  final bool isLinked; // Runtime property indicating if linked to current ledger

  CategoryModel({
    this.id,
    this.uid,
    required this.name,
    required this.iconKey,
    required this.type,
    required this.sortOrder,
    required this.isDefault,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.isLinked = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'iconKey': iconKey,
      'type': type,
      'sortOrder': sortOrder,
      'isDefault': isDefault ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, {bool isLinked = true}) {
    return CategoryModel(
      id: map['id'] as int?,
      uid: map['uid'] as String?,
      name: map['name'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? 'category_rounded',
      type: map['type'] as String? ?? 'expense',
      sortOrder: map['sortOrder'] as int? ?? 0,
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
      isArchived: (map['isArchived'] as int? ?? 0) == 1,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      isLinked: isLinked,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? uid,
    String? name,
    String? iconKey,
    String? type,
    int? sortOrder,
    bool? isDefault,
    bool? isArchived,
    String? createdAt,
    String? updatedAt,
    bool? isLinked,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLinked: isLinked ?? this.isLinked,
    );
  }

  static IconData getIconData(String iconKey) {
    switch (iconKey) {
      case 'fastfood_rounded':
        return Icons.fastfood_rounded;
      case 'receipt_rounded':
        return Icons.receipt_rounded;
      case 'directions_bus_rounded':
        return Icons.directions_bus_rounded;
      case 'shopping_bag_rounded':
        return Icons.shopping_bag_rounded;
      case 'sports_esports_rounded':
        return Icons.sports_esports_rounded;
      case 'medical_services_rounded':
        return Icons.medical_services_rounded;
      case 'content_cut_rounded':
        return Icons.content_cut_rounded;
      case 'checkroom_rounded':
        return Icons.checkroom_rounded;
      case 'school_rounded':
        return Icons.school_rounded;
      case 'pets_rounded':
        return Icons.pets_rounded;
      case 'child_care_rounded':
        return Icons.child_care_rounded;
      case 'family_restroom_rounded':
        return Icons.family_restroom_rounded;
      case 'security_rounded':
        return Icons.security_rounded;
      case 'account_balance_rounded':
        return Icons.account_balance_rounded;
      case 'work_rounded':
        return Icons.work_rounded;
      case 'home_rounded':
        return Icons.home_rounded;
      case 'money_off_rounded':
        return Icons.money_off_rounded;
      case 'account_balance_wallet_rounded':
        return Icons.account_balance_wallet_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'storefront_rounded':
        return Icons.storefront_rounded;
      case 'trending_up_rounded':
        return Icons.trending_up_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      case 'flight_rounded':
        return Icons.flight_rounded;
      case 'local_cafe_rounded':
        return Icons.local_cafe_rounded;
      case 'local_grocery_store_rounded':
        return Icons.local_grocery_store_rounded;
      case 'fitness_center_rounded':
        return Icons.fitness_center_rounded;
      case 'category_rounded':
      default:
        return Icons.category_rounded;
    }
  }
}
