import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_text_service.dart';
import '../../services/auth_service.dart';
import '../../services/credit_service.dart';
import '../../services/gemini_service.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_form_field.dart';
import '../../widgets/ai_result_card.dart';
import '../../widgets/credit_widgets.dart';

class _CaptionBriefSuggestion {
  final String title;
  final String brief;
  final String hashtags;
  final String? platform;
  final String? tone;
  final String? length;

  const _CaptionBriefSuggestion({
    required this.title,
    required this.brief,
    required this.hashtags,
    this.platform,
    this.tone,
    this.length,
  });
}

class AiTextScreen extends ConsumerStatefulWidget {
  const AiTextScreen({super.key});
  @override
  ConsumerState<AiTextScreen> createState() => _AiTextScreenState();
}

class _AiTextScreenState extends ConsumerState<AiTextScreen> {
  final _productController = TextEditingController();
  final _hashtagController = TextEditingController();

  String? _selectedPurpose;
  final _purposes = [
    'Promo Diskon',
    'Launching Produk',
    'Edukasi',
    'Testimoni',
    'Reminder',
    'Hiburan',
    'Giveaway',
    'Behind the Scenes',
    'Tips & Trik',
    'Seasonal / Hari Besar'
  ];

  String? _selectedPlatform;
  final _platforms = [
    'Instagram Feed',
    'Instagram Story',
    'Instagram Reels',
    'TikTok',
    'WhatsApp Status',
    'Facebook',
    'Twitter/X',
    'Threads'
  ];

  String _selectedTone = 'Santai';
  final _tones = [
    'Formal',
    'Santai',
    'Gen Z',
    'Premium',
    "Syar'i",
    'Lucu',
    'Inspiratif',
    'Storytelling',
    'Persuasif'
  ];

  String _selectedLength = 'Sedang';
  final _lengths = ['Pendek', 'Sedang', 'Panjang'];

  String _selectedLanguage = 'Indonesia';
  final _languages = ['Indonesia', 'Inggris', 'Mix (ID+EN)', 'Sunda', 'Jawa'];

  final Map<String, String> _toneDescriptions = const {
    'Formal': 'Rapi, profesional, cocok untuk info resmi.',
    'Santai': 'Ramah, natural, mudah terasa dekat.',
    'Gen Z': 'Ringan, cepat, cocok untuk Reels/TikTok.',
    'Premium': 'Elegan, eksklusif, fokus value produk.',
    "Syar'i": 'Sopan, hangat, cocok untuk momen Islami.',
    'Lucu': 'Humor ringan untuk engagement.',
    'Inspiratif': 'Membangun trust dan emosi positif.',
    'Storytelling': 'Bercerita, kuat untuk brand story.',
    'Persuasif': 'Mendorong aksi tanpa terasa memaksa.',
  };

  final Map<String, String> _lengthDescriptions = const {
    'Pendek': '1-2 kalimat, cepat dibaca.',
    'Sedang': 'Seimbang untuk benefit dan CTA.',
    'Panjang': 'Lebih detail, cocok untuk edukasi/story.',
  };

  final Map<String, String> _languageDescriptions = const {
    'Indonesia': 'Bahasa utama audiens lokal.',
    'Inggris': 'Lebih global dan ringkas.',
    'Mix (ID+EN)': 'Kasual, modern, tetap mudah dipahami.',
    'Sunda': 'Lebih dekat untuk audiens lokal Sunda.',
    'Jawa': 'Lebih akrab untuk audiens lokal Jawa.',
  };

  final Map<String, List<String>> _hashtagRecommendations = const {
    'Promo Diskon': [
      '#promo #diskon #flashsale',
      '#hemat #belanjaonline #umkm',
      '#lastchance #stokterbatas #checkoutsekarang',
    ],
    'Launching Produk': [
      '#produkbaru #launching #newarrival',
      '#comingsoon #teaserproduk #firstlook',
      '#firstorder #bonusspesial #umkmindonesia',
    ],
    'Edukasi': [
      '#edukasi #tipsproduk #infopenting',
      '#mythvsfact #tipsbelanja #savepost',
      '#carapakai #edukasiumkm #tipspraktis',
    ],
    'Testimoni': [
      '#testimoni #reviewjujur #pelangganpuas',
      '#bintang5 #trusted #repeatorder',
      '#socialproof #ceritapelanggan #reviewproduk',
    ],
    'Reminder': [
      '#reminder #openorder #lastorder',
      '#infopengiriman #readyhariini #stokterbatas',
      '#janganlewatkan #updatebisnis #ceksekarang',
    ],
    'Hiburan': [
      '#relatable #kontenlucu #seruseruan',
      '#polling #pilihfavoritmu #dailyhumor',
      '#funfact #kontenringan #brandstory',
    ],
    'Giveaway': [
      '#giveaway #giveawayindonesia #gratis',
      '#tagtemanmu #countdowngiveaway #lastchance',
      '#pengumumanpemenang #akunresmi #hadiahgratis',
    ],
    'Behind the Scenes': [
      '#behindthescenes #prosesproduksi #smallbusiness',
      '#packingorder #ceritaumkm #handmade',
      '#meettheteam #brandvalues #terimakasih',
    ],
    'Tips & Trik': [
      '#tipspraktis #tipsdantrik #savepost',
      '#checklist #tipsbelanja #konsultasigratis',
      '#lifehack #tipscepat #praktis',
    ],
    'Seasonal / Hari Besar': [
      '#haribesar #spesialhariini #promoakhirpekan',
      '#hampers #ramadan #lebaran',
      '#payday #selfreward #belanjahemat',
    ],
  };

