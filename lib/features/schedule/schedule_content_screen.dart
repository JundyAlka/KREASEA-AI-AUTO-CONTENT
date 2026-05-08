import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/social_scheduler_service.dart';
import '../../models/content_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';

class ScheduleContentScreen extends ConsumerStatefulWidget {
  const ScheduleContentScreen({super.key});

  @override
  ConsumerState<ScheduleContentScreen> createState() => _ScheduleContentScreenState();
}

class _ScheduleContentScreenState extends ConsumerState<ScheduleContentScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _isCalendarView = false;
  final _contentTitleController = TextEditingController();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accent,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _selectedTime ?? TimeOfDay.now());
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _schedule() async {
    if (_selectedDate == null || _selectedTime == null || _contentTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi form jadwal')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dt = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );
      final item = ContentItem.demo('999');
      final service = ref.read(socialSchedulerServiceProvider);
      await service.schedulePost(item, dt);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil dijadwalkan pada $dt')));
        context.pop();
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient Header
            const GlassGradientHeader(
              title: 'Jadwal Post',
              subtitle: 'Atur waktu posting kontenmu secara otomatis',
              icon: Icons.calendar_month_rounded,
              gradientColors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // View Toggle
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tampilan Kalender', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                        Switch(
                          value: _isCalendarView,
                          onChanged: (v) => setState(() => _isCalendarView = v),
                          activeColor: AppColors.accentLight,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_isCalendarView)
                    _buildCalendarMock()
                  else
                    _buildScheduleForm(),

                  const SizedBox(height: 24),

                  // Upcoming Schedules (Mock)
                  const Text(
                    'Jadwal Mendatang',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  _buildUpcomingItem('Promo Spesial Ayam Geprek', 'Instagram • Besok 10:00', Icons.camera_alt, const Color(0xFFE1306C)),
                  _buildUpcomingItem('Flash Sale Weekend', 'TikTok • Sabtu 19:00', Icons.music_note, const Color(0xFF69C9D0)),
                  _buildUpcomingItem('Menu Baru Announcement', 'WhatsApp • Senin 08:00', Icons.chat, const Color(0xFF25D366)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingItem(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Menunggu', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleForm() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Konten yang akan dijadwalkan', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          // Glass text field
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: TextField(
                controller: _contentTitleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Masukkan judul konten',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.article_rounded, color: AppColors.accentLight.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.accentLight),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildPickerButton(Icons.calendar_month, _selectedDate == null ? 'Pilih Tanggal' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}', AppColors.grad1, _pickDate)),
              const SizedBox(width: 12),
              Expanded(child: _buildPickerButton(Icons.access_time_rounded, _selectedTime == null ? 'Pilih Jam' : _selectedTime!.format(context), AppColors.warning, _pickTime)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _schedule,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentLight,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.accentLight.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule_send_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Simpan Jadwal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton(IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.8), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarMock() {
    return GlassContainer(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_week, size: 48, color: AppColors.accentLight.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Tampilan Kalender Penuh', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('(Fitur akan datang)', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
