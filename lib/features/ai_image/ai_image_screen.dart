import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/stability_ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/credit_service.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';
import '../../widgets/credit_widgets.dart';

class AiImageScreen extends ConsumerStatefulWidget {
  const AiImageScreen({super.key});
  @override
  ConsumerState<AiImageScreen> createState() => _AiImageScreenState();
}

class _AiImageScreenState extends ConsumerState<AiImageScreen> {
  final _promptController = TextEditingController();

  String _selectedType = 'Square Post (1:1)';
  final _types = [
    'Square Post (1:1)',
    'Story (9:16)',
    'Banner (16:9)',
    'Portrait (3:4)',
    'Wide (21:9)'
  ];

  String? _selectedPurpose;
  final _purposes = [
    'Promo Diskon',
    'Pengumuman',
    'Testimoni',
    'Produk Showcase',
    'Quotes',
    'Menu / Katalog',
    'Event / Undangan',
    'Thumbnail Video',
    'Cover Highlight',
  ];

  // Pilihan style sengaja dikurasi per tujuan agar hasilnya tidak janggal.
  static const _moodRecommendations = <String, List<String>>{
    'Promo Diskon': [
      'Bold Promo',
      'Playful/Ceria',
      'Flat Design',
      '3D Render',
      'Clean Studio'
    ],
    'Pengumuman': ['Minimalis', 'Flat Design', 'Bold Promo', 'Clean Studio'],
    'Testimoni': [
      'Warm & Cozy',
      'Photography',
      'Pastel Aesthetic',
      'Minimalis'
    ],
    'Produk Showcase': [
      'Clean Studio',
      'Photography',
      'Minimalis',
      'Elegan/Mewah',
      '3D Render'
    ],
    'Quotes': ['Minimalis', 'Pastel Aesthetic', 'Watercolor', 'Elegan/Mewah'],
    'Menu / Katalog': [
      'Warm & Cozy',
      'Photography',
      'Clean Studio',
      'Elegan/Mewah'
    ],
    'Event / Undangan': [
      'Playful/Ceria',
      'Elegan/Mewah',
      'Ramadan / Islami',
      'Bold Promo'
    ],
    'Thumbnail Video': [
      'Bold Promo',
      'Playful/Ceria',
      'Futuristic',
      '3D Render'
    ],
    'Cover Highlight': [
      'Minimalis',
      'Pastel Aesthetic',
      'Flat Design',
      'Elegan/Mewah'
    ],
  };

  String _selectedMood = 'Minimalis';
  final _moods = [
    'Minimalis',
    'Photography',
    'Clean Studio',
    'Bold Promo',
    'Playful/Ceria'
  ];

  static const _styleDescriptions = <String, String>{
    'Minimalis': 'Bersih, rapi, mudah dibaca',
    'Photography': 'Foto produk realistis',
    'Playful/Ceria': 'Warna cerah dan fun',
    'Elegan/Mewah': 'Premium, gold, classy',
    'Warm & Cozy': 'Hangat dan dekat',
    'Bold Promo': 'Poster promo mencolok',
    'Clean Studio': 'Marketplace ready',
    'Pastel Aesthetic': 'Lembut dan kekinian',
    'Ramadan / Islami': 'Nuansa Ramadan/Eid',
    'Flat Design': 'Grafis modern tegas',
    '3D Render': 'Visual 3D produk',
    'Futuristic': 'Tech dan high-energy',
    'Watercolor': 'Artistik untuk quotes',
  };

  String _selectedColor = 'Auto';
  final _colors = [
    'Auto',
    'Warna Brand',
    'Bold & Vibrant',
    'Pastel',
    'Earth Tone'
  ];