  final Map<String, List<String>> _platformRecommendations = const {
    'Promo Diskon': [
      'Instagram Story',
      'WhatsApp Status',
      'Instagram Feed',
      'Facebook',
    ],
    'Launching Produk': [
      'Instagram Reels',
      'TikTok',
      'Instagram Feed',
      'Threads',
    ],
    'Edukasi': ['Instagram Feed', 'Threads', 'Facebook', 'TikTok'],
    'Testimoni': ['Instagram Feed', 'Instagram Story', 'WhatsApp Status'],
    'Reminder': ['WhatsApp Status', 'Instagram Story', 'Facebook'],
    'Hiburan': ['TikTok', 'Instagram Reels', 'Threads'],
    'Giveaway': ['Instagram Feed', 'Instagram Story', 'TikTok'],
    'Behind the Scenes': ['Instagram Reels', 'TikTok', 'Instagram Story'],
    'Tips & Trik': ['Instagram Feed', 'TikTok', 'Threads'],
    'Seasonal / Hari Besar': [
      'Instagram Feed',
      'WhatsApp Status',
      'Facebook',
    ],
  };

  final Map<String, List<String>> _toneRecommendations = const {
    'Promo Diskon': ['Persuasif', 'Santai', 'Gen Z'],
    'Launching Produk': ['Storytelling', 'Premium', 'Persuasif'],
    'Edukasi': ['Inspiratif', 'Santai', 'Formal'],
    'Testimoni': ['Storytelling', 'Inspiratif', 'Santai'],
    'Reminder': ['Persuasif', 'Santai', 'Formal'],
    'Hiburan': ['Lucu', 'Gen Z', 'Santai'],
    'Giveaway': ['Gen Z', 'Santai', 'Persuasif'],
    'Behind the Scenes': ['Storytelling', 'Santai', 'Inspiratif'],
    'Tips & Trik': ['Santai', 'Inspiratif', 'Formal'],
    'Seasonal / Hari Besar': ['Inspiratif', 'Premium', "Syar'i"],
  };

  final Map<String, List<String>> _lengthRecommendations = const {
    'Promo Diskon': ['Pendek', 'Sedang'],
    'Launching Produk': ['Sedang', 'Panjang'],
    'Edukasi': ['Panjang', 'Sedang'],
    'Testimoni': ['Sedang', 'Panjang'],
    'Reminder': ['Pendek', 'Sedang'],
    'Hiburan': ['Pendek', 'Sedang'],
    'Giveaway': ['Sedang', 'Pendek'],
    'Behind the Scenes': ['Sedang', 'Panjang'],
    'Tips & Trik': ['Sedang', 'Panjang'],
    'Seasonal / Hari Besar': ['Sedang', 'Pendek'],
  };

