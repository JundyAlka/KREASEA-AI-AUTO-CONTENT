import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_button.dart';
import '../../models/user_profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _businessNameController = TextEditingController();
  final _descController = TextEditingController();
  final _audienceController = TextEditingController();
  
  String? _selectedType;
  final List<String> _businessTypes = ['Makanan & Minuman', 'Fashion', 'Jasa', 'Elektronik', 'Kesehatan', 'Lainnya'];

  String? _selectedTone;
  final List<String> _tones = ['Formal', 'Santai', 'Lucu', 'Elegan', 'Syar\'i', 'Gen Z'];

  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null || _selectedTone == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon lengkapi semua pilihan')),
        );
        return;
    }

    setState(() => _isLoading = true);

    try {
      // In a real app we would get the current user from auth state
      // For now we mock creating a profile update
      final authService = ref.read(authServiceProvider);
      final currentUser = authService.currentUser;
      
      final userProfile = currentUser?.copyWith(
        businessName: _businessNameController.text,
        businessType: _selectedType,
        brandTone: _selectedTone,
        targetAudience: _audienceController.text,
        businessDescription: _descController.text,
        isOnboardingComplete: true,
      ) ?? UserProfile(
        uid: 'unknown',
        email: 'unknown',
        businessName: _businessNameController.text,
        businessType: _selectedType!,
        brandTone: _selectedTone!,
        targetAudience: _audienceController.text,
        businessDescription: _descController.text,
        isOnboardingComplete: true,
      );

      await authService.updateProfile(userProfile);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Bisnis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yuk kenalan dengan bisnismu!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Data ini akan membantu AI membuat konten yang relevan.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(labelText: 'Nama Bisnis / Brand'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Jenis Usaha'),
                items: _businessTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _selectedTone,
                decoration: const InputDecoration(labelText: 'Tone / Gaya Bahasa'),
                items: _tones.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedTone = v),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _audienceController,
                decoration: const InputDecoration(labelText: 'Target Audiens (Misal: Mahasiswa, Ibu-ibu)'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Deskripsi Singkat Bisnis'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Simpan & Lanjut',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
