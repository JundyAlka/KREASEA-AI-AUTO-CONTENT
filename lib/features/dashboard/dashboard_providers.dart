import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/content_item.dart';
import '../../repositories/content_repository.dart';
import '../../services/auth_service.dart';

/// Provides the current user's real content stream.
/// Returns empty list if user is not logged in.
final userContentProvider = StreamProvider<List<ContentItem>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userProfile = authState.valueOrNull;

  if (userProfile == null) {
    return Stream.value([]);
  }

  final repo = ref.watch(contentRepositoryProvider);
  return repo.watchContent(userProfile.uid);
});

/// Derived: recent content (max 5, sorted by date)
final recentContentProvider = Provider<AsyncValue<List<ContentItem>>>((ref) {
  final contentAsync = ref.watch(userContentProvider);
  return contentAsync.whenData((items) {
    final sorted = List<ContentItem>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  });
});

/// Derived stats from real content
final contentStatsProvider = Provider<AsyncValue<ContentStats>>((ref) {
  final contentAsync = ref.watch(userContentProvider);
  return contentAsync.whenData((items) {
    final total = items.length;
    final scheduled = items.where((i) => i.isScheduled).length;
    // For draft: items without imageUrl or short body can be considered drafts
    // In a real app, you'd have a 'status' field. For now, use a simple heuristic.
    final drafts = items.where((i) => i.body.length < 20).length;
    return ContentStats(total: total, scheduled: scheduled, drafts: drafts);
  });
});

class ContentStats {
  final int total;
  final int scheduled;
  final int drafts;

  const ContentStats({required this.total, required this.scheduled, required this.drafts});
}
