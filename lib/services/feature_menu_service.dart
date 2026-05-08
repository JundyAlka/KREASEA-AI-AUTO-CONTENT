import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feature_menu_item.dart';

/// Local registry of all feature menu items.
/// Can be switched to Firestore StreamBuilder in the future.
class FeatureMenuService {
  static List<FeatureMenuItem> getAllFeatures() {
    return _features.where((f) => f.isVisible).toList()
      ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
  }

  static List<FeatureMenuItem> getGridFeatures() {
    // Exclude the 2 main tools (they have their own prominent cards)
    return getAllFeatures().where((f) => f.priorityOrder > 0).toList();
  }

  static final _features = <FeatureMenuItem>[
    // P1 — Pure Text AI (Free)
    const FeatureMenuItem(id: 'testimoni', name: 'Testimoni Generator', icon: Icons.rate_review_rounded, color: Color(0xFF38EF7D), route: '/features/testimoni', priorityOrder: 1, badge: 'Baru'),
    const FeatureMenuItem(id: 'nama_produk', name: 'Nama Produk AI', icon: Icons.label_rounded, color: Color(0xFFFF6B6B), route: '/features/nama_produk', priorityOrder: 2, badge: 'Baru'),
    const FeatureMenuItem(id: 'gmaps', name: 'Optimasi GMaps', icon: Icons.map_rounded, color: Color(0xFF4285F4), route: '/features/gmaps', priorityOrder: 3, badge: 'Baru'),
    const FeatureMenuItem(id: 'wa_blast', name: 'WA Blast Template', icon: Icons.send_rounded, color: Color(0xFF25D366), route: '/features/wa_blast', priorityOrder: 4, badge: 'Baru'),

    // P2 — Logic + AI (Free)
    const FeatureMenuItem(id: 'balasan_dm', name: 'Balasan DM AI', icon: Icons.quickreply_rounded, color: Color(0xFFE040FB), route: '/features/balasan_dm', priorityOrder: 5, badge: 'Baru'),
    const FeatureMenuItem(id: 'hpp', name: 'Kalkulator HPP', icon: Icons.calculate_rounded, color: Color(0xFF1A56DB), route: '/features/hpp', priorityOrder: 6, badge: 'Baru'),
    const FeatureMenuItem(id: 'content_calendar', name: 'Content Calendar', icon: Icons.calendar_month_rounded, color: Color(0xFFF59E0B), route: '/features/calendar', priorityOrder: 7, badge: 'Pro', requiredPlan: 'pro'),

    // P3 — Complex (Pro)
    const FeatureMenuItem(id: 'bio_link', name: 'Bio Link', icon: Icons.link_rounded, color: Color(0xFF00B4DB), route: '/features/bio_link', priorityOrder: 8, badge: 'Pro', requiredPlan: 'pro'),
    const FeatureMenuItem(id: 'logo_maker', name: 'Logo Maker AI', icon: Icons.brush_rounded, color: Color(0xFFFFD93D), route: '/features/logo_maker', priorityOrder: 9, badge: 'Pro', requiredPlan: 'pro'),
    const FeatureMenuItem(id: 'foto_analisis', name: 'Analisis Foto', icon: Icons.photo_camera_rounded, color: Color(0xFF4FC3F7), route: '/features/foto_analisis', priorityOrder: 10, badge: 'Pro', requiredPlan: 'pro'),

    // P4 — Premium
    const FeatureMenuItem(id: 'website_kilat', name: 'Website Kilat', icon: Icons.web_rounded, color: Color(0xFFE91E63), route: '/features/website', priorityOrder: 11, badge: 'Premium', requiredPlan: 'premium', isComingSoon: true),

    // Coming Soon
    const FeatureMenuItem(id: 'hashtag', name: 'Hashtag AI', icon: Icons.tag_rounded, color: Color(0xFFFF6B6B), route: '', priorityOrder: 12, badge: 'Soon', isComingSoon: true),
    const FeatureMenuItem(id: 'reels_maker', name: 'Reels Maker', icon: Icons.video_camera_back_rounded, color: Color(0xFFE040FB), route: '', priorityOrder: 13, badge: 'Soon', isComingSoon: true),
    const FeatureMenuItem(id: 'brand_kit', name: 'Brand Kit', icon: Icons.color_lens_rounded, color: Color(0xFFFFD93D), route: '', priorityOrder: 14, badge: 'Soon', isComingSoon: true),
  ];
}

final featureMenuProvider = Provider<List<FeatureMenuItem>>((ref) {
  return FeatureMenuService.getGridFeatures();
});