  static const _colorRecommendations = <String, List<String>>{
    'Promo Diskon': [
      'Auto',
      'Warna Brand',
      'Bold & Vibrant',
      'Merah Promo',
      'Kuning Cerah'
    ],
    'Pengumuman': ['Auto', 'Warna Brand', 'Monochrome', 'Biru Profesional'],
    'Testimoni': ['Auto', 'Warm Neutral', 'Pastel', 'Earth Tone'],
    'Produk Showcase': ['Auto', 'Warna Brand', 'Clean White', 'Earth Tone'],
    'Quotes': ['Auto', 'Pastel', 'Monochrome', 'Earth Tone'],
    'Menu / Katalog': ['Auto', 'Warm Neutral', 'Earth Tone', 'Warna Brand'],
    'Event / Undangan': ['Auto', 'Gold & Luxury', 'Pastel', 'Warna Brand'],
    'Thumbnail Video': ['Auto', 'Bold & Vibrant', 'Neon', 'Kuning Cerah'],
    'Cover Highlight': ['Auto', 'Warna Brand', 'Pastel', 'Monochrome'],
  };

  // Smart size recommendations per purpose
  static const _sizeRecommendations = <String, List<String>>{
    'Promo Diskon': ['Square Post (1:1)', 'Story (9:16)', 'Banner (16:9)'],
    'Pengumuman': ['Square Post (1:1)', 'Banner (16:9)'],
    'Testimoni': ['Square Post (1:1)', 'Portrait (3:4)'],
    'Produk Showcase': ['Square Post (1:1)', 'Portrait (3:4)'],
    'Quotes': ['Square Post (1:1)', 'Story (9:16)'],
    'Menu / Katalog': ['Square Post (1:1)', 'Portrait (3:4)'],
    'Event / Undangan': ['Story (9:16)', 'Square Post (1:1)'],
    'Thumbnail Video': ['Banner (16:9)', 'Wide (21:9)'],
    'Cover Highlight': ['Square Post (1:1)', 'Portrait (3:4)'],
  };

  // Hint text per purpose
  static const _purposeHints = <String, String>{
    'Promo Diskon':
        'Contoh: Diskon 50% sepatu Nike, background merah energik, produk di tengah...',
    'Pengumuman':
        'Contoh: Pengumuman jam buka toko baru, nuansa profesional dan bersih...',
    'Testimoni':
        'Contoh: Pelanggan bahagia minum kopi, ekspresi puas, suasana hangat...',
    'Produk Showcase':
        'Contoh: Kopi susu gula aren dalam gelas kaca bening di atas meja kayu...',
    'Quotes':
        'Contoh: Background gradasi ungu ke biru, nuansa tenang dan inspiratif...',
    'Menu / Katalog':
        'Contoh: Nasi goreng spesial dengan telur ceplok, garnish daun bawang...',
    'Event / Undangan':
        'Contoh: Dekorasi ulang tahun mewah, balon emas, confetti berkilau...',
    'Thumbnail Video':
        'Contoh: Wajah terkejut di depan laptop, teks besar di kanan, kontras tinggi...',
    'Cover Highlight':
        'Contoh: Ikon minimalis kopi di background hitam elegan, clean dan bold...',
  };