  final Map<String, List<_CaptionBriefSuggestion>> _briefSuggestions = const {
    'Promo Diskon': [
      _CaptionBriefSuggestion(
        title: 'Flash Sale 24 Jam',
        brief:
            'Promo diskon 25% untuk produk best seller. Tekankan stok terbatas, berlaku hari ini saja, dan ajak user checkout sekarang.',
        hashtags: '#flashsale #promo #diskon #umkm',
        platform: 'Instagram Story',
        tone: 'Persuasif',
        length: 'Pendek',
      ),
      _CaptionBriefSuggestion(
        title: 'Bundle Hemat',
        brief:
            'Paket bundling 3 produk lebih hemat untuk pelanggan baru. Jelaskan benefit praktis, cocok untuk hadiah, dan ada bonus kecil.',
        hashtags: '#bundlehemat #promohemat #belanjaonline',
        platform: 'Instagram Feed',
        tone: 'Santai',
        length: 'Sedang',
      ),
      _CaptionBriefSuggestion(
        title: 'Last Call Promo',
        brief:
            'Pengingat promo akan berakhir malam ini. Buat caption urgent tapi tetap ramah, sertakan alasan kenapa pelanggan jangan menunda.',
        hashtags: '#lastcall #promoberakhir #janganlewatkan',
        platform: 'WhatsApp Status',
        tone: 'Persuasif',
        length: 'Pendek',
      ),
    ],
    'Launching Produk': [
      _CaptionBriefSuggestion(
        title: 'Soft Launch',
        brief:
            'Perkenalkan produk baru yang dibuat dari masukan pelanggan. Ceritakan masalah yang diselesaikan dan ajak orang pertama mencoba.',
        hashtags: '#produkbaru #launching #umkmindonesia',
        platform: 'Instagram Feed',
        tone: 'Storytelling',
        length: 'Sedang',
      ),
      _CaptionBriefSuggestion(
        title: 'Teaser Reels',
        brief:
            'Caption pendek untuk video teaser produk baru. Bangun rasa penasaran, sebutkan tanggal rilis, dan minta audiens menyalakan reminder.',
        hashtags: '#comingsoon #teaserproduk #newarrival',
        platform: 'Instagram Reels',
        tone: 'Gen Z',
        length: 'Pendek',
      ),
      _CaptionBriefSuggestion(
        title: 'First Order Bonus',
        brief:
            'Produk baru sudah tersedia dengan bonus khusus untuk 30 pembeli pertama. Tonjolkan value, kualitas, dan cara order yang mudah.',
        hashtags: '#firstorder #launchingproduk #bonusspesial',
        platform: 'TikTok',
        tone: 'Persuasif',
        length: 'Sedang',
      ),
    ],
    'Edukasi': [
      _CaptionBriefSuggestion(
        title: 'Myth vs Fact',
        brief:
            'Bongkar 3 mitos umum tentang produk atau kategori bisnis. Gunakan bahasa sederhana dan tutup dengan tips memilih produk yang tepat.',
        hashtags: '#edukasi #mythvsfact #tipsbelanja',
        platform: 'Instagram Feed',
        tone: 'Santai',
        length: 'Panjang',
      ),
      _CaptionBriefSuggestion(
        title: 'Cara Pakai',
        brief:
            'Jelaskan langkah memakai produk agar hasilnya maksimal. Buat format mudah dipindai dan tambahkan ajakan untuk simpan postingan.',
        hashtags: '#carapakai #tipsproduk #edukasiumkm',
        platform: 'Threads',
        tone: 'Formal',
        length: 'Sedang',
      ),
      _CaptionBriefSuggestion(
        title: 'Problem-Solution',
        brief:
            'Mulai dari masalah pelanggan yang sering terjadi, lalu jelaskan solusi praktis dari produk. Buat terasa membantu, bukan sekadar jualan.',
        hashtags: '#solusipraktis #edukasibisnis #tipsumkm',
        platform: 'TikTok',
        tone: 'Inspiratif',
        length: 'Sedang',
      ),
    ],
    'Testimoni': [
      _CaptionBriefSuggestion(
        title: 'Cerita Pelanggan',
        brief:
            'Ubah testimoni pelanggan menjadi cerita before-after. Tampilkan masalah awal, pengalaman memakai produk, dan hasil yang dirasakan.',
        hashtags: '#testimoni #reviewjujur #ceritapelanggan',
        platform: 'Instagram Feed',
        tone: 'Storytelling',
        length: 'Sedang',
      ),
      _CaptionBriefSuggestion(
        title: 'Review Marketplace',
        brief:
            'Caption untuk screenshot review bintang 5. Beri apresiasi ke pelanggan dan ajak calon pembeli bertanya sebelum checkout.',
        hashtags: '#reviewpelanggan #bintang5 #trusted',
        platform: 'Instagram Story',
        tone: 'Santai',
        length: 'Pendek',
      ),
      _CaptionBriefSuggestion(
        title: 'Social Proof',
        brief:
            'Tunjukkan bahwa produk sudah dipercaya banyak pelanggan. Gunakan angka, repeat order, atau feedback singkat tanpa terasa berlebihan.',
        hashtags: '#socialproof #pelangganpuas #repeatorder',
        platform: 'WhatsApp Status',
        tone: 'Persuasif',
        length: 'Sedang',
      ),
    ],
    'Reminder': [
      _CaptionBriefSuggestion(
        title: 'Deadline Order',
        brief:
            'Ingatkan batas order hari ini sebelum pengiriman besok. Buat jelas, ringkas, dan sertakan format order yang harus dikirim pelanggan.',
        hashtags: '#reminderorder #lastorder #infopengiriman',
        platform: 'WhatsApp Status',
        tone: 'Formal',
        length: 'Pendek',
      ),
      _CaptionBriefSuggestion(
        title: 'Stok Terbatas',
        brief:
            'Pengingat stok varian favorit tinggal sedikit. Dorong audiens cek ketersediaan dan booking sebelum habis.',
        hashtags: '#stokterbatas #readyhariini #cepatcheckout',
        platform: 'Instagram Story',
        tone: 'Persuasif',
        length: 'Pendek',
      ),
      _CaptionBriefSuggestion(
        title: 'Jadwal Buka',
        brief:
            'Umumkan jam operasional, jadwal pre-order, atau perubahan layanan minggu ini dengan nada ramah dan informatif.',
        hashtags: '#infojadwal #openorder #updatebisnis',
        platform: 'Facebook',
        tone: 'Santai',
        length: 'Sedang',
      ),
    ],
    'Hiburan': [
      _CaptionBriefSuggestion(
        title: 'Relatable Problem',
        brief:
            'Buat caption lucu tentang kebiasaan pelanggan yang relatable dengan produk. Akhiri dengan punchline ringan dan CTA komentar.',
        hashtags: '#relatable #kontenlucu #dailyhumor',
        platform: 'TikTok',
        tone: 'Lucu',
        length: 'Pendek',
      ),
      _CaptionBriefSuggestion(
        title: 'Polling Seru',
        brief:
            'Ajak audiens memilih varian favorit dengan pertanyaan ringan. Buat pilihan A/B dan dorong mereka jawab di komentar.',
        hashtags: '#polling #pilihfavoritmu #seruseruan',
        platform: 'Instagram Story',
        tone: 'Gen Z',
        length: 'Pendek',
      ),
      _CaptionBriefSuggestion(
        title: 'Fun Fact Brand',
        brief:
            'Bagikan fakta unik tentang produk atau proses bisnis. Buat ringan, mengejutkan, dan tetap nyambung ke brand.',
        hashtags: '#funfact #brandstory #kontenringan',
        platform: 'Threads',
        tone: 'Santai',
        length: 'Sedang',
      ),
    ],
    'Giveaway': [
      _CaptionBriefSuggestion(
        title: 'Rules Giveaway',
        brief:
            'Umumkan giveaway dengan hadiah, syarat ikut, deadline, dan tanggal pengumuman. Buat aturan jelas supaya tidak membingungkan.',
        hashtags: '#giveaway #giveawayindonesia #gratis',
        platform: 'Instagram Feed',
        tone: 'Santai',
        length: 'Sedang',
      ),
      _CaptionBriefSuggestion(
        title: 'Countdown',
        brief:
            'Caption countdown 2 hari sebelum giveaway ditutup. Ingatkan cara ikut dan dorong audiens tag teman yang belum ikutan.',
        hashtags: '#countdowngiveaway #lastchance #tagtemanmu',
        platform: 'Instagram Story',
        tone: 'Gen Z',
        length: 'Pendek',
      ),
      _CaptionBriefSuggestion(
        title: 'Winner Reminder',
        brief:
            'Pengingat pengumuman pemenang giveaway malam ini. Buat antusias, sopan, dan tekankan hanya akun resmi yang akan menghubungi.',
        hashtags: '#pengumumanpemenang #giveawaywinner #akunresmi',
        platform: 'TikTok',
        tone: 'Persuasif',
        length: 'Sedang',
      ),
    ],
    'Behind the Scenes': [
      _CaptionBriefSuggestion(
        title: 'Proses Produksi',
        brief:
            'Ceritakan proses pembuatan produk dari awal sampai siap kirim. Tekankan detail, ketelitian, dan rasa bangga pada kualitas.',
        hashtags: '#behindthescenes #prosesproduksi #handmade',
        platform: 'Instagram Reels',
        tone: 'Storytelling',
        length: 'Sedang',
      ),
      _CaptionBriefSuggestion(
        title: 'Packing Order',
        brief:
            'Caption untuk video packing pesanan pelanggan. Buat hangat, personal, dan ucapkan terima kasih atas dukungan mereka.',
        hashtags: '#packingorder #smallbusiness #terimakasih',
        platform: 'TikTok',
        tone: 'Santai',
        length: 'Pendek',
      ),
      _CaptionBriefSuggestion(
        title: 'Meet the Team',
        brief:
            'Perkenalkan orang di balik bisnis. Ceritakan peran mereka, nilai brand, dan kenapa pelanggan bisa percaya pada prosesnya.',
        hashtags: '#meettheteam #ceritaumkm #brandvalues',
        platform: 'Instagram Feed',
        tone: 'Inspiratif',
        length: 'Panjang',
      ),
    ],
    'Tips & Trik': [
      _CaptionBriefSuggestion(
        title: '3 Tips Cepat',
        brief:
            'Buat 3 tips singkat yang membantu pelanggan memakai atau memilih produk. Format harus mudah disimpan dan dibagikan.',
        hashtags: '#tipspraktis #tipsdantrik #savepost',
        platform: 'Instagram Feed',
        tone: 'Santai',
        length: 'Sedang',
      ),
      _CaptionBriefSuggestion(
        title: 'Checklist',
        brief:
            'Buat checklist sebelum membeli produk agar pelanggan tidak salah pilih. Akhiri dengan ajakan konsultasi lewat DM.',
        hashtags: '#checklist #tipsbelanja #konsultasigratis',
        platform: 'Threads',
        tone: 'Formal',
        length: 'Panjang',
      ),
      _CaptionBriefSuggestion(
        title: 'Hack Harian',
        brief:
            'Bagikan hack sederhana yang membuat rutinitas pelanggan lebih mudah menggunakan produk. Buat cepat, praktis, dan friendly.',
        hashtags: '#lifehack #tipscepat #praktis',
        platform: 'TikTok',
        tone: 'Gen Z',
        length: 'Pendek',
      ),
    ],
    'Seasonal / Hari Besar': [
      _CaptionBriefSuggestion(
        title: 'Ucapan + Promo',
        brief:
            'Caption momen hari besar yang menggabungkan ucapan hangat dan promo terbatas. Jaga tetap sopan, relevan, dan tidak terlalu hard-sell.',
        hashtags: '#haribesar #promoakhirpekan #spesialhariini',
        platform: 'Instagram Feed',
        tone: 'Inspiratif',
        length: 'Sedang',
      ),
      _CaptionBriefSuggestion(
        title: 'Ramadan/Hari Raya',
        brief:
            'Caption untuk penawaran hampers atau produk spesial Ramadan/Hari Raya. Tonjolkan makna berbagi, kualitas, dan batas pemesanan.',
        hashtags: '#hampers #ramadan #lebaran',
        platform: 'WhatsApp Status',
        tone: "Syar'i",
        length: 'Sedang',
      ),
      _CaptionBriefSuggestion(
        title: 'Payday Campaign',
        brief:
            'Caption campaign payday dengan tone ceria. Tekankan self-reward yang tetap hemat dan ajak pelanggan pilih varian favorit.',
        hashtags: '#payday #selfreward #belanjahemat',
        platform: 'Instagram Story',
        tone: 'Gen Z',
        length: 'Pendek',
      ),
    ],
  };

