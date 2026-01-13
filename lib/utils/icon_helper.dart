import 'package:flutter/material.dart';

class IconHelper {
  static IconData getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('comida') || name.contains('super') || name.contains('restaurant')) {
      return Icons.restaurant;
    }
    if (name.contains('transporte') || name.contains('gasolina') || name.contains('uber')) {
      return Icons.directions_car;
    }
    if (name.contains('casa') || name.contains('alquiler') || name.contains('luz') || name.contains('agua')) {
      return Icons.home;
    }
    if (name.contains('servicio') || name.contains('internet') || name.contains('teléfono')) {
      return Icons.lightbulb;
    }
    if (name.contains('salud') || name.contains('farmacia') || name.contains('doctor')) {
      return Icons.local_hospital;
    }
    if (name.contains('ocio') || name.contains('cine') || name.contains('juego')) {
      return Icons.movie;
    }
    if (name.contains('compra') || name.contains('ropa') || name.contains('shopping')) {
      return Icons.shopping_bag;
    }
    if (name.contains('sueldo') || name.contains('salario')) {
      return Icons.attach_money;
    }
    if (name.contains('transferencia')) {
      return Icons.swap_horiz;
    }
    return Icons.category;
  }

  static IconData getIconByName(String iconName) {
    switch (iconName) {
      // Basic
      case 'category': return Icons.category;
      case 'flag': return Icons.flag;
      case 'star': return Icons.star;
      
      // Food & Drink
      case 'restaurant': return Icons.restaurant;
      case 'fastfood': return Icons.fastfood;
      case 'local_cafe': return Icons.local_cafe;
      case 'local_bar': return Icons.local_bar;
      case 'local_pizza': return Icons.local_pizza;
      
      // Transport
      case 'directions_car': return Icons.directions_car;
      case 'directions_bus': return Icons.directions_bus;
      case 'flight': return Icons.flight;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'train': return Icons.train;
      
      // Home & Utilities
      case 'home': return Icons.home;
      case 'lightbulb': return Icons.lightbulb;
      case 'water_drop': return Icons.water_drop;
      case 'wifi': return Icons.wifi;
      case 'phone': return Icons.phone;
      case 'build': return Icons.build;
      
      // Health
      case 'local_hospital': return Icons.local_hospital;
      case 'medical_services': return Icons.medical_services;
      case 'fitness_center': return Icons.fitness_center;
      
      // Shopping
      case 'shopping_bag': return Icons.shopping_bag;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'checkroom': return Icons.checkroom; // Clothes
      case 'card_giftcard': return Icons.card_giftcard;
      
      // Entertainment
      case 'movie': return Icons.movie;
      case 'sports_esports': return Icons.sports_esports;
      case 'music_note': return Icons.music_note;
      case 'sports_soccer': return Icons.sports_soccer;
      
      // Education & Work
      case 'school': return Icons.school;
      case 'work': return Icons.work;
      case 'laptop': return Icons.laptop;
      case 'book': return Icons.book;
      
      // Finance
      case 'attach_money': return Icons.attach_money;
      case 'savings': return Icons.savings;
      case 'account_balance': return Icons.account_balance;
      case 'credit_card': return Icons.credit_card;
      case 'trending_up': return Icons.trending_up;
      case 'trending_down': return Icons.trending_down;
      case 'swap_horiz': return Icons.swap_horiz;
      
      // Others
      case 'pets': return Icons.pets;
      case 'child_care': return Icons.child_care;
      case 'celebration': return Icons.celebration;
      
      default: return Icons.category;
    }
  }

  static const List<String> availableIcons = [
    'restaurant', 'fastfood', 'local_cafe', 'local_bar', 'local_pizza',
    'directions_car', 'directions_bus', 'flight', 'local_gas_station', 'train',
    'home', 'lightbulb', 'water_drop', 'wifi', 'phone', 'build',
    'local_hospital', 'medical_services', 'fitness_center',
    'shopping_bag', 'shopping_cart', 'checkroom', 'card_giftcard',
    'movie', 'sports_esports', 'music_note', 'sports_soccer',
    'school', 'work', 'laptop', 'book',
    'attach_money', 'savings', 'account_balance', 'credit_card', 'trending_up', 'trending_down', 'swap_horiz',
    'pets', 'child_care', 'celebration', 'star', 'flag', 'category'
  ];
}
