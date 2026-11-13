import 'package:flutter/material.dart' hide Text;
import 'package:mobile_pariwisata/core/widgets/localized_text.dart';

enum ProfileInformationType { terms, about }

class ProfileInformationPage extends StatelessWidget {
  const ProfileInformationPage({super.key, required this.type});

  final ProfileInformationType type;

  static const _navy = Color(0xFF12304A);
  static const _raisedNavy = Color(0xFF244D70);
  static const _background = Color(0xFFF7F9FC);
  static const _bodyColor = Color(0xFF5F6F82);

  String get _title => switch (type) {
    ProfileInformationType.terms => 'Syarat dan Ketentuan',
    ProfileInformationType.about => 'Tentang JemberGo',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    tooltip: localized('Kembali'),
                    icon: const Icon(Icons.arrow_back_rounded, color: _navy),
                  ),
                  Expanded(
                    child: Text(
                      _title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE4EAF0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0809233F),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: type == ProfileInformationType.terms
                        ? _termsContent()
                        : _aboutContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _termsContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _InformationTitle('Syarat dan Ketentuan JemberGo'),
      const SizedBox(height: 12),
      const _InformationParagraph(
        'Selamat datang di JemberGo, aplikasi informasi dan layanan '
        'pariwisata Kabupaten Jember.',
      ),
      const SizedBox(height: 12),
      const _InformationParagraph(
        'Dengan menggunakan aplikasi JemberGo, pengguna dianggap telah '
        'menyetujui ketentuan berikut:',
      ),
      const SizedBox(height: 14),
      const _NumberedInformationList(
        items: [
          'Pengguna wajib memberikan informasi yang benar saat menggunakan '
              'aplikasi.',
          'Pengguna bertanggung jawab atas keamanan akun masing-masing.',
          'Pengguna dilarang menyalahgunakan fitur aplikasi untuk kegiatan '
              'yang melanggar hukum.',
          'Informasi wisata yang tersedia digunakan sebagai referensi bagi '
              'pengunjung.',
          'Informasi seperti harga tiket, jam operasional, dan fasilitas '
              'wisata dapat berubah sewaktu-waktu.',
          'Pengguna wajib menghormati aturan dan ketentuan di setiap destinasi '
              'wisata.',
          'Pengelola berhak memperbarui fitur dan ketentuan aplikasi sesuai '
              'kebutuhan.',
          'Pengelola berupaya menjaga keamanan data dan kenyamanan pengguna.',
        ],
      ),
      const SizedBox(height: 16),
      const _InformationParagraph(
        'Dengan menggunakan JemberGo, pengguna menyatakan telah membaca dan '
        'menyetujui seluruh syarat dan ketentuan yang berlaku.',
      ),
      const SizedBox(height: 16),
      const _InformationEmphasis(
        'JemberGo – Jelajahi Keindahan Wisata Kabupaten Jember.',
      ),
    ],
  );

  Widget _aboutContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _InformationTitle('Tentang JemberGo'),
      const SizedBox(height: 8),
      const _InformationEmphasis('JemberGo – Jelajahi Jember Lebih Dekat'),
      const SizedBox(height: 14),
      const _InformationParagraph(
        'JemberGo merupakan platform informasi dan layanan pariwisata '
        'Kabupaten Jember yang dikembangkan untuk memperkenalkan keindahan '
        'alam, kekayaan budaya, kuliner, serta berbagai potensi wisata lokal '
        'kepada masyarakat luas.',
      ),
      const SizedBox(height: 12),
      const _InformationParagraph(
        'Melalui JemberGo, pengguna dapat menemukan berbagai informasi '
        'destinasi wisata, mulai dari wisata alam, wisata budaya, wisata '
        'sejarah, hingga tempat kuliner menarik yang ada di Kabupaten Jember.',
      ),
      const SizedBox(height: 12),
      const _InformationParagraph(
        'JemberGo hadir sebagai solusi digital yang memudahkan wisatawan '
        'dalam mencari referensi perjalanan, mengenal tempat-tempat menarik, '
        'serta mendapatkan informasi pariwisata secara lebih mudah dan praktis.',
      ),
      const SizedBox(height: 20),
      const _InformationSectionHeading('Visi'),
      const SizedBox(height: 8),
      const _InformationParagraph(
        'Menjadi platform informasi dan layanan pariwisata digital yang '
        'membantu memperkenalkan potensi wisata Kabupaten Jember kepada '
        'masyarakat luas.',
      ),
      const SizedBox(height: 20),
      const _InformationSectionHeading('Misi'),
      const SizedBox(height: 8),
      const _BulletInformationList(
        items: [
          'Menyediakan informasi destinasi wisata yang mudah diakses.',
          'Memperkenalkan kekayaan alam dan budaya Kabupaten Jember.',
          'Mendukung promosi wisata dan potensi lokal.',
          'Memudahkan wisatawan menemukan tempat wisata dan kuliner.',
          'Mendorong perkembangan pariwisata lokal melalui teknologi digital.',
        ],
      ),
      const SizedBox(height: 20),
      const _InformationSectionHeading('Tujuan JemberGo'),
      const SizedBox(height: 8),
      const _InformationParagraph(
        'JemberGo bertujuan menjadi pusat informasi pariwisata digital yang '
        'menghubungkan wisatawan dengan berbagai potensi wisata di Kabupaten '
        'Jember, sehingga semakin banyak orang mengenal dan tertarik untuk '
        'berkunjung ke Jember.',
      ),
      const SizedBox(height: 16),
      const _InformationEmphasis(
        'JemberGo – Satu Platform, Banyak Cerita dari Jember.',
      ),
    ],
  );
}

class _InformationTitle extends StatelessWidget {
  const _InformationTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ProfileInformationPage._navy,
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _InformationSectionHeading extends StatelessWidget {
  const _InformationSectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ProfileInformationPage._raisedNavy,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _InformationParagraph extends StatelessWidget {
  const _InformationParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ProfileInformationPage._bodyColor,
      fontSize: 14,
      height: 1.65,
    ),
  );
}

class _InformationEmphasis extends StatelessWidget {
  const _InformationEmphasis(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: ProfileInformationPage._raisedNavy,
      fontSize: 14,
      height: 1.55,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _NumberedInformationList extends StatelessWidget {
  const _NumberedInformationList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < items.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '${index + 1}.',
                style: const TextStyle(
                  color: ProfileInformationPage._raisedNavy,
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(child: _InformationParagraph(items[index])),
          ],
        ),
      ],
    ],
  );
}

class _BulletInformationList extends StatelessWidget {
  const _BulletInformationList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 7),
                child: Icon(
                  Icons.circle,
                  size: 6,
                  color: ProfileInformationPage._raisedNavy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _InformationParagraph(item)),
            ],
          ),
        ),
      ],
    ],
  );
}