  bool _useEmoji = true;
  bool _useCTA = true;
  bool _isLoading = false;
  List<String> _results = [];

  List<String> get _availablePlatforms => _selectedPurpose == null
      ? _platforms
      : _platformRecommendations[_selectedPurpose] ?? _platforms;

  List<String> get _availableTones => _selectedPurpose == null
      ? _tones
      : _toneRecommendations[_selectedPurpose] ?? _tones;

  List<String> get _availableLengths => _selectedPurpose == null
      ? _lengths
      : _lengthRecommendations[_selectedPurpose] ?? _lengths;

  List<_CaptionBriefSuggestion> get _availableBriefSuggestions =>
      _selectedPurpose == null
          ? const []
          : _briefSuggestions[_selectedPurpose] ?? const [];

  List<String> get _availableHashtagPresets => _selectedPurpose == null
      ? const [
          '#umkm #jualanonline #produklokal',
          '#promo #belanjaonline #trusted',
          '#bisnislokal #supportumkm #indonesia',
        ]
      : _hashtagRecommendations[_selectedPurpose] ??
          const ['#umkm #jualanonline #produklokal'];

  String get _preferenceSummary {
    if (_selectedPurpose == null) {
      return 'Pilih tujuan konten agar rekomendasi tone, panjang, dan hashtag lebih presisi.';
    }
    return 'Disetel untuk $_selectedPurpose di ${_selectedPlatform ?? 'platform pilihan'}: tone $_selectedTone, caption $_selectedLength, bahasa $_selectedLanguage.';
  }