  static const _promptSuggestions = <String, List<_PromptSuggestion>>{
    'Promo Diskon': [
      _PromptSuggestion(
        title: 'Flash Sale Produk',
        prompt:
            'Poster promo flash sale untuk produk utama, diskon besar terlihat menonjol, produk berada di tengah sebagai hero, background warna merah dan kuning yang energik, ada ruang kosong untuk teks harga dan CTA, visual modern, kontras tinggi, cocok untuk Instagram feed.',
      ),
      _PromptSuggestion(
        title: 'Bundling Hemat',
        prompt:
            'Desain promosi paket bundling hemat untuk UMKM, beberapa produk tersusun rapi dalam komposisi dinamis, suasana ceria dan terpercaya, elemen badge promo besar, warna brand dominan, lighting terang, tampilan profesional untuk marketplace dan media sosial.',
      ),
      _PromptSuggestion(
        title: 'Promo Grand Opening',
        prompt:
            'Poster grand opening toko dengan nuansa ramai dan mengundang, produk atau storefront menjadi fokus utama, dekorasi confetti dan elemen celebratory, warna vivid, layout clean dengan ruang untuk tanggal, lokasi, dan call to action.',
      ),
    ],
    'Pengumuman': [
      _PromptSuggestion(
        title: 'Jam Operasional',
        prompt:
            'Visual pengumuman perubahan jam operasional toko, desain bersih dan profesional, ikon jam sebagai elemen utama, background warna brand yang tenang, hierarchy jelas, ruang kosong untuk detail tanggal dan jam, mudah dibaca di layar mobile.',
      ),
      _PromptSuggestion(
        title: 'Info Cabang Baru',
        prompt:
            'Desain pengumuman pembukaan cabang baru, storefront modern sebagai focal point, suasana optimis dan terpercaya, warna biru profesional dengan aksen brand, komposisi rapi, menyediakan area teks untuk alamat dan tanggal pembukaan.',
      ),
      _PromptSuggestion(
        title: 'Stok Terbatas',
        prompt:
            'Visual pengumuman stok produk terbatas, produk utama tampil jelas di tengah, elemen alert halus tanpa terlihat murahan, kontras tinggi, background clean, ruang untuk pesan singkat dan CTA segera pesan.',
      ),
    ],
    'Testimoni': [
      _PromptSuggestion(
        title: 'Pelanggan Puas',
        prompt:
            'Visual testimoni pelanggan puas setelah menggunakan produk, suasana hangat dan natural, ekspresi bahagia, produk terlihat di foreground, background cafe atau rumah yang cozy, pencahayaan golden hour, area kosong untuk kutipan review.',
      ),
      _PromptSuggestion(
        title: 'Before After',
        prompt:
            'Desain social proof before-after yang elegan, dua area visual seimbang, produk atau layanan terlihat sebagai solusi, warna hangat dan terpercaya, layout clean, ruang untuk rating bintang dan komentar singkat pelanggan.',
      ),
      _PromptSuggestion(
        title: 'Review Marketplace',
        prompt:
            'Grafis testimoni marketplace untuk UMKM, ilustrasi kartu review yang modern tanpa teks terbaca, produk utama tetap menjadi hero, nuansa ramah, terpercaya, soft pastel, cocok untuk Instagram feed.',
      ),
    ],
    'Produk Showcase': [
      _PromptSuggestion(
        title: 'Hero Product Studio',
        prompt:
            'Foto produk profesional untuk showcase, produk utama berada di tengah dengan detail tajam, background clean white atau warna brand yang lembut, studio lighting dengan soft shadow, komposisi premium, cocok untuk katalog dan marketplace.',
      ),
      _PromptSuggestion(
        title: 'Lifestyle Product',
        prompt:
            'Visual lifestyle produk dalam konteks penggunaan sehari-hari, produk terlihat natural dan menarik, properti pendukung sesuai kategori bisnis, pencahayaan hangat, depth of field lembut, suasana autentik dan premium.',
      ),
      _PromptSuggestion(
        title: 'Detail Bahan',
        prompt:
            'Close-up produk yang menonjolkan tekstur, bahan, dan kualitas, komposisi macro photography, background sederhana, lighting dramatis namun tetap natural, visual bersih untuk menampilkan keunggulan produk.',
      ),
    ],
    'Quotes': [
      _PromptSuggestion(
        title: 'Motivasi Brand',
        prompt:
            'Background visual untuk quote motivasi bisnis, gradasi lembut dan atmosfer inspiratif, elemen abstrak halus, ruang kosong besar di tengah untuk teks quote, kontras cukup agar tulisan mudah dibaca, aesthetic dan profesional.',
      ),
      _PromptSuggestion(
        title: 'Quote Islami',
        prompt:
            'Background quote bernuansa Islami yang elegan, ornamen geometris halus, warna hijau tua, cream, dan gold, pencahayaan lembut, area kosong untuk teks utama, suasana tenang, spiritual, dan premium.',
      ),
      _PromptSuggestion(
        title: 'Quote Produktif',
        prompt:
            'Visual quote produktivitas untuk media sosial, meja kerja rapi dengan cahaya pagi, elemen notebook dan kopi, warna hangat netral, banyak negative space untuk teks, tampilan minimalis dan modern.',
      ),
    ],
    'Menu / Katalog': [
      _PromptSuggestion(
        title: 'Menu Makanan',
        prompt:
            'Foto menu makanan yang sangat menggugah selera, hidangan utama tersaji rapi dari angle 45 derajat, garnish segar, tekstur makanan terlihat jelas, pencahayaan hangat, background meja kayu, cocok untuk menu digital restoran.',
      ),
      _PromptSuggestion(
        title: 'Katalog Produk',
        prompt:
            'Layout katalog produk UMKM yang rapi dan premium, beberapa item produk tersusun grid clean, background netral, shadow lembut, warna brand sebagai aksen, ruang untuk nama produk dan harga.',
      ),
      _PromptSuggestion(
        title: 'Minuman Signature',
        prompt:
            'Showcase minuman signature, gelas terlihat segar dengan embun dingin, es batu dan topping terlihat detail, background cafe cozy, lighting natural, warna appetizing, komposisi untuk poster menu.',
      ),
    ],
    'Event / Undangan': [
      _PromptSuggestion(
        title: 'Undangan Launching',
        prompt:
            'Desain undangan launching produk baru, suasana eksklusif dan celebratory, produk tampak sebagai centerpiece, elemen spotlight, confetti halus, warna brand premium, ruang untuk tanggal, lokasi, dan RSVP.',
      ),
      _PromptSuggestion(
        title: 'Workshop UMKM',
        prompt:
            'Poster event workshop untuk UMKM, visual ruangan kreatif dengan peserta aktif, suasana edukatif dan energik, warna profesional, komposisi jelas, ruang untuk judul acara, narasumber, tanggal, dan CTA daftar.',
      ),
      _PromptSuggestion(
        title: 'Seasonal Event',
        prompt:
            'Visual event musiman dengan dekorasi meriah, suasana hangat dan ramai, elemen festive sesuai tema, warna cerah namun tetap rapi, cocok untuk story Instagram dan feed promosi event.',
      ),
    ],
    'Thumbnail Video': [
      _PromptSuggestion(
        title: 'Tutorial Produk',
        prompt:
            'Thumbnail video tutorial produk, produk besar di foreground, ekspresi manusia penasaran atau antusias, background high contrast, elemen panah dan shape dinamis tanpa teks terbaca, sangat clickable dan jelas saat ukuran kecil.',
      ),
      _PromptSuggestion(
        title: 'Review Jujur',
        prompt:
            'Thumbnail video review produk, close-up produk dengan lighting dramatis, ekspresi surprised, split composition, warna kuning dan merah sebagai aksen urgency, visual tajam dan menarik perhatian.',
      ),
      _PromptSuggestion(
        title: 'Tips Bisnis',
        prompt:
            'Thumbnail video tips bisnis UMKM, meja kerja modern, grafik naik secara visual, laptop dan produk bisnis, komposisi bold, kontras tinggi, ruang untuk headline besar di sisi kanan.',
      ),
    ],
    'Cover Highlight': [
      _PromptSuggestion(
        title: 'Ikon Produk',
        prompt:
            'Cover highlight Instagram minimalis dengan ikon produk utama, background warna brand solid atau gradasi lembut, bentuk sederhana, center composition, clean, mudah dikenali dalam ukuran kecil.',
      ),
      _PromptSuggestion(
        title: 'Kategori Menu',
        prompt:
            'Cover highlight kategori menu, ikon makanan atau minuman bergaya flat design, warna pastel konsisten, bentuk bulat, visual clean dan branded untuk profil Instagram UMKM.',
      ),
      _PromptSuggestion(
        title: 'FAQ / Info',
        prompt:
            'Cover highlight FAQ atau informasi toko, ikon chat bubble dan sparkle sederhana, background clean, warna brand, gaya modern minimalis, mudah dibaca dan konsisten dengan identitas brand.',
      ),
    ],
  };

