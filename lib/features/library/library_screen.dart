import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/content_item.dart';
import '../../repositories/content_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';

// Controller/Provider
final contentStreamProvider = StreamProvider.autoDispose<List<ContentItem>>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.watchContent('demo-user');
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  final _filters = ['Semua', 'Instagram', 'TikTok', 'Draft', 'Favorit'];

  @override
  Widget build(BuildContext context) {
    final mock = GoRouterState.of(context).uri.queryParameters['mock'] == 'true';
    final contentAsync = mock
        ? AsyncValue.data(List.generate(5, (i) => ContentItem.demo(i.toString())))
        : ref.watch(contentStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Gradient Header
          const GlassGradientHeader(
            title: 'Library Konten',
            subtitle: 'Kelola semua konten yang pernah kamu buat',
            icon: Icons.folder_rounded,
          ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                // Glass Search Bar
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
            child: contentAsync.when(
              data: (items) {
                final filteredItems = items.where((item) {
                  final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      item.body.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesFilter = _selectedFilter == 'Semua' ||
                      item.platform.name.contains(_selectedFilter) ||
                      (_selectedFilter == 'Draft' && false);
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text('Tidak ada konten ditemukan', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    return _GlassContentCard(item: filteredItems[index]);
                  },
                );
              },
              error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentLight)),
            ),
          ),
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
    IconData icon = Icons.article;
    if (item.platform.name.toLowerCase().contains('instagram')) {
      tagColor = const Color(0xFFE1306C);
      icon = Icons.camera_alt;
    } else if (item.platform.name.toLowerCase().contains('tiktok')) {
      tagColor = const Color(0xFF69C9D0);
      icon = Icons.music_note;
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
                        maxLines: 1,
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