  String get _briefHint {
    switch (_selectedPurpose) {
      case 'Promo Diskon':
        return 'Contoh: Diskon 25% kopi susu gula aren, berlaku hari ini, stok 40 cup...';
      case 'Launching Produk':
        return 'Contoh: Produk baru parfum travel size, cocok untuk kerja dan hangout...';
      case 'Edukasi':
        return 'Contoh: Edukasi cara memilih bahan skincare untuk kulit berminyak...';
      case 'Testimoni':
        return 'Contoh: Pelanggan repeat order karena produk awet dan pengiriman cepat...';
      case 'Reminder':
        return 'Contoh: Pre-order ditutup jam 20.00, pengiriman besok pagi...';
      case 'Hiburan':
        return 'Contoh: Kebiasaan lucu pelanggan saat bingung pilih varian favorit...';
      case 'Giveaway':
        return 'Contoh: Giveaway paket hampers untuk 3 pemenang, syarat follow dan tag teman...';
      case 'Behind the Scenes':
        return 'Contoh: Proses packing order hari ini dengan kartu ucapan personal...';
      case 'Tips & Trik':
        return 'Contoh: 3 tips menyimpan produk agar tetap awet dan kualitas terjaga...';
      case 'Seasonal / Hari Besar':
        return 'Contoh: Promo hampers Lebaran, cocok untuk keluarga dan rekan kerja...';
      default:
        return 'Jelaskan produk, target audiens, promo, atau pesan utama caption...';
    }
  }