  bool _isLoading = false;
  String _loadingMessage = '';
  String _loadingSubtitle = '';
  int _loadingStep = 0;
  String? _resultImageUrl;
  String _enhancedPrompt = '';
  String _imageProvider = '';
  bool _isPromptExpanded = false; // Toggle expand prompt textarea

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creditServiceProvider).fetchCredits();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  List<String> get _availableMoods {
    if (_selectedPurpose == null) return _moods;
    return _moodRecommendations[_selectedPurpose] ?? _moods;
  }

  List<String> get _availableTypes {
    if (_selectedPurpose == null) return _types;
    return _sizeRecommendations[_selectedPurpose] ?? _types;
  }

  List<String> get _availableColors {
    if (_selectedPurpose == null) return _colors;
    return _colorRecommendations[_selectedPurpose] ?? _colors;
  }

  List<_PromptSuggestion> get _availablePromptSuggestions {
    if (_selectedPurpose == null) {
      return _promptSuggestions['Produk Showcase'] ?? const [];
    }
    return _promptSuggestions[_selectedPurpose] ?? const [];
  }

  void _applyPromptSuggestion(_PromptSuggestion suggestion) {
    _promptController.text = suggestion.prompt;
    _promptController.selection = TextSelection.fromPosition(
      TextPosition(offset: _promptController.text.length),
    );
    setState(() => _isPromptExpanded = true);
  }

  // Auto-switch mood ke rekomendasi terbaik saat purpose berubah
  void _onPurposeChanged(String? newPurpose) {
    if (newPurpose == null) return;
    final recommended = _moodRecommendations[newPurpose];
    if (recommended != null && recommended.isNotEmpty) {
      final bestMood = recommended.first;
      final recommendedSizes = _sizeRecommendations[newPurpose] ?? _types;
      final recommendedColors = _colorRecommendations[newPurpose] ?? _colors;
      setState(() {
        _selectedPurpose = newPurpose;
        if (!recommended.contains(_selectedMood)) {
          _selectedMood = bestMood;
        }
        if (!recommendedSizes.contains(_selectedType)) {
          _selectedType = recommendedSizes.first;
        }
        if (!recommendedColors.contains(_selectedColor)) {
          _selectedColor = recommendedColors.first;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Style "$bestMood" direkomendasikan untuk $newPurpose',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ]),
              backgroundColor: const Color(0xFF7C4DFF),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    } else {
      setState(() => _selectedPurpose = newPurpose);
    }
  }

  bool _isMoodRecommended(String mood) {
    if (_selectedPurpose == null) return false;
    return _moodRecommendations[_selectedPurpose]?.contains(mood) ?? false;
  }

  bool _isSizeRecommended(String size) {
    if (_selectedPurpose == null) return false;
    return _sizeRecommendations[_selectedPurpose]?.contains(size) ?? false;
  }

  String get _purposeHint {
    if (_selectedPurpose == null)
      return 'Misal: Kopi latte hangat di meja kayu, suasana pagi yang cozy...';
    return _purposeHints[_selectedPurpose] ??
        'Deskripsikan gambar yang ingin kamu buat secara detail...';
  }

  String get _aspectRatio {
    if (_selectedType.contains('16:9')) return '16:9';
    if (_selectedType.contains('9:16')) return '9:16';
    if (_selectedType.contains('3:4')) return '3:4';
    if (_selectedType.contains('21:9')) return '21:9';
    return '1:1';
  }

  Widget _buildPromptSuggestions() {
    final suggestions = _availablePromptSuggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFC107).withOpacity(0.28),
                ),
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFFFFC107),
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rekomendasi Prompt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Tap contoh untuk mengisi deskripsi, lalu edit sesuai produkmu.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 114,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return GestureDetector(
                onTap: () => _applyPromptSuggestion(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 236,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.09),
                        const Color(0xFFE91E63).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63).withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Contoh ${index + 1}',
                              style: const TextStyle(
                                color: Color(0xFFFF80AB),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.touch_app_rounded,
                            color: Color(0xFFFF80AB),
                            size: 13,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Text(
                          item.prompt,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.48),
                            fontSize: 10,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _generate() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Jelaskan desain yang kamu inginkan'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final canProceed = await showCreditGuard(context, CreditType.image, ref);
    if (!canProceed || !mounted) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Menyiapkan brief visual...';
      _loadingSubtitle = 'Backend AI akan memperkaya prompt dengan aman';
      _loadingStep = 0;
      _resultImageUrl = null;
      _enhancedPrompt = '';
      _imageProvider = '';
    });

    await ref.read(creditServiceProvider).useCredit(CreditType.image);

    try {
      final authState = ref.read(authStateProvider);
      final profile = authState.asData?.value ??
          UserProfile(
              uid: 'guest',
              email: '',
              businessName: 'UMKM Demo',
              businessType: 'Umum');

      final colorHint =
          _selectedColor != 'Auto' ? ' Palet warna: $_selectedColor.' : '';
      final promptBrief = '${_promptController.text.trim()}$colorHint';

      if (mounted)
        setState(() {
          _loadingMessage = 'Mengirim brief ke backend...';
          _loadingSubtitle =
              'Gemini prompt enhancer + image provider berjalan di server';
          _loadingStep = 1;
        });

      final service = ref.read(stabilityAiServiceProvider);

      if (mounted)
        setState(() {
          _loadingMessage = 'Generating gambar...';
          _loadingSubtitle = 'NVIDIA FLUX / X5Lab / Pollinations fallback';
          _loadingStep = 2;
        });

      final result = await service.generateImageResult(
        prompt: promptBrief,
        aspectRatio: _aspectRatio,
        stylePreset: _selectedMood,
        purpose: _selectedPurpose ?? '',
        businessName: profile.businessName,
        businessType: profile.businessType,
        enhancePrompt: true,
      );

      if (mounted) {
        setState(() {
          _resultImageUrl = result.url;
          _imageProvider = result.provider;
          _enhancedPrompt =
              result.promptUsed.isNotEmpty ? result.promptUsed : promptBrief;
          _loadingStep = 0;
          _loadingSubtitle = ''; // reset
        });
      }
    } catch (e) {
      if (!mounted) return;
      String errMsg = e.toString().replaceFirst('Exception: ', '');

      if (errMsg.contains('401') && errMsg.contains('Auth')) {
        errMsg = 'Sesi habis. Silakan logout lalu login kembali.';
      } else if (errMsg.contains('SocketException') ||
          errMsg.contains('Connection refused') ||
          errMsg.contains('tidak dapat dihubungi')) {
        errMsg = 'Backend tidak berjalan. Jalankan: cd backend && npm start';
      } else if (errMsg.contains('503') || errMsg.contains('provider')) {
        errMsg = 'Semua AI provider sedang sibuk. Coba lagi dalam 1 menit.';
      } else if (errMsg.contains('TimeoutException') ||
          errMsg.contains('timeout')) {
        errMsg = 'Request timeout. Koneksi lambat, coba lagi.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg, style: const TextStyle(fontSize: 12)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade900,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
          _loadingStep = 0;
          _loadingSubtitle = '';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(slivers: [
        // ── HEADER ──────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 180,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.surfaceDark,
          actions: [
            CreditBadge(
                type: CreditType.image, accentColor: const Color(0xFFE91E63)),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Studio Desain AI',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            background: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/banner_ai_image.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight)),
                        child: const Center(
                            child: Icon(Icons.palette_rounded,
                                size: 60, color: Colors.white24)),
                      )),
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Colors.transparent,
                    AppColors.surfaceDark
                  ]))),
            ]),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── INFO BANNER ──────────────────────────────────
              GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFFF5722)]),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.palette_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AI generate gambar sesuai tujuan visual kamu secara otomatis!',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                  // NVIDIA badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF76B900).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFF76B900).withOpacity(0.5)),
                    ),
                    child: const Text('NVIDIA',
                        style: TextStyle(
                            color: Color(0xFF76B900),
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // ── KONSEP VISUAL ────────────────────────────────
              _sectionTitle('🖼️ Konsep Visual'),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassDropdown<String>(
                        label: 'Tujuan Visual',
                        value: _selectedPurpose,
                        onChanged: _onPurposeChanged,
                        items: _purposes
                            .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      _buildPromptSuggestions(),
                      const SizedBox(height: 14),
                      // ── Expandable Prompt Input ──────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('Deskripsi Visual',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _isPromptExpanded = !_isPromptExpanded),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFE91E63).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: const Color(0xFFE91E63)
                                          .withOpacity(0.3)),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isPromptExpanded
                                            ? Icons.compress_rounded
                                            : Icons.expand_rounded,
                                        size: 11,
                                        color: const Color(0xFFE91E63),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                          _isPromptExpanded
                                              ? 'Ringkas'
                                              : 'Perluas',
                                          style: const TextStyle(
                                              color: Color(0xFFE91E63),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ]),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: TextField(
                              controller: _promptController,
                              maxLines: _isPromptExpanded ? null : 4,
                              minLines: _isPromptExpanded ? 8 : 4,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.5),
                              decoration: InputDecoration(
                                hintText: _purposeHint,
                                hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.25),
                                    fontSize: 12),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE91E63), width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                          ),
                          if (_isPromptExpanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                  '💡 Makin detail deskripsimu, makin akurat hasilnya',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 10)),
                            ),
                        ],
                      ),
                    ]),
              ),
              const SizedBox(height: 20),

              // ── FORMAT & GAYA ────────────────────────────────
              _sectionTitle('🎨 Format & Gaya'),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Smart Size Selector ──────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('Ukuran / Rasio',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5)),
                            if (_selectedPurpose != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF00BCD4).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: const Color(0xFF00BCD4)
                                          .withOpacity(0.4)),
                                ),
                                child: const Text('✦ = Cocok untuk tujuanmu',
                                    style: TextStyle(
                                        color: Color(0xFF00BCD4),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableTypes.map((size) {
                              final isSelected = _selectedType == size;
                              final isRec = _isSizeRecommended(size);
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedType = size),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(colors: [
                                            Color(0xFF3D5AFE),
                                            Color(0xFF7C4DFF)
                                          ])
                                        : null,
                                    color: isSelected
                                        ? null
                                        : isRec
                                            ? const Color(0xFF00BCD4)
                                                .withOpacity(0.1)
                                            : Colors.white.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : isRec
                                              ? const Color(0xFF00BCD4)
                                                  .withOpacity(0.5)
                                              : Colors.white.withOpacity(0.12),
                                      width: isRec ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isRec && !isSelected)
                                          const Text('✦ ',
                                              style: TextStyle(
                                                  color: Color(0xFF00BCD4),
                                                  fontSize: 9)),
                                        Text(size,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : isRec
                                                      ? const Color(0xFF80DEEA)
                                                      : Colors.white60,
                                              fontSize: 12,
                                              fontWeight: isSelected || isRec
                                                  ? FontWeight.w700
                                                  : FontWeight.normal,
                                            )),
                                      ]),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // ── Smart Mood Selector ──────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('Mood & Style',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5)),
                            if (_selectedPurpose != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF7C4DFF).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: const Color(0xFF7C4DFF)
                                          .withOpacity(0.4)),
                                ),
                                child: const Text('⭐ = Direkomendasikan',
                                    style: TextStyle(
                                        color: Color(0xFF7C4DFF),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableMoods.map((mood) {
                              final isSelected = _selectedMood == mood;
                              final isRecommended = _isMoodRecommended(mood);
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedMood = mood),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(colors: [
                                            Color(0xFFE91E63),
                                            Color(0xFFFF5722)
                                          ])
                                        : null,
                                    color: isSelected
                                        ? null
                                        : isRecommended
                                            ? const Color(0xFF7C4DFF)
                                                .withOpacity(0.15)
                                            : Colors.white.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : isRecommended
                                              ? const Color(0xFF7C4DFF)
                                                  .withOpacity(0.6)
                                              : Colors.white.withOpacity(0.12),
                                      width: isRecommended ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isRecommended && !isSelected)
                                          const Text('⭐ ',
                                              style: TextStyle(fontSize: 9)),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(mood,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : isRecommended
                                                          ? const Color(
                                                              0xFFB39DDB)
                                                          : Colors.white60,
                                                  fontSize: 12,
                                                  fontWeight: isSelected ||
                                                          isRecommended
                                                      ? FontWeight.w700
                                                      : FontWeight.normal,
                                                )),
                                            if (_styleDescriptions[mood] !=
                                                null)
                                              Text(_styleDescriptions[mood]!,
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(isSelected
                                                            ? 0.7
                                                            : 0.35),
                                                    fontSize: 9,
                                                  )),
                                          ],
                                        ),
                                      ]),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GlassChipGroup(
                          label: 'Palet Warna',
                          options: _availableColors,
                          selected: _selectedColor,
                          onSelected: (v) =>
                              setState(() => _selectedColor = v)),
                    ]),
              ),
              const SizedBox(height: 24),

              // ── GENERATE BUTTON ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF5722)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFE91E63).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generate,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: Text(
                        _isLoading ? 'Generating...' : 'Generate Desain ✨',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── LOADING ──────────────────────────────────────
              if (_isLoading)
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: spinner + pesan utama
                        Row(children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: const Color(0xFF76B900),
                              strokeWidth: 2.5,
                              backgroundColor:
                                  const Color(0xFF76B900).withOpacity(0.15),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_loadingMessage,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(_loadingSubtitle,
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 10)),
                                ]),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        // Step progress indicator
                        _buildLoadingSteps(),
                      ]),
                ),

              // ── RESULT ───────────────────────────────────────
              if (_resultImageUrl != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    _sectionTitle('🖼️ Hasil Desain'),
                    const Spacer(),
                    if (_imageProvider.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF76B900).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF76B900).withOpacity(0.4)),
                        ),
                        child: Text(
                          _imageProvider,
                          style: const TextStyle(
                            color: Color(0xFF76B900),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AiImageResultCard(
                  key: ValueKey(
                      _resultImageUrl), // Force rebuild saat URL berubah
                  imageUrl: _resultImageUrl!,
                  prompt: _enhancedPrompt,
                  onRegenerate: _isLoading ? null : _generate,
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  /// Step progress indicator — 3 tahap pipeline AI
  Widget _buildLoadingSteps() {
    const steps = [
      _AiStep(
          icon: '✨',
          label: 'Gemini',
          sublabel: 'Enhance Prompt',
          provider: 'gemini'),
      _AiStep(
          icon: '🚀',
          label: 'Kirim ke AI',
          sublabel: 'NVIDIA / X5Lab',
          provider: 'send'),
      _AiStep(
          icon: '🖼️',
          label: 'Generate',
          sublabel: '30–90 detik',
          provider: 'image'),
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line antara step
          final stepIdx = i ~/ 2;
          final isDone = _loadingStep > stepIdx;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF76B900).withOpacity(0.6)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step = steps[stepIdx];
        final isActive = _loadingStep == stepIdx;
        final isDone = _loadingStep > stepIdx;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF76B900).withOpacity(0.2)
                    : isActive
                        ? const Color(0xFFE91E63).withOpacity(0.2)
                        : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDone
                      ? const Color(0xFF76B900).withOpacity(0.5)
                      : isActive
                          ? const Color(0xFFE91E63).withOpacity(0.5)
                          : Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Color(0xFF76B900), size: 16)
                    : Text(step.icon, style: const TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(height: 5),
            Text(step.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      isActive || isDone ? FontWeight.bold : FontWeight.normal,
                  color: isDone
                      ? const Color(0xFF76B900)
                      : isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                )),
            Text(step.sublabel,
                style: TextStyle(
                    fontSize: 8, color: Colors.white.withOpacity(0.2))),
          ],
        );
      }),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white));
}

// ── Helper class untuk step data ─────────────────────────
class _AiStep {
  final String icon;
  final String label;
  final String sublabel;
  final String provider;
  const _AiStep(
      {required this.icon,
      required this.label,
      required this.sublabel,
      required this.provider});
}

class _PromptSuggestion {
  final String title;
  final String prompt;

  const _PromptSuggestion({
    required this.title,
    required this.prompt,
  });
}
