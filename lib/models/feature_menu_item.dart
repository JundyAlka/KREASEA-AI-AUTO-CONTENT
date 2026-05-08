import 'package:flutter/material.dart';

/// Represents a feature menu item in the dashboard grid.
class FeatureMenuItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String route;
  final int priorityOrder;
  final bool isVisible;
  final String badge; // 'Baru', 'Pro', 'Soon', ''
  final bool isComingSoon;
  final String requiredPlan; // 'free', 'pro', 'premium'

  const FeatureMenuItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.route,
    required this.priorityOrder,
    this.isVisible = true,
    this.badge = '',
    this.isComingSoon = false,
    this.requiredPlan = 'free',
  });
}