  void _onPurposeChanged(String? purpose) {
    setState(() {
      _selectedPurpose = purpose;
      if (purpose == null) return;

      final platforms = _availablePlatforms;
      final tones = _availableTones;
      final lengths = _availableLengths;

      if (_selectedPlatform == null || !platforms.contains(_selectedPlatform)) {
        _selectedPlatform = platforms.first;
      }
      if (!tones.contains(_selectedTone)) _selectedTone = tones.first;
      if (!lengths.contains(_selectedLength)) _selectedLength = lengths.first;
    });

    if (!mounted || purpose == null) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rekomendasi caption untuk "$purpose" sudah disesuaikan.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF3D5AFE),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  void _applyBriefSuggestion(_CaptionBriefSuggestion suggestion) {
    setState(() {
      _productController.text = suggestion.brief;
      _hashtagController.text = suggestion.hashtags;
      if (suggestion.platform != null &&
          _availablePlatforms.contains(suggestion.platform)) {
        _selectedPlatform = suggestion.platform;
      }
      if (suggestion.tone != null &&
          _availableTones.contains(suggestion.tone)) {
        _selectedTone = suggestion.tone!;
      }
      if (suggestion.length != null &&
          _availableLengths.contains(suggestion.length)) {
        _selectedLength = suggestion.length!;
      }
      _useEmoji = true;
      _useCTA = true;
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Brief "${suggestion.title}" diterapkan. Silakan edit detailnya.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF7C4DFF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  void _applyHashtagPreset(String hashtags) {
    setState(() => _hashtagController.text = hashtags);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.tag_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hashtag preset diterapkan.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF3D5AFE),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Future<void> _generate() async {
    if (_productController.text.isEmpty ||
        _selectedPurpose == null ||
        _selectedPlatform == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mohon lengkapi form utama'),
          behavior: SnackBarBehavior.floating));
      return;
    }

    // Cek dan kurangi credit caption.
    final canProceed = await showCreditGuard(context, CreditType.caption, ref);
    if (!canProceed || !mounted) return;

    setState(() {
      _isLoading = true;
      _results = [];
    });
    await ref.read(creditServiceProvider).useCredit(CreditType.caption);

    try {
      final authService = ref.read(authServiceProvider);
      final userProfile = authService.currentUser ??
          UserProfile(
              uid: 'demo',
              email: 'demo@mail.com',
              businessName: 'Bisnis Demo',
              targetAudience: 'Umum');
      final service = ref.read(aiTextServiceProvider);
      var promptProduct = _productController.text;
      if (_hashtagController.text.isNotEmpty) {
        promptProduct += " (Hashtags: ${_hashtagController.text})";
      }
      if (_useEmoji) promptProduct += " (Gunakan Emoji)";
      if (_useCTA) promptProduct += " (Sertakan Call-to-Action)";
      promptProduct += " (Bahasa: $_selectedLanguage)";
      final captions = await service.generateCaptions(
        userProfile: userProfile,
        purpose: _selectedPurpose!,
        platform: _selectedPlatform!,
        productName: promptProduct,
        tone: _selectedTone,
        length: _selectedLength,
        useEmoji: _useEmoji,
        useCTA: _useCTA,
      );
      setState(() => _results = captions);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final isKeyError = msg.contains('quota') ||
          msg.contains('429') ||
          msg.contains('rate') ||
          msg.contains('invalid') ||
          msg.contains('tidak valid') ||
          msg.contains('cooldown') ||
          msg.contains('semua');

      if (isKeyError) {
        _showAiErrorDialog(e.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(fontSize: 12)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Improve caption tanpa mengurangi credit.
  Future<String?> _improveCaption(String currentText) async {
    final gemini = ref.read(geminiServiceProvider);
    final userProfile = ref.read(authServiceProvider).currentUser;
    final businessContext = [
      if (userProfile != null && userProfile.businessName.isNotEmpty)
        'Nama bisnis: ${userProfile.businessName}',
      if (userProfile != null && userProfile.businessType.isNotEmpty)
        'Jenis bisnis: ${userProfile.businessType}',
      if (userProfile != null && userProfile.targetAudience.isNotEmpty)
        'Target audiens: ${userProfile.targetAudience}',
      if (_hashtagController.text.trim().isNotEmpty)
        'Hashtag pilihan: ${_hashtagController.text.trim()}',
    ].join('\n');

    return await gemini.generateText(
      systemPrompt: 'Kamu adalah copywriter UMKM Indonesia profesional. '
          'Tugasmu memperbaiki caption supaya lebih siap posting, lebih jelas, dan lebih menjual tanpa terdengar spam. '
          'Sesuaikan dengan tujuan "$_selectedPurpose", platform "$_selectedPlatform", tone "$_selectedTone", panjang "$_selectedLength", dan bahasa "$_selectedLanguage". '
          '${_useEmoji ? 'Gunakan emoji secukupnya sebagai penekanan natural. ' : 'Jangan gunakan emoji. '}'
          '${_useCTA ? 'Akhiri dengan CTA yang spesifik dan mudah dilakukan. ' : 'Jangan tambahkan CTA eksplisit. '}'
          'Pertahankan fakta, harga, nama produk, promo, dan klaim yang sudah ada. '
          'Jika caption punya hashtag, rapikan dan pilih yang paling relevan. '
          'Output HANYA caption yang sudah diperbaiki, tanpa penjelasan.',
      userPrompt: [
        if (businessContext.isNotEmpty) businessContext,
        'Caption saat ini:',
        currentText,
      ].join('\n\n'),
      temperature: 0.8,
    );
  }

  void _showAiErrorDialog(String errorMessage) {
    final isAllInvalid = errorMessage.toLowerCase().contains('semua') &&
        errorMessage.toLowerCase().contains('tidak valid');
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAllInvalid
                            ? 'API Key Tidak Valid'
                            : 'AI Sedang Sibuk',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isAllInvalid
                            ? 'Semua key sudah expired'
                            : 'Quota gratis habis hari ini',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cara Atasi:',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    if (isAllInvalid) ...[
                      _step('1', 'Buka aistudio.google.com/app/apikey'),
                      _step('2', 'Buat API key baru (gratis)'),
                      _step('3', 'Update GEMINI_KEY_1 di file .env'),
                      _step('4', 'Restart aplikasi'),
                    ] else ...[
                      _step('1', 'Tunggu hingga besok (reset 00:00 WIB)'),
                      _step('2', 'ATAU tambah API key baru di .env'),
                      _step(
                          '3', 'Buka aistudio.google.com/app/apikey (gratis)'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AFE).withOpacity(0.15),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mengerti',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String num, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF3D5AFE).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(slivers: [
        // Hero header.
        SliverAppBar(
          expandedHeight: 180,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.surfaceDark,
          actions: [
            CreditBadge(
                type: CreditType.caption, accentColor: const Color(0xFF3D5AFE)),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('Buat Caption AI',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            background: Stack(fit: StackFit.expand, children: [
              Image.asset('assets/images/banner_ai_text.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight)),
                        child: const Center(
                            child: Icon(Icons.auto_awesome_rounded,
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
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Powered by card.
                      GlassContainer(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      AppColors.grad1,
                                      AppColors.grad2
                                    ]),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.auto_awesome_rounded,
                                    color: Colors.white, size: 18)),
                            const SizedBox(width: 12),
                            const Expanded(
                                child: Text(
                                    'Powered by Gemini AI. Pilih tujuan, gunakan brief rekomendasi, lalu AI akan merapikan caption siap posting.',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 11))),
                          ])),
                      const SizedBox(height: 20),

                      // Section: Detail Konten.
                      _sectionTitle('Detail Konten'),
                      const SizedBox(height: 12),
                      GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GlassDropdown<String>(
                                    label: 'Tujuan Konten',
                                    value: _selectedPurpose,
                                    onChanged: _onPurposeChanged,
                                    items: _purposes
                                        .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e,
                                                style: const TextStyle(
                                                    fontSize: 13))))
                                        .toList()),
                                const SizedBox(height: 14),
                                GlassDropdown<String>(
                                    label: 'Platform Target',
                                    value: _selectedPlatform,
                                    onChanged: (v) =>
                                        setState(() => _selectedPlatform = v),
                                    items: _availablePlatforms
                                        .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e,
                                                style: const TextStyle(
                                                    fontSize: 13))))
                                        .toList()),
                                const SizedBox(height: 14),
                                _buildBriefSuggestions(),
                                const SizedBox(height: 14),
                                GlassFormField(
                                    label: 'Produk / Topik Utama',
                                    hint: _briefHint,
                                    controller: _productController,
                                    maxLines: 3),
                              ])),
                      const SizedBox(height: 20),

                      // Section: Preferensi dan Gaya.
                      _sectionTitle('Preferensi & Gaya'),
                      const SizedBox(height: 12),
                      _buildPreferencePanel(),
                      const SizedBox(height: 24),

                      // Generate button.
                      SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFF3D5AFE),
                                Color(0xFF7C4DFF)
                              ]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF3D5AFE)
                                        .withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6))
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
                                  : const Icon(Icons.auto_awesome_rounded,
                                      size: 20),
                              label: Text(
                                  _isLoading
                                      ? 'Generating...'
                                      : 'Generate Caption Ajaib',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16))),
                            ),
                          )),
                      const SizedBox(height: 20),

                      // Results.
                      if (_isLoading)
                        ...List.generate(
                            3,
                            (_) => const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: AiResultShimmer())),
                      if (_results.isNotEmpty) ...[
                        _sectionTitle('Hasil Caption'),
                        const SizedBox(height: 12),
                        ..._results.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: AiResultCard(
                                title: 'Caption ${e.key + 1}',
                                content: e.value,
                                variantIndex: e.key + 1,
                                accentColor: const Color(0xFF3D5AFE),
                                onRegenerate: _isLoading ? null : _generate,
                                onImprove: _improveCaption,
                                onSave: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Tersimpan ke Library!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            )),
                      ],
                    ]))),
      ]),
    );
  }

  Widget _buildBriefSuggestions() {
    final suggestions = _availableBriefSuggestions;
    if (suggestions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded,
                color: Colors.white38, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pilih tujuan konten dulu, nanti muncul contoh brief yang bisa langsung dipakai.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tips_and_updates_rounded,
                color: Color(0xFF7C4DFF), size: 16),
            const SizedBox(width: 6),
            Text(
              'Smart Brief Rekomendasi',
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return GestureDetector(
                onTap: () => _applyBriefSuggestion(suggestion),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3D5AFE).withOpacity(0.17),
                        const Color(0xFF7C4DFF).withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_fix_high_rounded,
                                color: Color(0xFFBBA7FF), size: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestion.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          suggestion.brief,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _miniMetaChip(suggestion.platform ?? 'Auto'),
                          const SizedBox(width: 6),
                          _miniMetaChip(suggestion.tone ?? 'Auto'),
                        ],
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

  Widget _miniMetaChip(String label) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.62),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencePanel() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3D5AFE).withOpacity(0.18),
                  const Color(0xFF00BCD4).withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Color(0xFF9CEBFF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekomendasi gaya aktif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _preferenceSummary,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.62),
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _smartChoiceGroup(
            label: 'Gaya Bahasa',
            helper:
                'Pilih rasa komunikasi caption. Rekomendasi berubah mengikuti tujuan konten.',
            icon: Icons.record_voice_over_rounded,
            options: _availableTones,
            selected: _selectedTone,
            descriptions: _toneDescriptions,
            onSelected: (v) => setState(() => _selectedTone = v),
          ),
          const SizedBox(height: 18),
          _smartChoiceGroup(
            label: 'Panjang Caption',
            helper:
                'Sesuaikan detail caption dengan platform dan niat posting.',
            icon: Icons.format_line_spacing_rounded,
            options: _availableLengths,
            selected: _selectedLength,
            descriptions: _lengthDescriptions,
            compact: true,
            onSelected: (v) => setState(() => _selectedLength = v),
          ),
          const SizedBox(height: 18),
          _smartChoiceGroup(
            label: 'Bahasa',
            helper: 'Pilih bahasa yang paling dekat dengan audiens.',
            icon: Icons.translate_rounded,
            options: _languages,
            selected: _selectedLanguage,
            descriptions: _languageDescriptions,
            onSelected: (v) => setState(() => _selectedLanguage = v),
          ),
          const SizedBox(height: 18),
          _buildHashtagAssistant(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _toggleCardDetailed(
                  title: 'Emoji',
                  subtitle: _useEmoji
                      ? 'Tambahkan penekanan visual secukupnya.'
                      : 'Caption dibuat bersih tanpa emoji.',
                  icon: Icons.auto_awesome_rounded,
                  value: _useEmoji,
                  onChanged: (v) => setState(() => _useEmoji = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _toggleCardDetailed(
                  title: 'CTA',
                  subtitle: _useCTA
                      ? 'Arahkan user untuk DM, order, atau simpan.'
                      : 'Tanpa ajakan aksi eksplisit.',
                  icon: Icons.ads_click_rounded,
                  value: _useCTA,
                  onChanged: (v) => setState(() => _useCTA = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smartChoiceGroup({
    required String label,
    required String helper,
    required IconData icon,
    required List<String> options,
    required String selected,
    required Map<String, String> descriptions,
    required ValueChanged<String> onSelected,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFBBA7FF), size: 16),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.86),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    helper,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.42),
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return _smartOptionChip(
              label: option,
              description: descriptions[option] ?? '',
              selected: selected == option,
              compact: compact,
              onTap: () => onSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _smartOptionChip({
    required String label,
    required String description,
    required bool selected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          minWidth: compact ? 96 : 118,
          maxWidth: compact ? 148 : 190,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 13,
          vertical: compact ? 10 : 11,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF3D5AFE), Color(0xFF7C4DFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.white.withOpacity(0.10)
                : Colors.white.withOpacity(0.10),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3D5AFE).withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 14,
                  color: selected ? Colors.white : Colors.white30,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withOpacity(0.78)
                      : Colors.white.withOpacity(0.38),
                  fontSize: 9.5,
                  height: 1.25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagAssistant() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassFormField(
          label: 'Hashtags',
          hint: '#jualan #promo #umkm',
          controller: _hashtagController,
          prefix:
              const Icon(Icons.tag_rounded, size: 18, color: Colors.white38),
        ),
        const SizedBox(height: 10),
        Text(
          'Preset cepat',
          style: TextStyle(
            color: Colors.white.withOpacity(0.56),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableHashtagPresets.map((hashtags) {
            final selected = _hashtagController.text.trim() == hashtags;
            return GestureDetector(
              onTap: () => _applyHashtagPreset(hashtags),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF00BCD4).withOpacity(0.18)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF00BCD4).withOpacity(0.45)
                        : Colors.white.withOpacity(0.09),
                  ),
                ),
                child: Text(
                  hashtags,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF9CEBFF)
                        : Colors.white.withOpacity(0.52),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white));

  Widget _toggleCardDetailed({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: value
              ? AppColors.accentLight.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: value
                  ? AppColors.accentLight.withOpacity(0.3)
                  : Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: value ? AppColors.accentLight : Colors.white30),
                const Spacer(),
                Icon(value ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    size: 28,
                    color: value ? AppColors.accentLight : Colors.white24),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: value ? Colors.white : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withOpacity(value ? 0.58 : 0.34),
                    fontSize: 10,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}
