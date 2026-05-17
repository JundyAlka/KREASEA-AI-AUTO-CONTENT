import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/content_item.dart';
import '../../repositories/content_repository.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';

// Provider menggunakan UID real dari auth state
final userContentStreamProvider = StreamProvider.autoDispose<List<ContentItem>>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    data: (profile) {
      final uid = profile?.uid;
      if (uid == null || uid.isEmpty || uid == 'guest') {
        // Guest: kembalikan stream kosong
        return Stream.value(<ContentItem>[]);
      }
      return repo.watchContent(uid);
    },
    loading: () => Stream.value(<ContentItem>[]),
    error: (_, __) => Stream.value(<ContentItem>[]),
  );
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  final _filters = ['Semua', 'Instagram', 'TikTok', 'Facebook', 'Caption', 'Gambar'];

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(userContentStreamProvider);
    final authAsync = ref.watch(authStateProvider);
    final isGuest = authAsync.valueOrNull?.uid == 'guest' || authAsync.valueOrNull == null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Gradient Header
          const GlassGradientHeader(
            title: 'Library Konten',
            subtitle: 'Semua konten yang pernah kamu buat',
            icon: Icons.folder_rounded,
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                // Search Bar
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cari konten...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Pills
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final filter = _filters[i];
                      final isSelected = _selectedFilter == filter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(colors: [AppColors.grad1, AppColors.grad2])
                                : null,
                            color: isSelected ? null : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Content List
          Expanded(
            child: isGuest
                ? _buildGuestState(context)
                : contentAsync.when(
                    data: (items) {
                      final filtered = _filterItems(items);
                      if (filtered.isEmpty && items.isEmpty) {
                        return _buildEmptyState();
                      }
                      if (filtered.isEmpty) {
                        return _buildNoResultState();
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _GlassContentCard(item: filtered[index])
                              .animate(delay: (index * 50).ms)
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.1, end: 0);
                        },
                      );
                    },
                    error: (e, _) => _buildErrorState(e.toString()),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.accentLight),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<ContentItem> _filterItems(List<ContentItem> items) {
    return items.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.body.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'Semua' ||
          item.platform.name.toLowerCase().contains(_selectedFilter.toLowerCase());
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.grad1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.folder_open_rounded, size: 50, color: AppColors.grad1.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Library masih kosong',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Konten yang kamu generate akan\notomatis tersimpan di sini',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => context.go('/dashboard'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.grad1, AppColors.grad2]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '✨ Buat Konten Pertama',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
    );
  }

  Widget _buildNoResultState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('Tidak ada konten ditemukan', style: TextStyle(color: Colors.white38, fontSize: 15)),
          const SizedBox(height: 8),
          Text('Coba kata kunci lain', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.lock_rounded, size: 48, color: Colors.amber),
          ),
          const SizedBox(height: 20),
          const Text(
            'Login untuk melihat Library',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Masuk dengan akunmu untuk menyimpan\ndan mengelola semua konten AI',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.grad1, AppColors.grad2]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '🔐 Masuk Sekarang',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('Gagal memuat konten', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 4),
          Text(error, style: const TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }
}

class _GlassContentCard extends StatelessWidget {
  final ContentItem item;
  const _GlassContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    Color tagColor = AppColors.grad1;
    IconData icon = Icons.article_rounded;

    final platformName = item.platform.name.toLowerCase();
    if (platformName.contains('instagram')) {
      tagColor = const Color(0xFFE1306C);
      icon = Icons.camera_alt_rounded;
    } else if (platformName.contains('tiktok')) {
      tagColor = const Color(0xFF69C9D0);
      icon = Icons.music_note_rounded;
    } else if (platformName.contains('facebook')) {
      tagColor = const Color(0xFF1877F2);
      icon = Icons.facebook_rounded;
    } else if (platformName.contains('gambar') || platformName.contains('image')) {
      tagColor = const Color(0xFF9C27B0);
      icon = Icons.image_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.go('/library/detail', extra: item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [tagColor.withOpacity(0.3), tagColor.withOpacity(0.1)],
                    ),
                  ),
                  child: Icon(icon, color: tagColor, size: 24),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.platform.name,
                              style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                            style: const TextStyle(fontSize: 10, color: Colors.white24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
