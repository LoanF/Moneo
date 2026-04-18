import 'package:flutter/material.dart';

class IconHelper {
  static Map<String, IconData> iconsMap = {
    'shopping_cart': Icons.shopping_cart_rounded,
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'flash_on': Icons.flash_on_rounded,
    'medical_services': Icons.medical_services_rounded,
    'school': Icons.school_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'movie': Icons.movie_rounded,
    'flight': Icons.flight_rounded,
    'pets': Icons.pets_rounded,
    'account_balance': Icons.account_balance_rounded,
    'celebration': Icons.celebration_rounded,
    'work': Icons.work_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'checkroom': Icons.checkroom_rounded,
    'smartphone': Icons.smartphone_rounded,
    'coffee': Icons.coffee_rounded,
    'fastfood': Icons.fastfood_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'savings': Icons.savings_rounded,
  };

  static IconData getIcon(String name) {
    return iconsMap[name] ?? Icons.help_outline_rounded;
  }

  static String getName(IconData data) {
    return iconsMap.entries
        .firstWhere((e) => e.value.codePoint == data.codePoint, orElse: () => iconsMap.entries.first)
        .key;
  }
}