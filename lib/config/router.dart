import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../features/splash/splash_router_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dashboard/metric_detail_screen.dart';
import '../features/library/library_screen.dart';
import '../features/schedule/schedule_content_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/business_profile_screen.dart';
import '../features/ai_text/ai_text_screen.dart';
import '../features/ai_image/ai_image_screen.dart';
import '../features/content_detail/content_detail_screen.dart';
import '../features/recommendation_detail/recommendation_detail_screen.dart';
import '../features/testimoni/testimoni_screen.dart';
import '../features/nama_produk/nama_produk_screen.dart';
import '../features/gmaps/gmaps_screen.dart';
import '../features/wa_blast/wa_blast_screen.dart';
import '../features/balasan_dm/balasan_dm_screen.dart';
import '../features/hpp/hpp_screen.dart';
import '../features/content_calendar/calendar_screen.dart';
import '../models/content_item.dart';
import '../widgets/scaffold_with_navbar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash', // ← mulai dari splash, bukan dashboard
  routes: [
    // ── Splash + Onboarding ──────────────────────────────────
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashRouterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // ── Auth ─────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // ── Feature routes (tanpa bottom nav) ────────────────────
    GoRoute(path: '/features/testimoni', builder: (_, __) => const TestimoniScreen()),
    GoRoute(path: '/features/nama_produk', builder: (_, __) => const NamaProdukScreen()),
    GoRoute(path: '/features/gmaps', builder: (_, __) => const GmapsScreen()),
    GoRoute(path: '/features/wa_blast', builder: (_, __) => const WaBlastScreen()),
    GoRoute(path: '/features/balasan_dm', builder: (_, __) => const BalasanDmScreen()),
    GoRoute(path: '/features/hpp', builder: (_, __) => const HppScreen()),
    GoRoute(path: '/features/calendar', builder: (_, __) => const ContentCalendarScreen()),

    // ── Main app dengan bottom navigation ─────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
              routes: [
                GoRoute(
                  path: 'ai_text',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, __) => const AiTextScreen(),
                ),
                GoRoute(
                  path: 'ai_image',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, __) => const AiImageScreen(),
                ),
                GoRoute(
                  path: 'recommendation',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final data = (state.extra is Map<String, dynamic>)
                        ? state.extra as Map<String, dynamic>
                        : <String, dynamic>{'title': '', 'type': '', 'desc': '', 'image': ''};
                    return RecommendationDetailScreen(data: data);
                  },
                ),
                GoRoute(
                  path: 'metric/:type',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final type = state.pathParameters['type'] ?? 'reach';
                    return MetricDetailScreen(metricType: type);
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 2: Library
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (_, __) => const LibraryScreen(),
              routes: [
                GoRoute(
                  path: 'detail',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final item = (state.extra is ContentItem)
                        ? state.extra as ContentItem
                        : ContentItem.demo('fallback');
                    return ContentDetailScreen(item: item);
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 3: Schedule
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/schedule',
              builder: (_, __) => const ScheduleContentScreen(),
            ),
          ],
        ),

        // Tab 4: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'business_profile',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, __) => const BusinessProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
